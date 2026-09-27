import {defaults,validate,geometry,axis,makeMask,sourceSamples,gaussianBeam,gaussianMode,lct,pupilValue,maximum} from './optics.js?v=20260927-illumination2';
// Evaluate the same discrete mask Fourier integral on a small, dense physical
// pupil window. No global padding or interpolation of the optical field.
export function densePupil(params,{size=257,progress=()=>{}}={}){
  const p={...defaults,...params};validate(p);
  const g=geometry(p),radius=g.f2*.001*p.projNA,half=radius*1.1;
  const outputAxis=Float64Array.from({length:size},(_,i)=>(i/(size-1)*2-1)*half);
  const x=axis(p.gridSize,p.fieldSizeUm*1e-6/p.gridSize),mask=makeMask(p),beam=gaussianBeam(p,g.mask),samples=sourceSamples(p);
  const raw=new Float64Array(size*size),opening=Float64Array.from(raw,(_,i)=>pupilValue(p,outputAxis[i%size]/radius,outputAxis[Math.floor(i/size)]/radius)**2);
  samples.forEach((s,index)=>{
    const f=gaussianMode(beam,x,s.u,s.v);
    for(let i=0;i<mask.length;i++){f.re[i]*=mask[i];f.im[i]*=mask[i];}
    const pupil=lct(f,x,outputAxis,p.wavelengthNm*1e-9,0,g.f1*.001,0);
    for(let i=0;i<raw.length;i++)raw[i]+=s.w*opening[i]*(pupil.re[i]**2+pupil.im[i]**2);
    progress((index+1)/samples.length);
  });
  return {params:p,geometry:g,z:g.pupil,label:'Aperture plane',screenRaw:raw,screenAxis:outputAxis,screenAxisY:outputAxis,screenHalf:half,sharedPeak:maximum(raw),samples:samples.length,dark:maximum(raw)===0,densePupil:true};
}
export function enhancePupil(r,progress=()=>{}){
  const d=densePupil(r.params,{progress});r.pupilRaw=d.screenRaw;r.pupilAxis=d.screenAxis;r.sharedPeak=Math.max(r.sharedPeak,d.sharedPeak);
  if(Math.abs(r.z-r.geometry.pupil)<1e-8)Object.assign(r,{screenRaw:d.screenRaw,screenAxis:d.screenAxis,screenAxisY:d.screenAxisY,screenHalf:d.screenHalf,densePupil:true});
  return r;
}
