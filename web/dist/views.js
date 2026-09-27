import {densePupil,enhancePupil} from './dense-pupil.js?v=20260927-positions3';
import {compute,geometry} from './optics.js?v=20260927-positions3';
// Defocus selects the movable screen; the image reference stays at the ideal focus.
export function computeScreen(params,z,progress=()=>{}) {
  if(Math.abs(z-geometry(params).pupil)<1e-8){
    const r=densePupil(params,{progress});
    // Use the same source/mask/image normalization as other screen positions.
    const reference=compute({...params,defocusUm:0},geometry(params).image);
    r.sharedPeak=Math.max(r.sharedPeak,reference.sharedPeak);return r;
  }
  const r=compute({...params,defocusUm:0},z,progress);
  return Math.abs(z-geometry(params).image)<1e-8?enhancePupil(r):r;
}
export function computeViews(params,z,progress=()=>{}) {
  const fixedZ=geometry(params).image,same=Math.abs(z-fixedZ)<1e-9;
  const planes=computeScreen(params,fixedZ,v=>progress(v*(same?.7:.4)));
  const screen=same?planes:computeScreen(params,z,v=>progress(.5+v*.5));
  progress(1);return {planes,screen};
}
