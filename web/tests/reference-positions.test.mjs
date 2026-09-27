import test from 'node:test';
import assert from 'node:assert/strict';
import {defaults,geometry} from '../dist/optics.js';
import {setObservation,tuneObservation,observationZ,sliceRequest,acceptsSlice,SliceCache,sliceKey} from '../dist/observation-state.js';
import {restorePositions,hydratePositions,atReferencePositions,referenceDisplayMode} from '../dist/reference-positions.js';

test('Reference preset follows geometry while Undo restores custom offsets and rejects replaced jobs',()=>{
  const g=geometry(defaults),custom=restorePositions();
  setObservation(custom[0],g,123);tuneObservation(custom[0],g,12);
  custom.splice(2,1);const old=sliceRequest(custom[0],g,defaults);
  const references=restorePositions(),restored=restorePositions(custom);
  assert.equal(atReferencePositions(references),true);
  assert.equal(atReferencePositions(custom),false);
  assert.deepEqual(restored.map(p=>p.id),['A','B','D']);
  assert.equal(observationZ(restored[0],g),123.012);
  assert.equal(acceptsSlice(restored[0],old,g,defaults),false);
  assert.equal(acceptsSlice(references[0],old,g,defaults),false);
  const changed=geometry({...defaults,condenserFocalMm:130,f1Mm:140});
  assert.deepEqual(references.map(p=>observationZ(p,changed)),[0,changed.mask,changed.pupil,changed.image]);
});
test('Restoring positions uses only matching optical settings and quality from cache',()=>{
  const g=geometry(defaults),cache=new SliceCache(),planes=restorePositions();
  const data={screenRaw:[42]},key=sliceKey(defaults,g.mask);cache.set(key,data);
  hydratePositions(planes,g,defaults,cache,7);
  assert.equal(planes[1].result,data);assert.equal(planes[1].resultRevision,7);
  const changed=restorePositions();hydratePositions(changed,g,{...defaults,gridSize:512},cache,8);
  assert.equal(changed[1].result,null);
});
test('Opening and source modes apply only at current, exact named reference positions',()=>{
  const p=restorePositions(),choices={source:'weights',mask:'amplitude',pupil:'opening'};
  assert.deepEqual(p.map(panel=>referenceDisplayMode(panel,choices)),['weights','mask-opening','aperture-opening','intensity']);
  p[1].offset=.5;assert.equal(referenceDisplayMode(p[1],choices),'intensity');
  p[1].offset=0;p[1].plane='custom';assert.equal(referenceDisplayMode(p[1],choices),'intensity');
  assert.equal(referenceDisplayMode(p[0],choices,false),'intensity');
  assert.equal(referenceDisplayMode(null,choices),'intensity');
});
