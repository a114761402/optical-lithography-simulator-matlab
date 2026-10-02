import test from 'node:test';
import assert from 'node:assert/strict';
import {createPlanes,appendPositionGroup,availablePlaneId,duplicatePositionAfter,relabelPositions,interpolatePositions,markedPositions,observationZ,quantizePosition,formatPosition,sliceRequest,acceptsSlice,setObservation} from '../dist/observation-state.js';
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
test('A card copy is inserted after its source; removal closes letter gaps without reusing calculation identity',()=>{
 const panels=createPlanes(),source=panels[1],shifted=panels[2];
 setObservation(source,g,123.456);source.result={screenRaw:new Float64Array([1,2,3])};
 const oldRequest=sliceRequest(shifted,g,defaults),copy=duplicatePositionAfter(panels,'B');
 assert.deepEqual(panels.map(panel=>panel.id),['A','B','C','D','E']);
 assert.equal(panels[2],copy);assert.notEqual(copy.instance,source.instance);
 assert.equal(copy.result,source.result);assert.equal(observationZ(copy,g),observationZ(source,g));
 assert.equal(shifted.id,'D');assert.ok(!acceptsSlice(shifted,oldRequest,g,defaults));
 panels.splice(1,1);relabelPositions(panels);
 assert.deepEqual(panels.map(panel=>panel.id),['A','B','C','D']);
 assert.equal(panels[1],copy);assert.equal(copy.result,source.result);
});
test('Interpolation changes only intermediate slice coordinates, in card order, and rejects old work',()=>{
 const panels=createPlanes();appendPositionGroup(panels,2);
 setObservation(panels[0],g,420);setObservation(panels[3],g,60);
 const original=panels.map(panel=>({id:panel.id,z:observationZ(panel,g),generation:panel.generation}));
 const request=sliceRequest(panels[1],g,defaults);
 const updated=interpolatePositions(panels,'D','A',g);
 assert.deepEqual(updated.map(panel=>panel.id),['B','C']);
 assert.deepEqual(updated.map(panel=>observationZ(panel,g)),[300,180]);
 assert.ok(updated.every(panel=>panel.plane==='custom'&&panel.offset===0));
 assert.ok(!acceptsSlice(panels[1],request,g,defaults));
 for(const index of [0,3,4,5])assert.deepEqual({id:panels[index].id,z:observationZ(panels[index],g),generation:panels[index].generation},original[index]);
 assert.deepEqual(interpolatePositions(panels,'B','C',g),[]);
 assert.deepEqual(interpolatePositions(panels,'A','missing',g),[]);
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

test('Browser module graph shares one identity allocator across add, reset and undo',async()=>{
 const {readFile}=await import('node:fs/promises');
 const app=await readFile(new URL('../dist/app.js',import.meta.url),'utf8');
 const load=name=>{
  const specifier=app.match(new RegExp("from ['\"](\\./"+name+"\\.js[^'\"]*)['\"]"))[1];
  return import(new URL(specifier,new URL('../dist/app.js',import.meta.url)));
 };
 const state=await load('observation-state'),reference=await load('reference-positions');
 let panels=state.createPlanes();const seen=new Set(panels.map(p=>p.instance));
 const fresh=items=>{for(const p of items){assert.ok(!seen.has(p.instance),'reused position identity');seen.add(p.instance);}};
 fresh(state.appendPositionGroup(panels,2));const saved=panels;
 panels=reference.restorePositions();fresh(panels);assert.deepEqual(panels.map(p=>p.id),['A','B','C','D']);
 fresh(state.appendPositionGroup(panels,2));
 panels=reference.restorePositions(saved);fresh(panels);assert.deepEqual(panels.map(p=>p.id),['A','B','C','D','E','F']);
});
