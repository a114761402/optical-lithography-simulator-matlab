import test from 'node:test';
import assert from 'node:assert/strict';
import {createPlanes,appendPositionGroup,availablePlaneId,markedPositions,observationZ,quantizePosition,formatPosition,sliceRequest,acceptsSlice,setObservation} from '../dist/observation-state.js';
import {restorePositions} from '../dist/reference-positions.js';
import {defaults,geometry} from '../dist/optics.js';
const g=geometry(defaults);
test('Desktop adds four, phone adds two; clones share results but not edits or calculation identities',()=>{
 const panels=createPlanes();panels[2].result={screenRaw:new Float64Array([1,2])};
 const row=appendPositionGroup(panels,4);assert.equal(panels.length,8);assert.deepEqual(row.map(p=>p.id),['E','F','G','H']);assert.equal(row[2].result,panels[2].result);
 const original=sliceRequest(panels[0],g,defaults);assert.ok(!acceptsSlice(row[0],original,g,defaults));setObservation(row[0],g,123.456);assert.equal(observationZ(panels[0],g),0);
 const phone=appendPositionGroup(panels,2);assert.deepEqual(phone.map(p=>p.plane),['pupil','image']);assert.equal(panels.length,10);
 for(let i=0;i<5;i++)appendPositionGroup(panels,4);assert.equal(panels.length,30);assert.equal(panels[26].id,'AA');assert.equal(new Set(panels.map(p=>p.instance)).size,30);
 panels.splice(1,1);assert.equal(availablePlaneId(panels),'B');
});
test('Empty layout can add; reset and undo preserve arbitrary groups and reject obsolete requests',()=>{
 const panels=[];appendPositionGroup(panels,2);assert.equal(panels.length,2);assert.ok(panels.every(p=>p.plane==='image'));
 appendPositionGroup(panels,4);const old=sliceRequest(panels[4],g,defaults),restored=restorePositions(panels);assert.equal(restored.length,6);assert.ok(!acceptsSlice(restored[4],old,g,defaults));assert.equal(restorePositions().length,4);
});
test('Expanded beam markers expose editing group and leave other positions as ticks',()=>{
 const panels=createPlanes();for(let i=0;i<3;i++)appendPositionGroup(panels,4);
 const mobile=markedPositions(panels,'J',4);assert.deepEqual(mobile.filter(p=>!p.muted).map(p=>p.id),['I','J','K','L']);assert.equal(mobile.filter(p=>p.muted).length,12);
 assert.equal(markedPositions(panels,'P',8).filter(p=>!p.muted).length,8);
});
test('Micrometre display and manual quantization never mutate exact attached image geometry',()=>{
 const optical={...defaults,reduction:3},geom=geometry(optical),panel=createPlanes()[3],key=sliceRequest(panel,geom,optical);
 assert.equal(quantizePosition(159.559682),159.56);assert.equal(formatPosition(159.559682),'159.56');
 assert.equal(Number(formatPosition(geom.image)),Math.round(geom.image*1000)/1000);
 assert.equal(observationZ(panel,geom),geom.image);assert.ok(acceptsSlice(panel,key,geom,optical));assert.equal(panel.plane,'image');
});
