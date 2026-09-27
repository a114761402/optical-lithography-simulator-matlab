import {slicePlan,maximum} from './optics.js?v=20260927-positions3';
const clamp=(v,lo,hi)=>Math.min(hi,Math.max(lo,v));
export const PLANE_NAMES={source:'Pupil plane',condenser:'Condenser exit',mask:'Mask exit',near:'Mask + 1 µm',lens1:'Lens 1',pupil:'Aperture plane',lens2:'Lens 2',image:'Image plane',custom:'Custom position'};
let nextInstance=0;
export function createPlane(id,plane='custom',base=0){return {id,instance:++nextInstance,plane,base,offset:0,generation:0,result:null,resultKey:null,pending:false,error:''};}
export function createPlanes(){return ['source','mask','pupil','image'].map((plane,i)=>createPlane('ABCD'[i],plane));}
export function restorePlane(panel){return {...panel,instance:++nextInstance,generation:panel.generation+1,pending:false,progress:null,error:''};}
export function availablePlaneId(planes){
  const used=new Set(planes.map(p=>p.id));
  for(let i=0;;i++){let n=i+1,id='';while(n){n--;id=String.fromCharCode(65+n%26)+id;n=Math.floor(n/26);}if(!used.has(id))return id;}
}
// Clone state, sharing immutable calculated arrays but never identity or edits.
export function appendPositionGroup(planes,count){
  const source=planes.slice(-count),added=[];
  for(let i=0;i<count;i++){
    const id=availablePlaneId([...planes,...added]),previous=source[i%source.length];
    const panel=previous?{...restorePlane(previous),id}:createPlane(id,'image');added.push(panel);
  }
  planes.push(...added);return added;
}
export const quantizePosition=value=>Math.round(value*1000)/1000;
export const formatPosition=value=>Number(value.toFixed(3)).toString();
// Limit labels to a coherent group; retain every other position as a faint tick.
export function markedPositions(planes,activeId,count){
  if(planes.length<=count)return planes;
  const index=Math.max(0,planes.findIndex(p=>p.id===activeId)),start=Math.floor(index/count)*count;
  return planes.map((p,i)=>({...p,muted:i<start||i>=start+count}));
}
export class SliceBatch{
  constructor(panels){this.states=new Map(panels.map(panel=>[panel.instance,'queued']));}
  settle(instance,state='done'){if(this.states.has(instance))this.states.set(instance,state);}
  drop(instance){this.states.delete(instance);}
  get total(){return this.states.size;}
  get remaining(){return [...this.states.values()].filter(state=>state==='queued').length;}
  get active(){return this.remaining>0;}
  get completed(){return this.total-this.remaining;}
}
export function tuningBase(panel,g){return panel.plane==='custom'?clamp(panel.base,0,g.max):panel.plane==='near'?g.mask+.001:g[panel.plane];}
export function observationZ(panel,g){return clamp(tuningBase(panel,g)+panel.offset*.001,0,g.max);}
export function setObservation(panel,g,value,plane='custom'){
  if(!Number.isFinite(value))return false;
  panel.plane=plane;panel.base=clamp(value,0,g.max);panel.offset=0;panel.generation++;panel.error='';return true;
}
export function tuneObservation(panel,g,offset){
  if(!Number.isFinite(offset))return false;
  const base=tuningBase(panel,g);panel.offset=clamp(offset,Math.max(-100,-base*1000),Math.min(100,(g.max-base)*1000));panel.generation++;panel.error='';return true;
}
export function sliceKey(params,z){const p={...params,defocusUm:0};return 'slice-v1:'+JSON.stringify(Object.keys(p).sort().map(key=>[key,p[key]]))+':'+Number(z.toFixed(9));}
export function sliceRequest(panel,g,params){return {panelId:panel.id,instance:panel.instance,generation:panel.generation,z:observationZ(panel,g),key:sliceKey(params,observationZ(panel,g))};}
export function acceptsSlice(panel,request,g,params){return !!panel&&panel.instance===request.instance&&panel.id===request.panelId&&panel.generation===request.generation&&request.key===sliceKey(params,observationZ(panel,g));}
export function snapPosition(z,g,pixelWidth,{bypass=false,previous=null,displayMax=g.max}={}){
  z=clamp(z,0,g.max);if(bypass||pixelWidth<=0)return {z,plane:'custom'};
  const keys=['source','condenser','mask','lens1','pupil','lens2','image'];
  if(previous&&keys.includes(previous)&&Math.abs(z-g[previous])*pixelWidth/displayMax<=12)return {z:g[previous],plane:previous};
  const key=keys.reduce((best,k)=>Math.abs(z-g[k])<Math.abs(z-g[best])?k:best,keys[0]);
  return Math.abs(z-g[key])*pixelWidth/displayMax<=8?{z:g[key],plane:key}:{z,plane:'custom'};
}
// Keep only XY data needed by a screen; full relay fields belong to reference views.
export function screenSnapshot(r){const {params,geometry,z,label,screenRaw,screenAxis,screenAxisY,screenHalf,sharedPeak,dark,samples}=r;return {params,geometry,z,label:displayPlaneLabel(label),screenRaw,screenAxis,screenAxisY,screenHalf,sharedPeak,dark,samples};}
export function displayPlaneLabel(label){return ({'Source plane':'Pupil plane','Pupil exit':'Aperture plane','Lens 1 to pupil':'Lens 1 to aperture','Pupil to lens 2':'Aperture to lens 2'})[label]||label;}
export function referenceScreens(r){
  const g=r.geometry,base=screenSnapshot(r);
  const make=(z,raw,axis,axisY=axis,half=null)=>({...base,z,label:displayPlaneLabel(slicePlan(r.params,z).label),screenRaw:raw,screenAxis:axis,screenAxisY:axisY,screenHalf:half,dark:maximum(raw)===0});
  return [make(0,r.sourceRaw,r.sourceAxis,r.sourceAxisY),make(g.mask,r.maskRaw,slicePlan(r.params,g.mask).axis),make(g.pupil,r.pupilRaw,r.pupilAxis,r.pupilAxis,1.1*g.f2*.001*r.params.projNA),base];
}
export class SliceCache{
  constructor(limit=6){this.limit=limit;this.entries=new Map();}
  get(key){const value=this.entries.get(key);if(value){this.entries.delete(key);this.entries.set(key,value);}return value;}
  set(key,value){this.entries.delete(key);this.entries.set(key,value);while(this.entries.size>this.limit)this.entries.delete(this.entries.keys().next().value);}
  values(){return [...this.entries.values()];}
  clear(){this.entries.clear();}
}
