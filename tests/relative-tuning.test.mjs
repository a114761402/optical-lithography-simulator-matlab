import test from 'node:test';
import assert from 'node:assert/strict';
import {RelativeTuning} from '../dist/relative-tuning.js';
import {createPlane,tuneObservation,observationZ} from '../dist/observation-state.js';
function stroke(speed,dt=10,distance=100){const m=new RelativeTuning(50,470,0,0);let x=0,t=0;while(x<distance){const dx=Math.min(speed*dt,distance-x);x+=dx;t+=dx/speed;m.move(x,t);}return m.z-50;}
test('Slow motion has micrometre control; faster strokes cover the optical path',()=>{
 assert.ok(stroke(.04)<.21);assert.ok(stroke(2)>70&&stroke(2)<160);
});
test('Sub-micrometre residuals accumulate instead of being rounded away',()=>{
 const m=new RelativeTuning(40,470,0,0);let out;
 for(let i=1;i<=20;i++)out=m.move(i*.1,i*10);
 assert.equal(out,40.004);
});
test('Tuning settings adjust slow and fast travel and can disable glide',()=>{
 const travel=(options,step)=>{const m=new RelativeTuning(100,470,0,0,options);for(let i=1;i<=20;i++)m.move(i*step,i*10);return m.z-100;};
 assert.ok(travel({slow:.5},.1)<travel({},.1));
 assert.ok(travel({slow:2},.1)>travel({},.1));
 assert.ok(travel({fast:.5},12)<travel({},12));
 assert.ok(travel({fast:1.5},12)>travel({},12));
 const noGlide=new RelativeTuning(100,470,0,0,{glide:0});
 for(let i=1;i<=8;i++)noGlide.move(i*12,i*10);
 assert.equal(noGlide.release(80),null);
});
test('Equivalent motion at 60 and 120Hz has similar travel',()=>{
 const a=stroke(.8,1000/60),b=stroke(.8,1000/120);
 assert.ok(Math.abs(a-b)/a<.03,`${a} vs ${b}`);
});
test('Stationary contact has no drift and slowing or reversing restores fine control',()=>{
 const m=new RelativeTuning(20,470,0,0);m.move(100,60);const z=m.z;
 m.move(100,1000);assert.equal(m.z,z);m.move(99.9,1010);assert.ok(Math.abs(m.z-z)<.001);
});
test('Endpoints discard overshoot; reversing moves immediately; a new contact never jumps',()=>{
 const m=new RelativeTuning(469,470,0,0);m.move(1000,20);assert.equal(m.z,470);
 assert.equal(m.move(999,100),469.998);
 const n=new RelativeTuning(469.998,470,300,200);assert.equal(n.move(300,210),469.998);
 const lower=new RelativeTuning(0,470,0,0);lower.move(-1000,10);assert.equal(lower.z,0);assert.equal(lower.move(-999,100),.002);
});
test('Tuning stops at the image plane even when the physical screen can travel farther',()=>{
 const image=450,physicalLimit=470;
 const tuning=new RelativeTuning(image-1,image,0,0);
 tuning.move(1000,20);assert.equal(tuning.z,image);assert.equal(tuning.release(20),null);
 assert.ok(image<physicalLimit);
 const outside=new RelativeTuning(physicalLimit,image,0,0);
 assert.equal(outside.z,image);
 assert.equal(outside.move(10,100),image);
 assert.ok(outside.move(9,200)<image);
});
test('Desktop fine offsets cover ±2.5mm while retaining the named anchor and physical bounds',()=>{
 const g={mask:200,max:470},p=createPlane('A','mask');tuneObservation(p,g,2500);assert.equal(observationZ(p,g),202.5);
 tuneObservation(p,g,-2500);assert.equal(observationZ(p,g),197.5);assert.equal(p.plane,'mask');tuneObservation(p,g,0);assert.equal(observationZ(p,g),200);
 tuneObservation(p,g,999999);assert.equal(observationZ(p,g),470);
});

