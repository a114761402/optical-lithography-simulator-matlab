import {PRESET_CACHE_VERSION,presetParams,presetCacheKey} from './presets.js?v=20260927-positions3';
import {geometry,sourceSamples} from './optics.js?v=20260927-positions3';
import {pathPlanes} from './wave.js?v=20260927-positions3';
import {loadTransmittedPresetCache} from './transmitted-cache.js?v=20261003-transmitted-cache';
export async function loadPresetWave(id,transmittedOnly=false){
  return transmittedOnly?loadTransmittedPresetCache(id):(await loadPresetCache(id)).wave;
}
export function validatePresetCache(cache,id){
  const p=presetParams(id),g=geometry(p),key=presetCacheKey(p);
  if(cache.version!==PRESET_CACHE_VERSION||cache.id!==id||cache.key!==key||cache.slices?.length!==4||!cache.wave)throw Error('Saved preset does not match these settings.');
  const finite=a=>a?.length>1&&Array.from(a).every(Number.isFinite);
  const zs=[0,g.mask,g.pupil,g.image];
  cache.slices.forEach((s,i)=>{
    if(s.z!==zs[i]||presetCacheKey(s.params)!==key||!finite(s.screenAxis)||!finite(s.screenRaw)||s.screenRaw.length!==s.screenAxis.length**2||!(s.sharedPeak>0))throw Error('Invalid saved slice.');
    s.screenRaw=Float64Array.from(s.screenRaw);s.screenAxis=Float64Array.from(s.screenAxis);s.screenAxisY=Float64Array.from(s.screenAxisY||s.screenAxis);
  });
  const w=cache.wave,positions=pathPlanes(p);
  if(presetCacheKey(w.params)!==key||w.samples!==sourceSamples(p).length||w.columns.length!==positions.length||w.scope!=='full'||w.zMin!==0||w.zMax!==g.max||!(w.sharedPeak>0))throw Error('Invalid saved full path.');
  w.columns.forEach((c,i)=>{if(c.z!==positions[i]||!['x','y','xz','yz'].every(k=>finite(c[k]))||c.x.length!==c.xz.length||c.y.length!==c.yz.length)throw Error('Invalid saved wave coordinates.');});
  w.cached=true;return cache;
}
// Only the current preset is retained. A stale network response is checked by
// the caller before it can update the displayed system.
let current=null;
export async function loadPresetCache(id){
  if(current?.id===id)return current.promise;
  const promise=fetch(new URL(`./data/presets/${id}.json.gz?v=${PRESET_CACHE_VERSION}`,import.meta.url)).then(async r=>{
    if(!r.ok)throw Error('Saved preset unavailable');
    const raw=await r.arrayBuffer();
    const bytes=new Uint8Array(raw);
    const stream=bytes[0]===31&&bytes[1]===139?new Blob([raw]).stream().pipeThrough(new DecompressionStream('gzip')):new Blob([raw]).stream();
    return validatePresetCache(JSON.parse(await new Response(stream).text()),id);
  });
  current={id,promise};try{return await promise;}catch(e){if(current?.promise===promise)current=null;throw e;}
}
