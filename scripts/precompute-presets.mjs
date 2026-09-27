import {Worker,isMainThread,workerData,parentPort} from 'node:worker_threads';
import {readFileSync,writeFileSync,mkdirSync,existsSync} from 'node:fs';
import {gzipSync} from 'node:zlib';
import {createHash} from 'node:crypto';
import {PRESETS,presetParams,presetCacheKey,PRESET_CACHE_VERSION} from '../dist/presets.js';
import {compute} from '../dist/optics.js';
import {CACHE_VERSION,waveCacheKey} from '../dist/cache.js';
import {enhancePupil} from '../dist/dense-pupil.js';
import {computeWave,centerCuts} from '../dist/wave.js';
import {referenceScreens} from '../dist/observation-state.js';
const encode=v=>JSON.stringify(v,(_,a)=>ArrayBuffer.isView(a)?Array.from(a):a);
const dir=new URL('../dist/data/presets/',import.meta.url);mkdirSync(dir,{recursive:true});
const engineHash=createHash('sha256').update(['optics.js','wave.js','wave-cuts.js','dense-pupil.js','radial-illumination.js'].map(f=>readFileSync(new URL('../dist/'+f,import.meta.url))).join('')).digest('hex');
if(!isMainThread){
  const id=workerData.id,p=presetParams(id),start=performance.now();
  parentPort.postMessage({stage:'XY'});
  const r=enhancePupil(compute(p));const slices=referenceScreens(r);slices[2].densePupil=true;
  parentPort.postMessage({stage:'Wave'});
  const wave=computeWave(p,'full',v=>{const step=Math.floor(v*10);if(step!==globalThis.step){globalThis.step=step;parentPort.postMessage({progress:step*10});}});
  // Dense Fourier plane is the same physical field, also used in the wave cut.
  const pupil=wave.columns.find(c=>Math.abs(c.z-r.geometry.pupil)<1e-9);Object.assign(pupil,{x:r.pupilAxis,y:r.pupilAxis,...centerCuts(r.pupilRaw,r.pupilAxis)});wave.sharedPeak=r.sharedPeak;
  const cache={version:PRESET_CACHE_VERSION,id,key:presetCacheKey(p),engineHash,generatedAt:new Date().toISOString(),seconds:(performance.now()-start)/1000,slices,wave};
  const bytes=gzipSync(encode(cache),{level:9});writeFileSync(new URL(id+'.json.gz',dir),bytes);
  if(id==='default')writeFileSync(new URL('../dist/data/default-wave-circular-fine-v4.json',import.meta.url),encode({version:CACHE_VERSION,key:waveCacheKey(p),engineHash,generatedAt:cache.generatedAt,result:wave}));
  parentPort.postMessage({done:true,id,bytes:bytes.length,seconds:cache.seconds});
}else{
  const todo=PRESETS.filter(p=>!existsSync(new URL(p.id+'.json.gz',dir)));let cursor=0;
  async function run(){while(cursor<todo.length){const {id}=todo[cursor++];await new Promise((resolve,reject)=>{const w=new Worker(new URL(import.meta.url),{workerData:{id}});let done=false;w.on('message',m=>{console.log(id,JSON.stringify(m));if(m.done){done=true;resolve();}});w.on('error',reject);w.on('exit',code=>{if(code||!done)reject(Error(id+' cache stopped '+code));});});}}
  await Promise.all([run(),run(),run()]);
  writeFileSync(new URL('manifest.json',dir),JSON.stringify({version:PRESET_CACHE_VERSION,engineHash,presets:PRESETS.map(p=>({id:p.id,key:presetCacheKey(presetParams(p.id)),file:p.id+'.json.gz'}))},null,2));
}
