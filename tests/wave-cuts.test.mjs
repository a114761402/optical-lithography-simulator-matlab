import test from 'node:test';
import assert from 'node:assert/strict';
import {field,axis,lct,intensity} from '../dist/optics.js';
import {centerCuts} from '../dist/wave.js';
import {lctCenterCuts} from '../dist/wave-cuts.js';
const error=(a,b)=>Math.sqrt(a.reduce((s,v,i)=>s+(v-b[i])**2,0)/Math.max(b.reduce((s,v)=>s+v*v,0),Number.MIN_VALUE));
test('Fast Collins cuts agree with the full 2D integral for asymmetric complex fields and offset axes',()=>{
 for(const n of [32,64])for(const sign of [-1,1])for(const shift of [0,.17]){
  const f=field(n),x=Float64Array.from(axis(n,2e-7),v=>v+shift*2e-7),y=Float64Array.from({length:48},(_,i)=>(i-23.3)*3e-5);
  for(let i=0;i<f.re.length;i++){f.re[i]=Math.sin(i*.372)*Math.cos(i*.018);f.im[i]=Math.cos(i*.219);}
  const full=centerCuts(intensity(lct(f,x,y,365e-9,.73,sign*.027,.42)),y),fast=lctCenterCuts(f,x,y,365e-9,.73,sign*.027);
  for(const key of ['xz','yz'])assert.ok(error(fast[key],full[key])<1e-11,`${n}, ${sign}, ${shift}, ${key}`);
 }
});
test('Central-cut evaluation returns zero when the plotted coordinates exclude the origin',()=>{
 const f=field(32),x=axis(32,2e-7),y=Float64Array.from({length:32},(_,i)=>(i+1)*1e-5);f.re.fill(1);
 const fast=lctCenterCuts(f,x,y,365e-9,1,.05);assert.ok([...fast.xz,...fast.yz].every(v=>v===0));
});

test('Cached propagation matches independent uncached fields across kernel, spectrum and evanescent branches',async()=>{
 const {propagateSame}=await import('../dist/optics.js');
 const cache={operators:new Map(),spectra:new WeakMap()};
 for(const n of [64,128]){
  const f=field(n);for(let i=0;i<f.re.length;i++){f.re[i]=Math.sin(i*.17);f.im[i]=Math.cos(i*.43);}
  const original=f.re.slice();
  for(const [dx,z,kind] of [[1e-6,1e-7,'rs'],[1e-6,1e-3,'rs'],[1e-7,1e-8,'rs'],[1e-6,1e-5,'fresnel'],[1e-6,.02,'fresnel'],[1e-6,-.02,'fresnel']]){
   const expected=propagateSame(f,365e-9,dx,z,kind);
   for(let repeat=0;repeat<2;repeat++){
    const actual=propagateSame(f,365e-9,dx,z,kind,cache);
    assert.deepEqual(actual.re,expected.re);assert.deepEqual(actual.im,expected.im);
   }
  }
  assert.deepEqual(f.re,original);
 }
});

test('Propagation cache evicts operators at its memory limit without changing results',async()=>{
 const {propagateSame}=await import('../dist/optics.js');
 const f=field(64);f.re[32*64+32]=1;
 const cache={operators:new Map(),spectra:new WeakMap(),maxBytes:1024*1024};
 for(const z of [1e-5,2e-5,3e-5,1e-5]){
  const expected=propagateSame(f,365e-9,1e-6,z),actual=propagateSame(f,365e-9,1e-6,z,'fresnel',cache);
  assert.deepEqual(actual.re,expected.re);assert.ok(cache.operatorBytes<=cache.maxBytes);
 }
});
