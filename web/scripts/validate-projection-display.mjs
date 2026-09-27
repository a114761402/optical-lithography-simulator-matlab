import {presetParams} from '../dist/presets.js';
import {computeWave,sampleLine} from '../dist/wave.js';
import {createWaveSampler} from '../dist/wave-display.js';
import {readFileSync,writeFileSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import {gunzipSync} from 'node:zlib';
// Both comparisons use independently recomputed Fine cuts at uncached midplanes.
const results=[];
for(const id of ['default','annular','dipole']){
 const old=JSON.parse(gunzipSync(execFileSync('git',['show','cac5439a8a51e78290d2a46941a44cc454e3b9dc:dist/data/presets/'+id+'.json.gz'],{maxBuffer:40*1024*1024}))).wave;
 const current=JSON.parse(gunzipSync(readFileSync('dist/data/presets/'+id+'.json.gz'))).wave;
 const zs=[210,436.953125,444.296875,448.5,453.671875,458.984375],start=performance.now();
 const direct=computeWave(presetParams(id),'full',()=>{},zs);
 for(const section of ['xz','yz'])for(const col of direct.columns){
  const peak=Math.max(...col[section]),oldFrame=createWaveSampler({...old,geometry:{}},section)(col.z),frame=createWaveSampler(current,section)(col.z);
  let oldError=0,newError=0,energy=0,peakPosition=0;const truth=[],prediction=[];
  const half=Math.min(.007,Math.max(Math.abs(col.x[0]),col.x.at(-1)));
  for(let i=0;i<2049;i++){const y=-half+2*half*i/2048,t=sampleLine(col.x,col[section],y)/peak,a=(oldFrame.sample(y)||0)/oldFrame.reference,b=(frame.sample(y)||0)/frame.reference;oldError+=(t-a)**2;newError+=(t-b)**2;energy+=t*t;truth.push(t);prediction.push(b);}
  const span=a=>{const indices=a.map((v,i)=>v>=.5?i:-1).filter(i=>i>=0);return indices.length?indices.at(-1)-indices[0]+1:0;};
  results.push({id,section,z:col.z,oldError:Math.sqrt(oldError/energy),newError:Math.sqrt(newError/energy),halfMaximumWidthRatio:span(prediction)/span(truth)});
 }
 console.log(id,'Fine midplane validation',((performance.now()-start)/1000).toFixed(1)+' s');
}
writeFileSync('.sites-runtime/projection-validation.json',JSON.stringify(results,null,2));
console.log(results);
