// Reuse projection arrays only after verifying that every projection operator
// is identical to the cache's recorded engine. Recompute all reference slices,
// illumination columns and the common brightness reference at full Fine detail.
import {readFileSync,writeFileSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import {gunzipSync,gzipSync} from 'node:zlib';
import {createHash} from 'node:crypto';
import {PRESETS,presetParams,presetCacheKey,PRESET_CACHE_VERSION} from '../dist/presets.js';
import {compute,illuminationIntensity,slicePlan} from '../dist/optics.js';
import {enhancePupil} from '../dist/dense-pupil.js';
import {pathPlanes,centerCuts} from '../dist/wave.js';
import {referenceScreens} from '../dist/observation-state.js';
import {validatePresetCache} from '../dist/preset-cache.js';
import {CACHE_VERSION,waveCacheKey,validateWaveCache} from '../dist/cache.js';
const baseline='cf11ed6d9efc56b448d6c552cbd08d8b913c45a4';
const original=f=>execFileSync('git',['show',baseline+':dist/'+f],{encoding:'utf8'}),current=f=>readFileSync(new URL('../dist/'+f,import.meta.url),'utf8');
const strip=s=>s.replace(/\?v=[^'\"]+(?=['\"])/g,'').replace(/^import .*radial-illumination.*\n/m,'').replace(/export function illuminationIntensity[\s\S]*?(?=\nfunction paintValue)/,'').replace(/export function slicePlan[\s\S]*?(?=\nexport function compute)/,'');
if(strip(original('optics.js'))!==strip(current('optics.js')))throw Error('Projection operator changed: full regeneration is required.');
for(const f of ['wave-cuts.js','dense-pupil.js'])if(strip(original(f))!==strip(current(f)))throw Error('Projection operator changed: '+f);
const files=['optics.js','wave.js','wave-cuts.js','dense-pupil.js'];
const oldHash=createHash('sha256').update(files.map(original).join('')).digest('hex');
const engineHash=createHash('sha256').update([...files,'radial-illumination.js'].map(current).join('')).digest('hex');
const encode=v=>JSON.stringify(v,(_,a)=>ArrayBuffer.isView(a)?Array.from(a):a);
const dir=new URL('../dist/data/presets/',import.meta.url);
for(const preset of PRESETS){
 const file=new URL(preset.id+'.json.gz',dir),saved=JSON.parse(gunzipSync(readFileSync(file))),p=presetParams(preset.id),start=performance.now();
 if(saved.engineHash===engineHash&&saved.version===PRESET_CACHE_VERSION){validatePresetCache(saved,preset.id);console.log(preset.id,'already current');continue;}
 if(saved.engineHash!==oldHash&&saved.reusedProjectionFrom?.engineHash!==oldHash)throw Error('Unknown source cache engine '+preset.id);
 if(JSON.stringify(saved.wave.params)!==JSON.stringify(p))throw Error('Optical parameters changed '+preset.id);
 console.log(preset.id,'recomputing Fine reference slices');
 const r=enhancePupil(compute(p)),slices=referenceScreens(r);slices[2].densePupil=true;
 const retained=saved.wave.columns.filter(c=>c.z>=r.geometry.mask),columns=[];
 for(const z of pathPlanes(p)){
  if(z<r.geometry.mask){const plan=slicePlan(p,z),x=plan.axis,y=plan.axisY||x;columns.push({z,x,y,...centerCuts(illuminationIntensity(p,plan.beam,x,y),x,y)});}
  else{const old=retained.find(c=>c.z===z);if(!old)throw Error('Missing unchanged projection plane '+z);columns.push(old);}
 }
 const pupil=columns.find(c=>c.z===r.geometry.pupil);Object.assign(pupil,{x:r.pupilAxis,y:r.pupilAxis,...centerCuts(r.pupilRaw,r.pupilAxis)});
 const wave={...saved.wave,params:p,columns,sharedPeak:r.sharedPeak};
 const cache={version:PRESET_CACHE_VERSION,id:preset.id,key:presetCacheKey(p),engineHash,generatedAt:new Date().toISOString(),reusedProjectionFrom:{engineHash:oldHash,commit:baseline},seconds:(performance.now()-start)/1000,slices,wave};
 const raw=encode(cache);validatePresetCache(JSON.parse(raw),preset.id);writeFileSync(file,gzipSync(raw,{level:9}));
 if(preset.id==='default'){const legacy={version:CACHE_VERSION,key:waveCacheKey(p),engineHash,generatedAt:cache.generatedAt,result:wave};const json=encode(legacy);validateWaveCache(JSON.parse(json));writeFileSync(new URL('../dist/data/default-wave-circular-fine-v4.json',import.meta.url),json);}
 console.log(preset.id,'saved',columns.length,'planes',Math.round(cache.seconds),'seconds');
}
writeFileSync(new URL('manifest.json',dir),JSON.stringify({version:PRESET_CACHE_VERSION,engineHash,presets:PRESETS.map(p=>({id:p.id,key:presetCacheKey(presetParams(p.id)),file:p.id+'.json.gz'}))},null,2));
