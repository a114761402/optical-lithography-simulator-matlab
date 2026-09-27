import {geometry,axis,makeMask,sourceSamples,gaussianBeam,gaussianMode,pupilValue} from './optics.js?v=20260927-illumination2';
import {lctCenterCuts} from './wave-cuts.js?v=20260927-illumination2';
export function densePupilCuts(p,size=257){
  const g=geometry(p),radius=g.f2*.001*p.projNA,half=radius*1.1;
  const output=Float64Array.from({length:size},(_,i)=>(i/(size-1)*2-1)*half),x=axis(p.gridSize,p.fieldSizeUm*1e-6/p.gridSize),mask=makeMask(p),beam=gaussianBeam(p,g.mask);
  const xz=new Float64Array(size),yz=new Float64Array(size);
  for(const s of sourceSamples(p)){
    const field=gaussianMode(beam,x,s.u,s.v);for(let i=0;i<mask.length;i++){field.re[i]*=mask[i];field.im[i]*=mask[i];}
    const cuts=lctCenterCuts(field,x,output,p.wavelengthNm*1e-9,0,g.f1*.001);
    for(let i=0;i<size;i++){xz[i]+=s.w*cuts.xz[i]*pupilValue(p,output[i]/radius,0)**2;yz[i]+=s.w*cuts.yz[i]*pupilValue(p,0,output[i]/radius)**2;}
  }
  return {z:g.pupil,x:output,y:output,xz,yz};
}
export function enhanceWave(w){const i=w.columns.findIndex(c=>Math.abs(c.z-w.geometry.pupil)<1e-8);if(i>=0)w.columns[i]=densePupilCuts(w.params);return w;}
