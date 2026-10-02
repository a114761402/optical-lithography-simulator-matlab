// Separate assets: preserve the original full-field caches and numerical engine.
import {Worker,isMainThread,workerData,parentPort} from 'node:worker_threads';
import {readFileSync,writeFileSync,mkdirSync,existsSync} from 'node:fs';
import {gzipSync,gunzipSync} from 'node:zlib';
import {createHash} from 'node:crypto';
import {PRESETS,presetParams} from '../dist/presets.js';
import {waveCacheKey} from '../dist/cache.js';
import {computeTransmittedWave} from '../dist/transmitted-wave.js';
import {TRANSMITTED_CACHE_VERSION,TRANSMITTED_ENGINE_HASH,validateTransmittedCache} from '../dist/transmitted-cache.js';
const files=['optics.js','wave.js','wave-cuts.js','dense-pupil.js','radial-illumination.js','transmitted-wave.js'];
const engineHash=createHash('sha256').update(files.map(f=>readFileSync(new URL('../dist/'+f,import.meta.url))).join('')).digest('hex');
if(engineHash!==TRANSMITTED_ENGINE_HASH)throw Error('Numerical engine changed: update the transmitted cache version/hash before regeneration.');
const encode=v=>JSON.stringify(v,(_,a)=>ArrayBuffer.isView(a)?Array.from(a):a);
const dir=new URL('../dist/data/presets/',import.meta.url);mkdirSync(dir,{recursive:true});
const file=id=>new URL(id+'-transmitted.json.gz',dir);
if(!isMainThread){
  const {id}=workerData,p=presetParams(id),start=performance.now();let last=-1;
  // Offline workers can retain the three large RS operators. Browser jobs keep
  // their existing 128 MiB bound. This changes reuse, never the arithmetic.
  const result=computeTransmittedWave(p,'full',v=>{const pct=Math.floor(v*10)*10;if(pct!==last){last=pct;parentPort.postMessage({id,progress:pct});}},null,{operatorCacheBytes:1024*1024*1024});
  const cache={version:TRANSMITTED_CACHE_VERSION,id,key:waveCacheKey(p,'full',true),engineHash,generatedAt:new Date().toISOString(),seconds:(performance.now()-start)/1000,result};
  const raw=encode(cache);validateTransmittedCache(JSON.parse(raw),id);
  const bytes=gzipSync(raw,{level:9});writeFileSync(file(id),bytes);
  parentPort.postMessage({done:true,id,bytes:bytes.length,seconds:cache.seconds});
}else{
  const todo=PRESETS.filter(({id})=>{if(!existsSync(file(id)))return true;try{const c=JSON.parse(gunzipSync(readFileSync(file(id))));validateTransmittedCache(c,id);return c.engineHash!==engineHash;}catch{return true;}});let cursor=0;
  async function run(){while(cursor<todo.length){const {id}=todo[cursor++];await new Promise((resolve,reject)=>{const w=new Worker(new URL(import.meta.url),{workerData:{id}});let done=false;w.on('message',m=>{console.log(JSON.stringify(m));if(m.done){done=true;resolve();}});w.on('error',reject);w.on('exit',code=>{if(code||!done)reject(Error(id+' projection cache stopped '+code));});});}}
  await Promise.all([run(),run()]);
  writeFileSync(new URL('transmitted-manifest.json',dir),JSON.stringify({version:TRANSMITTED_CACHE_VERSION,engineHash,presets:PRESETS.map(({id})=>({id,key:waveCacheKey(presetParams(id),'full',true),file:id+'-transmitted.json.gz'}))},null,2));
}
