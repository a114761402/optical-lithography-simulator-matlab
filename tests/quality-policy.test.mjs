import test from 'node:test';
import assert from 'node:assert/strict';
import {DetailPreferences,sameSlice,sufficientSlice,bestSlice} from '../dist/quality-policy.js';
import {QUALITY} from '../dist/quality.js';
import {defaults,geometry} from '../dist/optics.js';
import {SliceCache,sliceKey} from '../dist/observation-state.js';
import {hydratePositions,restorePositions} from '../dist/reference-positions.js';
test('Standard defaults fast; Expert and desktop share a separate persistent choice',()=>{
 const d=new DetailPreferences();assert.equal(d.get(true,false),false);assert.equal(d.get(true,true),true);assert.equal(d.get(false,false),true);
 d.set(true,false,true);d.set(false,false,false);assert.equal(d.get(true,false),true);assert.equal(d.get(true,true),false);assert.equal(d.quality(true,true).gridSize,256);
});
test('Fine cache fulfills Fast without relabeling or accepting different physics/positions',()=>{
 const params={...defaults,...QUALITY.standard},fast={params,z:450},fine={params:{...params,...QUALITY.fine},z:450};
 assert.equal(bestSlice([fast,fine],params,450),fine);assert.equal(bestSlice([fast],fine.params,450),undefined);
 assert.equal(sufficientSlice(fine,params,449.999),false);assert.equal(sameSlice(fine,{...params,sourceType:'Annular'},450),false);
 assert.equal(sameSlice(fast,fine.params,450),true);
 const cache=new SliceCache();cache.set(sliceKey(fine.params,450),fine);const panels=restorePositions();hydratePositions(panels,geometry(params),params,cache,1);
 assert.equal(panels[3].result,fine);assert.equal(panels[3].resultKey,sliceKey(fine.params,450));
});