test('Captured scrubbing coalesces updates, flushes on release, and cancels queued edits when selection changes',async()=>{
 const {setupRelativeTuning}=await import('../dist/relative-tuning.js');
 const globals={window:globalThis.window,document:globalThis.document,requestAnimationFrame:globalThis.requestAnimationFrame,cancelAnimationFrame:globalThis.cancelAnimationFrame};
 const handlers={},documents={},windows={},frames=new Map(),capture=new Set();let next=0,z=40,identity='A',calls=0,active=false;
 globalThis.window={addEventListener:(n,f)=>windows[n]=f};globalThis.document={hidden:false,addEventListener:(n,f)=>(documents[n]??=[]).push(f)};
 globalThis.requestAnimationFrame=f=>{frames.set(++next,f);return next;};globalThis.cancelAnimationFrame=id=>frames.delete(id);
 const node={addEventListener:(n,f)=>handlers[n]=f,setAttribute(){},style:{setProperty(){},removeProperty(){}},classList:{add(){},remove(){}},focus(){},setPointerCapture:id=>capture.add(id),hasPointerCapture:id=>capture.has(id),releasePointerCapture:id=>capture.delete(id)};
 const event=(name,x,time,id=1)=>handlers[name]?.({pointerId:id,isPrimary:id===1,button:0,clientX:x,timeStamp:time,preventDefault(){}});
 try{
  setupRelativeTuning(node,{currentZ:()=>z,maximum:()=>470,enabled:()=>true,target:()=>identity,onMove:v=>{z=v;calls++;},onActiveChange:value=>active=value});
  event('pointerdown',100,0);assert.equal(active,true);event('pointermove',101,50);event('pointermove',102,100);assert.equal(frames.size,1);assert.equal(calls,0);
  event('pointerup',102,100);assert.equal(z,40.004);assert.equal(calls,1);assert.equal(capture.size,0);assert.equal(frames.size,0);assert.equal(active,false);
  event('pointerdown',100,200);event('pointermove',101,250);identity='B';event('pointermove',102,300);assert.equal(z,40.004);assert.equal(calls,1);assert.equal(capture.size,0);
  event('pointerdown',100,400);event('pointermove',101,450);event('pointercancel',101,450);assert.equal(capture.size,0);const stopped=z;event('pointermove',110,460);assert.equal(z,stopped);
  event('pointerdown',100,500);for(const f of documents.pointerdown)f({pointerId:2});assert.equal(capture.size,0);
  event('pointerdown',100,600);windows.blur();assert.equal(capture.size,0);
 }finally{for(const [key,value]of Object.entries(globals)){if(value===undefined)delete globalThis[key];else globalThis[key]=value;}}
});

