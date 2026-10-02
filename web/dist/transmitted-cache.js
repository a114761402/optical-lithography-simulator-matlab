import {presetParams,presetCacheKey} from './presets.js?v=20261003-transmitted-cache';
import {waveCacheKey} from './cache.js?v=20261002-transmitted2';
import {geometry,sourceSamples} from './optics.js?v=20260927-positions3';
import {pathPlanes} from './wave.js?v=20260927-positions3';
export const TRANSMITTED_CACHE_VERSION='fine-aperture-transmitted-v1';
export const TRANSMITTED_ENGINE_HASH="e9107550be510b7e409f078c4075b183dc737d05e0b54a1df8ed51df56eda2c0";
export function validateTransmittedCache(cache,id){
  const p=presetParams(id),r=cache.result,g=geometry(p),positions=pathPlanes(p);
  if(cache.version!==TRANSMITTED_CACHE_VERSION||cache.engineHash!==TRANSMITTED_ENGINE_HASH||cache.id!==id||cache.key!==waveCacheKey(p,'full',true)||!r||!r.transmittedOnly||r.scope!=='full'||presetCacheKey(r.params)!==presetCacheKey(p))throw Error('Saved projection does not match this preset and selection.');
  if(Object.keys(g).some(k=>r.geometry?.[k]!==g[k])||!Array.isArray(r.columns)||r.columns.length!==positions.length||r.samples!==sourceSamples(p).length||r.zMin!==positions[0]||r.zMax!==g.max||!Number.isFinite(r.sharedPeak)||r.sharedPeak<=0)throw Error('Incomplete saved projection.');
  const finite=a=>a?.length>1&&Array.from(a).every(Number.isFinite);
  r.columns.forEach((c,i)=>{if(c.z!==positions[i]||!['x','y','xz','yz'].every(k=>finite(c[k]))||c.x.length!==c.xz.length||c.y.length!==c.yz.length||c.xz.some(v=>v<0)||c.yz.some(v=>v<0))throw Error('Invalid saved projection coordinates or intensity.');});
  r.cached=true;return r;
}
let current=null;
export async function loadTransmittedPresetCache(id){
  if(current?.id===id)return current.promise;
  const promise=fetch(new URL(`./data/presets/${id}-transmitted.json.gz?v=${TRANSMITTED_CACHE_VERSION}`,import.meta.url)).then(async r=>{
    if(!r.ok)throw Error('Saved projection unavailable');
    const raw=await r.arrayBuffer(),bytes=new Uint8Array(raw);
    const stream=bytes[0]===31&&bytes[1]===139?new Blob([raw]).stream().pipeThrough(new DecompressionStream('gzip')):new Blob([raw]).stream();
    return validateTransmittedCache(JSON.parse(await new Response(stream).text()),id);
  });
  current={id,promise};try{return await promise;}catch(e){if(current?.promise===promise)current=null;throw e;}
}
