import {defaults} from './optics.js';
import {STARTUP_PARAMS} from './cache.js';

// Illumination presets change the source distribution, not the projection stop.
export function experiment(name){
  let params={...defaults},selected='mask',plane='image',offset=0;
  if(name==='aperture'){params.sourceType='Point';params.maskType='Circular Aperture';params.maskSizeUm=20;plane='near';}
  else if(name==='circular'){params={...STARTUP_PARAMS};selected='source';}
  else if(name==='annular'){params={...STARTUP_PARAMS,sourceType:'Annular'};selected='source';}
  else if(name==='defocus'){offset=25;selected='image';}
  return {params:{...params,defocusUm:0},selected,plane,offset};
}
