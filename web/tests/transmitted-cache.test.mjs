import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {gunzipSync} from 'node:zlib';
import {PRESETS,presetParams} from '../dist/presets.js';
import {geometry} from '../dist/optics.js';
import {computeTransmittedWave} from '../dist/transmitted-wave.js';
import {TRANSMITTED_CACHE_VERSION,validateTransmittedCache,loadTransmittedPresetCache} from '../dist/transmitted-cache.js';
import {loadPresetWave} from '../dist/preset-cache.js';
const read=id=>JSON.parse(gunzipSync(readFileSync(new URL('../dist/data/presets/'+id+'-transmitted.json.gz',import.meta.url))));
for(const {id,name} of PRESETS)test(name+' has matching Fine aperture-selected XZ and YZ caches',()=>{
  const raw=read(id),r=validateTransmittedCache(raw,id);
  assert.equal(r.params.gridSize,512);assert.equal(r.params.sourceBins,25);
  assert.equal(r.transmittedOnly,true);assert.equal(r.cached,true);
  const original=JSON.parse(gunzipSync(readFileSync(new URL('../dist/data/presets/'+id+'.json.gz',import.meta.url)))).wave;
  for(let i=0;i<r.columns.length;i++)if(r.columns[i].z<r.geometry.mask||r.columns[i].z>r.geometry.pupil){
    const c=r.columns[i],baseline=original.columns[i];
    assert.deepEqual(c.x,baseline.x);assert.deepEqual(c.y,baseline.y);
    for(const key of ['xz','yz']){let peak=1,error=0;for(let j=0;j<c[key].length;j++){peak=Math.max(peak,baseline[key][j]);error=Math.max(error,Math.abs(c[key][j]-baseline[key][j]));}assert.ok(error<=peak*1e-10,`${id} unchanged ${key} at ${c.z}`);}
  }
  assert.throws(()=>validateTransmittedCache({...raw,engineHash:'outdated-engine'},id));
  assert.throws(()=>validateTransmittedCache({...raw,key:raw.key.replace('|transmitted-v1','')},id));
  assert.throws(()=>validateTransmittedCache({...raw,result:{...r,transmittedOnly:false}},id));
  assert.throws(()=>validateTransmittedCache({...raw,result:{...r,params:{...r.params,projNA:r.params.projNA+.01}}},id));
  assert.throws(()=>validateTransmittedCache({...raw,result:{...r,columns:r.columns.slice(1)}},id));
  assert.throws(()=>validateTransmittedCache({...raw,result:{...r,geometry:{...r.geometry,pupil:r.geometry.pupil+1}}},id));
});
for(const id of ['filtering','diffraction'])test(id+' cached upstream cuts match fresh Fine calculations',()=>{
  const r=validateTransmittedCache(read(id),id),g=geometry(r.params);
  const columns=[r.columns.find(c=>c.z===g.mask),r.columns.find(c=>c.z===g.lens1),r.columns.find(c=>c.z===g.pupil)];
  const fresh=computeTransmittedWave(presetParams(id),'full',()=>{},columns.map(c=>c.z));
  for(let j=0;j<columns.length;j++)for(const k of ['x','y','xz','yz'])assert.deepEqual(Array.from(fresh.columns[j][k]),Array.from(columns[j][k]));
  assert.equal(r.sharedPeak,fresh.sharedPeak);
});
test('Preset loader uses separate selection assets and can retry a missing cache',async()=>{
  const fetchBefore=globalThis.fetch,urls=[];let fail=true;
  globalThis.fetch=async url=>{
    urls.push(String(url));
    if(fail){fail=false;return new Response('',{status:404});}
    return new Response(readFileSync(url));
  };
  try{
    await assert.rejects(loadTransmittedPresetCache('filtering'));
    const passed=await loadPresetWave('filtering',true),full=await loadPresetWave('filtering',false);
    assert.equal(passed.transmittedOnly,true);assert.notEqual(full.transmittedOnly,true);
    assert.ok(urls[0].includes('filtering-transmitted.json.gz?v='+TRANSMITTED_CACHE_VERSION));
    assert.equal(urls[0],urls[1]);assert.ok(urls[2].includes('filtering.json.gz'));
    assert.notDeepEqual(passed.columns.find(c=>c.z===300).xz,full.columns.find(c=>c.z===300).xz);
  }finally{globalThis.fetch=fetchBefore;}
});
