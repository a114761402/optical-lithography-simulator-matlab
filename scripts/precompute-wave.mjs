import {writeFileSync,mkdirSync,readFileSync,existsSync,renameSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {Worker,isMainThread,parentPort,workerData} from 'node:worker_threads';
import {availableParallelism} from 'node:os';
import {computeWave,pathPlanes} from '../dist/wave.js';
import {geometry} from '../dist/optics.js';
import {CACHE_VERSION,DEFAULT_WAVE_PARAMS,waveCacheKey,validateWaveCache} from '../dist/cache.js';
const encode=value=>JSON.stringify(value,(_,v)=>ArrayBuffer.isView(v)?Array.from(v):v);
const engineHash=createHash('sha256').update(readFileSync(new URL('../dist/optics.js',import.meta.url))).update(readFileSync(new URL('../dist/wave.js',import.meta.url))).update(readFileSync(new URL('../dist/wave-cuts.js',import.meta.url))).update(readFileSync(new URL('../dist/dense-pupil.js',import.meta.url))).update(readFileSync(new URL('../dist/radial-illumination.js',import.meta.url))).digest('hex');
if(!isMainThread){
  let last=-1;
  const result=computeWave(DEFAULT_WAVE_PARAMS,'full',p=>{const step=Math.floor(p*20);if(step!==last){last=step;parentPort.postMessage({progress:p});}},workerData.planes);
  parentPort.postMessage({result});
}else{
  const start=performance.now(),key=waveCacheKey(DEFAULT_WAVE_PARAMS),planes=pathPlanes(DEFAULT_WAVE_PARAMS),count=Math.min(8,Math.max(1,availableParallelism()-2));
  let upstream=[];
  if(process.argv.length>2){
    if(process.argv.length!==4||process.argv[2]!=='--reuse-upstream')throw Error('Use --reuse-upstream <saved-cache.json> or no arguments.');
    const saved=JSON.parse(readFileSync(process.argv[3],'utf8')),old=saved.result.params;
    if(saved.engineHash!==engineHash||waveCacheKey({...old,lensType:DEFAULT_WAVE_PARAMS.lensType,lensInner:DEFAULT_WAVE_PARAMS.lensInner})!==key)throw Error('Upstream reuse requires the identical engine and all non-pupil parameters.');
    const checked=validateWaveCache({...saved,version:CACHE_VERSION,key:waveCacheKey(old)},old);
    // This forward model has no reflected field: the pupil cannot change upstream raw intensity.
    // Shared normalization is still recalculated below for the new pupil and image.
    upstream=checked.columns.filter(col=>col.z<geometry(DEFAULT_WAVE_PARAMS).pupil);
  }
  const remaining=planes.filter(z=>!upstream.some(col=>col.z===z));
  const checkpoints=new URL('../.sites-runtime/wave-cache-parts/',import.meta.url);mkdirSync(checkpoints,{recursive:true});
  const groups=Array.from({length:count},()=>[]);remaining.forEach((z,i)=>groups[i%count].push(z));
  const progress=Array(count).fill(0);let last=-1;
  console.log(`Full Fine calculation: 512 grid, 25 source bins per side, ${remaining.length} new planes, ${upstream.length} identical upstream planes, ${count} workers`);
  const parts=await Promise.all(groups.map((zs,index)=>new Promise((resolve,reject)=>{
    const file=new URL(`part-${index}.json`,checkpoints);
    if(existsSync(file)){const saved=JSON.parse(readFileSync(file,'utf8'));if(saved.key===key&&saved.engineHash===engineHash&&encode(saved.planes)===encode(zs)){progress[index]=1;resolve(saved.result);return;}}
    const worker=new Worker(new URL(import.meta.url),{workerData:{planes:zs}});let completed=false;
    worker.on('error',reject);worker.on('exit',code=>{if(code||!completed)reject(Error(`Worker ${index} stopped before completion (${code})`));});
    worker.on('message',message=>{
      if(message.progress!==undefined){progress[index]=message.progress;const percent=Math.floor(progress.reduce((a,b)=>a+b,0)/count*100);if(percent>last){last=percent;console.log(`Fine wave ${percent}% · ${Math.round((performance.now()-start)/1000)} s`);}}
      if(message.result){completed=true;writeFileSync(file,encode({key,engineHash,planes:zs,result:message.result}));resolve(message.result);}
    });
  })));
  const reference=parts[0];for(const part of parts)if(part.sharedPeak!==reference.sharedPeak||part.samples!==reference.samples)throw Error('Worker reference mismatch');
  const result={...reference,columns:[...upstream,...parts.flatMap(p=>p.columns)].sort((a,b)=>a.z-b.z),zMin:planes[0],zMax:planes.at(-1)};
  const cache={version:CACHE_VERSION,key,engineHash,generatedAt:new Date().toISOString(),calculationSeconds:(performance.now()-start)/1000,reusedUpstreamPlanes:upstream.length,result};
  const json=encode(cache);validateWaveCache(JSON.parse(json));
  const target=new URL('../dist/data/default-wave-circular-fine-v4.json',import.meta.url),temp=new URL('../dist/data/default-wave-circular-fine-v4.json.tmp',import.meta.url);
  mkdirSync(new URL('../dist/data/',import.meta.url),{recursive:true});writeFileSync(temp,json);renameSync(temp,target);
  console.log(encode({seconds:cache.calculationSeconds,bytes:json.length,planes:result.columns.length,grid:result.params.gridSize,sourceBins:result.params.sourceBins,emitters:result.samples}));
}
