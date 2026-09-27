import test from 'node:test';
import assert from 'node:assert/strict';
import {setupScreenDrag} from '../dist/screen-drag.js';
function harness(mobile=true){
  const handlers={},calls=[],classes=new Set(),capture=new Set();let z=200;
  const svg={viewBox:{baseVal:{width:464}},getBoundingClientRect:()=>({left:20,width:464}),addEventListener:(name,fn)=>(handlers[name]??=[]).push(fn),setPointerCapture:id=>capture.add(id),hasPointerCapture:id=>capture.has(id),releasePointerCapture:id=>capture.delete(id),classList:{add:c=>classes.add(c),remove:c=>classes.delete(c)}};
  setupScreenDrag(svg,{geometry:()=>({image:450,max:470,source:0,condenser:100,mask:200,lens1:300,pupil:400,lens2:425}),currentZ:()=>z,compact:()=>mobile,onStart:()=>calls.push('start'),onSelect:id=>calls.push(['select',id]),onMove:(value,plane)=>{z=value;calls.push(['move',value,plane]);},onDragStart:()=>calls.push('drag'),onDragEnd:()=>calls.push('end')});
  const marker={dataset:{positionMarker:'B'},getAttribute:()=>200},screen={dataset:{},getAttribute:()=>z};
  function event(type,x,y,{id=1,handle=marker,primary=true}={}){const e={pointerId:id,clientX:x,clientY:y,button:0,isPrimary:primary,target:{closest:()=>handle},preventDefault(){this.prevented=true;},stopImmediatePropagation(){this.stopped=true;}};for(const fn of handlers[type]||[])fn(e);return e;}
  return {event,calls,classes,capture,screen,get z(){return z;}};
}
test('Mobile label dragging uses finger displacement, preserves identity and never invokes mode switching',()=>{
  const h=harness();h.event('pointerdown',280,130);h.event('pointermove',283,131);assert.equal(h.calls.length,0);
  h.event('pointermove',340,131);assert.equal(h.z,260);assert.deepEqual(h.calls.slice(0,2),['drag',['select','B']]);
  h.event('pointermove',2000,130);assert.equal(h.z,450);h.event('pointerup',2000,130);
  assert.ok(!h.calls.includes('start'));assert.equal(h.calls.at(-1),'end');assert.equal(h.capture.size,0);
  assert.ok(h.event('click',2000,130).stopped);
});
test('Vertical gestures and pointer cancellation leave positions untouched and do not select',()=>{
  const h=harness();h.event('pointerdown',280,130);h.event('pointermove',282,150);h.event('pointerup',282,150);assert.deepEqual(h.calls,[]);assert.equal(h.z,200);
  h.event('pointerdown',280,130);h.event('pointercancel',280,130);assert.deepEqual(h.calls,[]);assert.equal(h.capture.size,0);
});
test('A tap selects without moving; unrelated fingers cannot move or end the gesture',()=>{
  const h=harness();h.event('pointerdown',280,130);h.event('pointermove',350,130,{id:2});h.event('pointerup',350,130,{id:2});assert.equal(h.z,200);
  h.event('pointerup',280,130);assert.deepEqual(h.calls,[['select','B']]);
});
test('Standard mobile handle moves without selecting a different observation; lost capture cleans up',()=>{
  const h=harness();h.event('pointerdown',280,40,{handle:h.screen});h.event('pointermove',230,40,{handle:h.screen});assert.equal(h.z,150);
  h.event('lostpointercapture',230,40);assert.equal(h.classes.size,0);assert.equal(h.capture.size,0);assert.ok(!h.calls.some(c=>Array.isArray(c)&&c[0]==='select'));
});
test('Desktop handles retain reference snapping and observation navigation',()=>{
  const h=harness(false);h.event('pointerdown',220,40,{handle:h.screen});h.event('pointermove',317,40,{handle:h.screen});assert.equal(h.z,300);assert.equal(h.calls[0],'start');h.event('pointerup',317,40);assert.equal(h.capture.size,0);
});
