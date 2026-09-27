import {defaults,sourceSamples} from './optics.js';
import {QUALITY} from './quality.js';
import {pathPlanes} from './wave.js';
export const CACHE_VERSION='scalar-wave-2026-09-26-v4';
export const STARTUP_PARAMS={...defaults,lensType:'Circular',lensInner:.65};
export const DEFAULT_WAVE_PARAMS={...STARTUP_PARAMS,...QUALITY.fine};
export function waveCacheKey(params,scope='full') {
  const p={...defaults,...params};
  return JSON.stringify([CACHE_VERSION,scope,Object.keys(defaults).sort().map(k=>[k,p[k]]),p.customSource??null,p.customPupil??null]);
}
export function validateWaveCache(cache,params=DEFAULT_WAVE_PARAMS,scope='full') {
  if(cache.version!==CACHE_VERSION||cache.key!==waveCacheKey(params,scope)||waveCacheKey(cache.result.params,cache.result.scope)!==cache.key)throw Error('The saved wave calculation does not match these settings.');
  const r=cache.result;
  if(!Array.isArray(r.columns)||r.columns.length!==119||r.params.gridSize!==512||r.params.sourceBins!==25||r.samples!==sourceSamples(DEFAULT_WAVE_PARAMS).length||!Number.isFinite(r.sharedPeak)||r.sharedPeak<=0||r.zMin!==0||r.zMax!==470)throw Error('Incomplete saved wave calculation.');
  const expected=pathPlanes(params,scope);
  if(r.columns.some((col,i)=>col.z!==expected[i]))throw Error('Mismatched wave positions.');
  for(const col of r.columns){for(const key of ['x','y','xz','yz'])if(!Array.isArray(col[key])||col[key].length<2||col[key].some(v=>!Number.isFinite(v)))throw Error('Invalid saved wave data.');if(col.x.length!==col.xz.length||col.y.length!==col.yz.length)throw Error('Mismatched wave coordinates.');}
  return {...r,cached:true};
}
