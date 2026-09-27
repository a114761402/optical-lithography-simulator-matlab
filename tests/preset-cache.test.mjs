import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {gunzipSync} from 'node:zlib';
import {PRESETS,presetParams,matchingPreset} from '../dist/presets.js';
import {validatePresetCache} from '../dist/preset-cache.js';
import {validate,maximum} from '../dist/optics.js';
for(const preset of PRESETS)test(preset.name+' has complete Fine key positions and both full-path cuts',()=>{
  const params=presetParams(preset.id);validate(params);
  const raw=JSON.parse(gunzipSync(readFileSync(new URL('../dist/data/presets/'+preset.id+'.json.gz',import.meta.url))));
  const checked=validatePresetCache(raw,preset.id);
  assert.equal(params.gridSize,512);assert.equal(params.sourceBins,25);assert.equal(checked.slices[2].screenAxis.length,257);
  for(const slice of checked.slices){assert.ok(maximum(slice.screenRaw)>0);assert.ok(slice.screenRaw.every(v=>v>=0));}
  const pupilColumn=checked.wave.columns.find(c=>c.z===checked.slices[2].z);assert.deepEqual(Array.from(pupilColumn.x),Array.from(checked.slices[2].screenAxis));
  assert.equal(matchingPreset(params).id,preset.id);assert.equal(matchingPreset({...params,wavelengthNm:400}),undefined);
  assert.throws(()=>validatePresetCache({...raw,id:'wrong'},preset.id));
});
