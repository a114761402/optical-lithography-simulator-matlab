import test from 'node:test';
import assert from 'node:assert/strict';
import {experiment} from '../dist/experiments.js';
import {sourceValue,pupilValue,geometry,slicePlan} from '../dist/optics.js';
import {DEFAULT_WAVE_PARAMS,waveCacheKey} from '../dist/cache.js';
import {QUALITY} from '../dist/quality.js';
import {screenSnapshot,displayPlaneLabel} from '../dist/observation-state.js';

test('Annular illumination changes the source and leaves the projection aperture circular',()=>{
  const circular=experiment('circular'),annular=experiment('annular');
  assert.equal(annular.selected,'source');assert.equal(annular.params.sourceType,'Annular');
  assert.equal(sourceValue(circular.params,0,0),1);assert.equal(sourceValue(annular.params,0,0),0);
  assert.equal(sourceValue(annular.params,.25,0),1);
  for(const [x,y] of [[0,0],[.5,0],[.8,.3],[1.1,0]])assert.equal(pupilValue(annular.params,x,y),pupilValue(circular.params,x,y));
  assert.equal(annular.params.lensType,'Circular');assert.equal(pupilValue(annular.params,0,0),1);
});
test('An annular projection aperture is independent of the illumination distribution',()=>{
  const source=experiment('circular').params,aperture={...source,lensType:'Annular'};
  for(const [x,y] of [[0,0],[.25,0],[.2,.2],[.4,0]])assert.equal(sourceValue(aperture,x,y),sourceValue(source,x,y));
  assert.equal(pupilValue(source,0,0),1);assert.equal(pupilValue(aperture,0,0),0);
});
test('Circular illumination retains the existing Fine cache; annular illumination rejects it',()=>{
  assert.equal(waveCacheKey({...experiment('circular').params,...QUALITY.fine}),waveCacheKey(DEFAULT_WAVE_PARAMS));
  assert.notEqual(waveCacheKey({...experiment('annular').params,...QUALITY.fine}),waveCacheKey(DEFAULT_WAVE_PARAMS));
});
test('Aperture plane labels describe the projection location without altering numerical results',()=>{
  const p=experiment('circular').params,z=geometry(p).pupil,raw=new Float64Array([1,2,3,4]);
  const r={params:p,geometry:geometry(p),z,label:slicePlan(p,z).label,screenRaw:raw};
  const shown=screenSnapshot(r);
  assert.equal(shown.label,'Aperture plane');assert.equal(shown.z,z);assert.equal(shown.screenRaw,raw);assert.equal(shown.params,p);
  assert.equal(r.label,'Pupil exit');assert.equal(displayPlaneLabel('Pupil to lens 2'),'Aperture to lens 2');
});
