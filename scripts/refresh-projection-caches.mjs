// Recompute all projection cuts. Reuse XY and illumination only after verifying
// original engine provenance, all optical parameters, and unchanged operators.
import {Worker,isMainThread,workerData,parentPort} from 'node:worker_threads';
import {readFileSync,writeFileSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import {gunzipSync,gzipSync} from 'node:zlib';
import {createHash} from 'node:crypto';
import {PRESETS,presetParams,presetCacheKey,PRESET_CACHE_VERSION} from '../dist/presets.js';
import {computeWave,pathPlanes,centerCuts,wavePlan} from '../dist/wave.js';
import {CACHE_VERSION,waveCacheKey,validateWaveCache} from '../dist/cache.js';
import {validatePresetCache} from '../dist/preset-cache.js';
const baseline='cac5439a8a51e78290d2a46941a44cc454e3b9dc';
const files=['optics.js','wave.js','wave-cuts.js','dense-pupil.js','radial-illumination.js'];
const old=f=>execFileSync('git',['show',baseline+':dist/'+f],{encoding:'utf8'}),current=f=>readFileSync(new URL('../dist/'+f,import.meta.url),'utf8');
const strip=s=>s.replace(/\?v=[^'\"]+(?=['\"])/g,'');
for(const f of files.filter(f=>f!=='wave.js'))if(strip(old(f))!==strip(current(f)))throw Error('XY/illumination operator changed: full regeneration required: '+f);
const hash=text=>createHash('sha256').update(text).digest('hex'),oldHash=hash(files.map(old).join('')),engineHash=hash(files.map(current).join(''));
const encode=v=>JSON.stringify(v,(_,a)=>ArrayBuffer.isView(a)?Array.from(a):a);
const dir=new URL('../dist/data/presets/',import.meta.url);
if(!isMainThread){
 const id=workerData.id,file=new URL(id+'.json.gz',dir),saved=JSON.parse(gunzipSync(readFileSync(file))),p=presetParams(id);
 if(saved.engineHash===engineHash&&saved.version===PRESET_CACHE_VERSION){validatePresetCache(saved,id);parentPort.postMessage({done:true,id,cached:true});}
 else{
  if(saved.engineHash!==oldHash||JSON.stringify(saved.wave.params)!==JSON.stringify(p))throw Error('Unverified old cache: '+id);
  const start=performance.now(),g=saved.wave.geometry,positions=pathPlanes(p),retained=new Map(saved.wave.columns.filter(c=>c.z<g.mask||wavePlan(p,c.z).type!=='lct').map(c=>[c.z,c])),zs=positions.filter(z=>!retained.has(z));let last=-1;
  const fresh=computeWave(p,'full',v=>{const pct=Math.floor(v*10)*10;if(pct!==last){last=pct;parentPort.postMessage({id,progress:pct});}},zs);
  for(const c of fresh.columns)retained.set(c.z,c);
  const columns=positions.map(z=>retained.get(z));
  const wave={...saved.wave,columns,sharedPeak:saved.wave.sharedPeak};
  const cache={version:PRESET_CACHE_VERSION,id,key:presetCacheKey(p),engineHash,generatedAt:new Date().toISOString(),reusedUnchangedFieldsFrom:{engineHash:oldHash,commit:baseline},seconds:(performance.now()-start)/1000,slices:saved.slices,wave};
  const raw=encode(cache);validatePresetCache(JSON.parse(raw),id);writeFileSync(file,gzipSync(raw,{level:9}));
  if(id==='default'){const legacy={version:CACHE_VERSION,key:waveCacheKey(p),engineHash,generatedAt:cache.generatedAt,result:wave},json=encode(legacy);validateWaveCache(JSON.parse(json));writeFileSync(new URL('../dist/data/default-wave-circular-fine-v4.json',import.meta.url),json);}
  parentPort.postMessage({done:true,id,seconds:cache.seconds,planes:columns.length});
 }
}else{
 let index=0;async function run(){while(index<PRESETS.length){const {id}=PRESETS[index++];await new Promise((resolve,reject)=>{const w=new Worker(new URL(import.meta.url),{workerData:{id}});let done=false;w.on('message',m=>{console.log(JSON.stringify(m));if(m.done){done=true;resolve();}});w.on('error',reject);w.on('exit',code=>{if(code||!done)reject(Error('Cache failed: '+id));});});}}
 await Promise.all([run(),run()]);
 writeFileSync(new URL('manifest.json',dir),JSON.stringify({version:PRESET_CACHE_VERSION,engineHash,presets:PRESETS.map(p=>({id:p.id,key:presetCacheKey(presetParams(p.id)),file:p.id+'.json.gz'}))},null,2));
}
