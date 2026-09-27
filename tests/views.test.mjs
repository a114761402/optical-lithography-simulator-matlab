import test from 'node:test';
import assert from 'node:assert/strict';
import {defaults,geometry,compute} from '../dist/optics.js';
import {computeViews,computeScreen} from '../dist/views.js';
const p={...defaults,sourceType:'Point',gridSize:128,sourceBins:1,lensType:'Annular',lensInner:.65};
test('Moving the observation screen leaves every fixed reference field unchanged',()=>{
 const g=geometry(p),focused=computeViews(p,g.image),near=computeViews(p,g.mask+.001);
 assert.equal(focused.planes,focused.screen);
 for(const key of ['screenRaw','sourceRaw','maskRaw','pupilRaw'])assert.deepEqual(near.planes[key],focused.planes[key],key);
 assert.equal(near.planes.z,g.image);assert.equal(near.planes.label,'Image plane');
 assert.equal(near.screen.z,g.mask+.001);assert.equal(near.screen.label,'Mask diffraction');
 assert.deepEqual(near.screen.screenRaw,compute({...p,defocusUm:0},g.mask+.001).screenRaw);
});
test('Defocus affects the movable screen, not the fixed image or shared intensity reference',()=>{
 const q={...p,defocusUm:25},g=geometry(q),views=computeViews(q,g.screen),fixed=computeViews(p,g.image);
 assert.equal(views.planes.z,g.image);assert.equal(views.screen.z,g.image+.025);
 assert.deepEqual(views.planes.screenRaw,fixed.planes.screenRaw);
 assert.notDeepEqual(views.screen.screenRaw,views.planes.screenRaw);
 assert.equal(views.screen.sharedPeak,views.planes.sharedPeak);
 assert.equal(views.screen.label,'Through focus');
});
test('Screen-only updates match the combined view; progress finishes and invalid positions fail',()=>{
 const g=geometry(p),progress=[],r=computeViews(p,g.pupil,v=>progress.push(v));
 assert.deepEqual(computeScreen(p,g.pupil).screenRaw,r.screen.screenRaw);
 assert.equal(progress.at(-1),1);assert.ok(progress.every((v,i)=>i===0||v>=progress[i-1]));
 assert.throws(()=>computeScreen(p,-1),/Place the screen/);
});

test('Changing relay focal lengths updates the physical image reference while screen moves independently',()=>{
 const q={...p,f1Mm:120,reduction:3},g=geometry(q),r=computeViews(q,g.mask);
 assert.equal(r.planes.z,520);assert.equal(r.screen.z,200);assert.equal(r.planes.label,'Image plane');
 assert.equal(r.planes.geometry.image,g.image);assert.equal(r.planes.geometry.f2,40);
});
