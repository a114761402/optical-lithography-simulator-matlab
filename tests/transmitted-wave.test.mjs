import test from 'node:test';
import assert from 'node:assert/strict';
import {defaults,geometry,coherent,makeMask,gaussianBeam,sourceSamples,lct,maximum,axis,propagateSame,intensity,slicePlan} from '../dist/optics.js';
import {computeWave,centerCuts,sampleLine} from '../dist/wave.js';
import {computeTransmittedWave,transmittedMaskField} from '../dist/transmitted-wave.js';
import {waveCacheKey} from '../dist/cache.js';
const p={...defaults,gridSize:64,sourceType:'Point',fieldSizeUm:80};
test('Transmitted view reconstructs the actual aperture field upstream on physical coordinates',()=>{
 for(const lensType of ['Circular','Annular','Vertical Slit']){
  const q={...p,lensType},g=geometry(q),zs=[g.mask,g.mask+.1,g.lens1,g.lens1+25,g.pupil-1];
  const w=computeTransmittedWave(q,'full',()=>{},zs),f=coherent(q,makeMask(q),sourceSamples(q)[0],gaussianBeam(q,g.mask));
  const selected=transmittedMaskField(f,q.reduction),dx=q.fieldSizeUm*1e-6/q.gridSize,input=axis(selected.n,dx);
  // Independent full inverse Fourier integral checks orientation and units.
  const inverse=centerCuts(intensity(lct(f.pupil,f.pupilAxis,f.x,q.wavelengthNm*1e-9,0,-g.f1*.001,0)),f.x),selectedCuts=centerCuts(intensity(selected),input);
  for(const key of ['xz','yz'])for(let i=0;i<f.x.length;i++)assert.ok(Math.abs(sampleLine(input,selectedCuts[key],f.x[i])-inverse[key][i])<Math.max(1,maximum(inverse[key]))*1e-9);
  for(const col of w.columns){
   const a=slicePlan(q,col.z);let out,cuts;
   if(a.type==='lct'){out=lct(selected,input,col.x,q.wavelengthNm*1e-9,a.A,a.B,a.D);cuts=centerCuts(intensity(out),col.x);}
   else{out=a.type==='near'?propagateSame(selected,q.wavelengthNm*1e-9,dx,a.dz,'rs'):selected;const c=centerCuts(intensity(out),input);cuts={xz:Float64Array.from(col.x,x=>sampleLine(input,c.xz,x)),yz:Float64Array.from(col.y,x=>sampleLine(input,c.yz,x))};}
   for(const key of ['xz','yz']){const peak=maximum(cuts[key]);for(let i=0;i<cuts[key].length;i++)assert.ok(Math.abs(col[key][i]-cuts[key][i])<=Math.max(1,peak)*1e-9);}
  }
 }
});
test('Closed projection stop removes upstream transmitted field; illumination stays unchanged',()=>{
 const q={...p,lensType:'Freeform',customPupil:Array(16).fill(0)},g=geometry(q),zs=[0,g.mask,g.lens1,g.pupil-1,g.pupil,g.image];
 const full=computeWave(q,'full',()=>{},zs),passed=computeTransmittedWave(q,'full',()=>{},zs);
 assert.deepEqual(passed.columns[0],full.columns[0]);
 for(const col of passed.columns.slice(1))assert.equal(maximum(col.xz),0);
 assert.ok(maximum(full.columns[2].xz)>0);
});
test('Downstream fields and near-mask diffraction remain unchanged; caches distinguish selection',()=>{
 const g=geometry(p),zs=[g.pupil,g.pupil+10,g.lens2,g.image,g.image+.02],a=computeWave(p,'full',()=>{},zs),b=computeTransmittedWave(p,'full',()=>{},zs);
 assert.deepEqual(a.columns,b.columns);assert.equal(b.transmittedOnly,true);
 const near=[g.mask,g.mask+.01];assert.deepEqual(computeWave(p,'near',()=>{},near).columns,computeTransmittedWave(p,'near',()=>{},near).columns);
 assert.notEqual(waveCacheKey(p,'full'),waveCacheKey(p,'full',true));
});
