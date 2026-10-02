import {lctCenterCuts} from './wave-cuts.js?v=20260927-positions3';
import {defaults,geometry,validate,makeMask,sourceSamples,gaussianBeam,coherent,propagateSame,slicePlan,illuminationIntensity,intensity,maximum,compute,axis,field} from './optics.js?v=20260927-positions3';
import {computeWave,centerCuts,sampleLine,pathPlanes,wavePlan} from './wave.js?v=20260927-positions3';

// Undo the image's inversion/reduction to recover the passed inverse FFT.
// Retain the full padded grid, including the filtering tails.
export function transmittedMaskField(f,reduction){
  const out=field(f.image.n),last=out.re.length-1;
  for(let i=0;i<=last;i++){out.re[i]=f.image.re[last-i]/reduction;out.im[i]=f.image.im[last-i]/reduction;}
  return out;
}
export function computeTransmittedWave(params,scope='full',progress=()=>{},planes=null) {
  if(scope==='near')return computeWave(params,scope,progress,planes);
  const transmittedOnly=true;
  const p={...defaults,...params};validate(p);const g=geometry(p),zs=planes||pathPlanes(p,scope);
  if(!zs.length||zs.some(z=>!Number.isFinite(z)||z<0||z>g.max))throw Error('Wave positions must lie within the bench.');
  const n=p.gridSize,dx=p.fieldSizeUm*1e-6/n,lambda=p.wavelengthNm*1e-9,mask=makeMask(p),beam=gaussianBeam(p,g.mask),samples=sourceSamples(p),columns=zs.map(z=>({z,plan:wavePlan(p,z)}));
  // Use the same fixed source/mask-incident/pupil/image reference as XY results.
  const reference=compute(p,g.screen),sharedPeak=reference.sharedPeak,propagationCache={operators:new Map(),spectra:new WeakMap()};
  for(const col of columns){if(col.plan.type==='illumination'){col.x=col.plan.axis;col.y=col.plan.axisY||col.x;Object.assign(col,centerCuts(illuminationIntensity(p,col.plan.beam,col.x,col.y),col.x,col.y));}}
  for(let k=0;k<samples.length;k++) {
    const s=samples[k],f=coherent(p,mask,s,beam),passed=transmittedOnly&&scope==='full'?transmittedMaskField(f,p.reduction):null,passedAxis=passed?axis(passed.n,dx):null;propagationCache.spectra=new WeakMap();
    for(let j=0;j<columns.length;j++) {
      const col=columns[j],a=col.plan;let out,cuts;
      // Propagate the aperture-selected mask field on the original relay.
      // This is its transmitted contribution, not the total incident field
      // or a decomposition into independent geometrical rays.
      if(passed && col.z>=g.mask && col.z<g.pupil){
        if(a.type==='lct')cuts=lctCenterCuts(passed,passedAxis,a.axis,lambda,a.A,a.B);
        else{
          out=a.type==='near'?propagateSame(passed,lambda,dx,a.dz,'rs',propagationCache):passed;
          const native=centerCuts(intensity(out),passedAxis),target=a.axis||f.x;
          cuts={xz:Float64Array.from(target,x=>sampleLine(passedAxis,native.xz,x)),yz:Float64Array.from(target,y=>sampleLine(passedAxis,native.yz,y))};
        }
      }
      if(!cuts)
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
  progress(1);return {columns,params:p,geometry:g,scope,transmittedOnly:transmittedOnly&&scope==='full',sharedPeak,samples:samples.length,zMin:zs[0],zMax:zs.at(-1)};
}