test('Momentum is reserved for sustained fast releases; slow, held, reversed and endpoint releases stop',()=>{
 const fast=()=>{const m=new RelativeTuning(100,470,0,0);for(let i=1;i<=8;i++)m.move(i*12,i*10);return m;};
 assert.ok(fast().release(81));assert.equal(fast().release(150),null);
 const slow=fast();slow.move(96.1,90);assert.equal(slow.release(90),null);
 const held=fast();held.move(96,90);assert.equal(held.release(90),null);
 const reversed=fast();reversed.move(84,90);assert.equal(reversed.release(90),null);
 const edge=new RelativeTuning(470,470,0,0);for(let i=1;i<=8;i++)edge.move(i*20,i*10);assert.equal(edge.release(80),null);
});
test('Momentum is short, bounded, refresh-rate independent and never bounces',async()=>{
 const {TuningCoast}=await import('../dist/relative-tuning.js');
 const a=new TuningCoast(100,470,.376),b=new TuningCoast(100,470,.376);
 for(let t=0;t<240;t+=1000/60)a.advance(t);for(let t=0;t<240;t+=1000/120)b.advance(t);
 assert.equal(a.advance(240),b.advance(240));assert.ok(a.z-100<34);assert.ok(a.done);
 const edge=new TuningCoast(469,470,.376);assert.equal(edge.advance(16),470);assert.ok(edge.done);
 const low=new TuningCoast(1,470,-.376);assert.equal(low.advance(16),0);assert.ok(low.done);
});
test('Regrip, compute stop, changed selection, external edits, mode and background cancel momentum and stale frames',async()=>{
 const {setupRelativeTuning}=await import('../dist/relative-tuning.js');
 const originals=Object.fromEntries(['window','document','requestAnimationFrame','cancelAnimationFrame'].map(k=>[k,globalThis[k]]));
 const handlers={},docs={},wins={},frames=new Map(),captured=new Set(),activation=[];let serial=0,z=100,identity='A',active=false;
 globalThis.window={addEventListener:(n,f)=>wins[n]=f};globalThis.document={hidden:false,addEventListener:(n,f)=>(docs[n]??=[]).push(f)};
 globalThis.requestAnimationFrame=f=>{frames.set(++serial,f);return serial;};globalThis.cancelAnimationFrame=id=>frames.delete(id);
 const node={contains:t=>t===node,addEventListener:(n,f)=>handlers[n]=f,setAttribute(){},style:{setProperty(){},removeProperty(){}},classList:{add(){},remove(){}},focus(){},setPointerCapture:id=>captured.add(id),hasPointerCapture:id=>captured.has(id),releasePointerCapture:id=>captured.delete(id)};
 const event=(name,x,time)=>handlers[name]?.({pointerId:1,isPrimary:true,button:0,clientX:x,timeStamp:time,preventDefault(){}});
 const dispatch=(name,e={})=>{for(const f of docs[name]||[])f(e);};
 const tick=t=>{const batch=[...frames.values()];frames.clear();for(const f of batch)f(t);};
 try{
  const control=setupRelativeTuning(node,{currentZ:()=>z,maximum:()=>470,enabled:()=>true,target:()=>identity,onMove:v=>{z=v;dispatch('observation-position-change');},onActiveChange:value=>{active=value;activation.push(value);}});
  const flick=()=>{z=100;identity='A';document.hidden=false;event('pointerdown',0,0);for(let i=1;i<=8;i++)event('pointermove',12*i,10*i);event('pointerup',96,80);assert.deepEqual(activation.slice(-2),[true,true],'drag and coast are one active edit');tick(1000);tick(1016);assert.equal(frames.size,1);assert.equal(active,true);};
  for(const halt of [()=>control.stop(),()=>dispatch('pointerdown',{pointerId:2}),()=>dispatch('click',{target:{}}),()=>dispatch('input',{target:{}}),()=>dispatch('change',{target:{}}),()=>dispatch('position-view-change'),()=>{document.hidden=true;dispatch('visibilitychange');},()=>wins.blur()]){
   flick();const stale=[...frames.values()],shown=z;halt();assert.equal(frames.size,0);assert.equal(active,false);for(const f of stale)f(1100);assert.equal(z,shown,'must compute/regrip at the displayed position');
  }
  flick();const shown=z;event('pointerdown',700,90);assert.equal(z,shown);event('pointermove',700,100);tick(1100);assert.equal(z,shown);control.stop();
  flick();identity='B';const before=z;tick(1032);assert.equal(z,before);assert.equal(frames.size,0);
  flick();z=200;dispatch('observation-position-change');tick(1100);assert.equal(z,200);
  control.stop();handlers.keydown({key:'ArrowRight',preventDefault(){}});assert.equal(active,true);handlers.keyup();assert.equal(active,false);
  flick();const paused=z;tick(1400);assert.equal(z,paused);assert.equal(frames.size,0);
 }finally{for(const[k,v]of Object.entries(originals)){if(v===undefined)delete globalThis[k];else globalThis[k]=v;}}
});
