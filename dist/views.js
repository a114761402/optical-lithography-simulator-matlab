import {compute,geometry} from './optics.js';
// Defocus selects the movable screen; the image reference stays at the ideal focus.
export function computeScreen(params,z,progress=()=>{}) {
  return compute({...params,defocusUm:0},z,progress);
}
export function computeViews(params,z,progress=()=>{}) {
  const fixedZ=geometry(params).image,same=Math.abs(z-fixedZ)<1e-9;
  const planes=computeScreen(params,fixedZ,v=>progress(v*(same?1:.5)));
  const screen=same?planes:computeScreen(params,z,v=>progress(.5+v*.5));
  return {planes,screen};
}
