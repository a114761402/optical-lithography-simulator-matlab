import {lctCenterCuts} from './wave-cuts.js?v=20260927-positions3';
import {defaults,geometry,validate,makeMask,sourceSamples,gaussianBeam,coherent,propagateSame,lct,slicePlan,illuminationIntensity,intensity,maximum,compute} from './optics.js?v=20260927-positions3';

// Interpolate at the physical origin, which need not be the middle pixel.
export function sampleLine(axis, values, at) {
  if (at < axis[0] || at > axis.at(-1)) return 0;
  const f=(at-axis[0])/(axis[1]-axis[0]),i=Math.min(axis.length-2,Math.max(0,Math.floor(f))),t=Math.max(0,Math.min(1,f-i));
  return values[i]*(1-t)+values[i+1]*t;
}
export function centerCuts(raw,x,y=x) {
  const n=x.length,xz=new Float64Array(n),yz=new Float64Array(y.length),column=new Float64Array(y.length);
  for(let j=0;j<n;j++){for(let i=0;i<y.length;i++)column[i]=raw[i*n+j];xz[j]=sampleLine(y,column,0);}
  for(let i=0;i<y.length;i++)yz[i]=sampleLine(x,raw.subarray(i*n,(i+1)*n),0);
  return {xz,yz};
}
export function brightness(value,reference,mode='local') {
  const ratio=reference>0?Math.max(0,value/reference):0;
  return mode.includes('log')?Math.max(0,Math.min(1,(10*Math.log10(Math.max(ratio,1e-12))+120)/120)):Math.max(0,Math.min(1,ratio));
}
export function pathPlanes(p,scope='full') {
  const g=geometry(p);
  if(scope==='near')return Array.from({length:61},(_,i)=>g.mask+i*.2/60);
  const a=Array.from({length:65},(_,i)=>i*g.max/64);
  // Resolve rapid source-lobe spreading locally, without adding projection FFTs.
  const end=Math.min(g.condenser*.4,40),step=p.gridSize>=512?.5:1;
  for(let z=step;z<=end;z+=step)a.push(z);
  for(const z of [.01,.025,.05,.1,.2,.3])if(z<end)a.push(z);
  for(const z of [g.condenser,g.mask,g.lens1,g.pupil,g.lens2,g.image,g.screen]) {
    a.push(z);for(const d of [.001,.02,.2,1])a.push(z-d,z+d);
  }
  // Resolve the rapidly changing diffraction/focus region locally. Elsewhere
  // keep the original spacing. These are physical calculations, not blur.
  for(const anchor of [g.mask,g.image])for(let d=.5;d<=Math.min(25,g.f2);d*=1.35){
    a.push(anchor+d);if(anchor===g.image)a.push(anchor-d);
  }
  return [...new Set(a.filter(z=>z>=0&&z<=g.max))].sort((a,b)=>a-b);
}
// Expand only the cheap output cuts, keeping the original transverse spacing.
// The previous calculation window clipped visible tails at about 4% of peak.
// This does not increase the 2-D propagation grid or source sample count.
export function wavePlan(p,z){
  const plan=slicePlan(p,z);
  if(plan.type==='lct'){
    const old=plan.axis,n=old.length,step=old[1]-old[0];
    const inputStep=p.fieldSizeUm*1e-6/p.gridSize/(plan.before?1:p.reduction);
    const nyquist=p.wavelengthNm*1e-9*Math.abs(plan.B)/(2*inputStep);
    const padding=Math.max(0,Math.min(n,Math.floor((nyquist-Math.max(Math.abs(old[0]),Math.abs(old.at(-1))))/step)));
    plan.axis=Float64Array.from({length:n+2*padding},(_,i)=>old[0]+(i-padding)*step);
  }
  return plan;
}
// One coherent relay per emitter; retain only the two physical central cuts.
// Spatial grid stays at the selected detail. Source quadrature is explicit.
export function computeWave(params,scope='full',progress=()=>{},planes=null) {
  const p={...defaults,...params};validate(p);const g=geometry(p),zs=planes||pathPlanes(p,scope);
  if(!zs.length||zs.some(z=>!Number.isFinite(z)||z<0||z>g.max))throw Error('Wave positions must lie within the bench.');
  const n=p.gridSize,dx=p.fieldSizeUm*1e-6/n,lambda=p.wavelengthNm*1e-9,mask=makeMask(p),beam=gaussianBeam(p,g.mask),samples=sourceSamples(p),columns=zs.map(z=>({z,plan:wavePlan(p,z)}));
  // Use the same fixed source/mask-incident/pupil/image reference as XY results.
  const reference=compute(p,g.screen),sharedPeak=reference.sharedPeak,propagationCache={operators:new Map(),spectra:new WeakMap()};
  for(const col of columns){if(col.plan.type==='illumination'){col.x=col.plan.axis;col.y=col.plan.axisY||col.x;Object.assign(col,centerCuts(illuminationIntensity(p,col.plan.beam,col.x,col.y),col.x,col.y));}}
  for(let k=0;k<samples.length;k++) {
    const s=samples[k],f=coherent(p,mask,s,beam);propagationCache.spectra=new WeakMap();
    for(let j=0;j<columns.length;j++) {
      const col=columns[j],a=col.plan;let out,cuts;
      switch(a.type) {
        case 'illumination':continue;
        case 'mask':out=f.mask;break;
        case 'pupil':out=f.pupil;break;
        case 'near':out=propagateSame(f.mask,lambda,dx,a.dz,'rs',propagationCache);break;
        case 'image':out=propagateSame(f.image,lambda,dx/p.reduction,a.dz,'fresnel',propagationCache);break;
        case 'lct':cuts=lctCenterCuts(a.before?f.mask:f.image,a.before?f.x:f.imageAxis,a.axis,lambda,a.A,a.B);break;
      }
      const x=a.axis||f.pupilAxis,y=a.axisY||x;cuts=cuts||centerCuts(intensity(out),x,y);
      if(!col.x){col.x=x;col.y=y;col.xz=new Float64Array(x.length);col.yz=new Float64Array(y.length);}
      for(const key of ['xz','yz'])for(let i=0;i<cuts[key].length;i++)col[key][i]+=s.w*cuts[key][i];
      progress((k*columns.length+j+1)/(Math.max(1,samples.length)*columns.length));
    }
  }
  // Empty custom source still returns meaningful coordinates and zero fields.
  for(const col of columns){if(!col.x){col.x=col.plan.axis||reference.pupilAxis;col.y=col.plan.axisY||col.x;col.xz=new Float64Array(col.x.length);col.yz=new Float64Array(col.y.length);}delete col.plan;for(const key of ['xz','yz'])if(!Number.isFinite(maximum(col[key])))throw Error('Non-finite wave intensity. Choose less extreme settings.');}
  progress(1);return {columns,params:p,geometry:g,scope,sharedPeak,samples:samples.length,zMin:zs[0],zMax:zs.at(-1)};
}
