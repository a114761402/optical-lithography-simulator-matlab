import test from 'node:test';
import assert from 'node:assert/strict';
import {defaults,slicePlan,coherent,makeMask,gaussianBeam,lct,intensity,geometry} from '../dist/optics.js';
import {wavePlan,pathPlanes,centerCuts,computeWave} from '../dist/wave.js';
import {lctCenterCuts} from '../dist/wave-cuts.js';
import {createWaveSampler} from '../dist/wave-display.js';
const p={...defaults,sourceType:'Point',gridSize:64,sourceBins:1,projNA:.06};
test('Expanded cut support agrees with independently evaluated full 2D diffraction, including the added tails',()=>{
 for(const z of [220,300,440,455]){const a=wavePlan(p,z),original=slicePlan(p,z),g=geometry(p),f=coherent(p,makeMask(p),{u:0,v:0,w:1},gaussianBeam(p,g.mask));
  assert.equal(a.axis.length,3*original.axis.length);assert.ok(Math.abs((a.axis[1]-a.axis[0])/(original.axis[1]-original.axis[0])-1)<1e-12);
  const field=a.before?f.mask:f.image,x=a.before?f.x:f.imageAxis,full=centerCuts(intensity(lct(field,x,a.axis,p.wavelengthNm*1e-9,a.A,a.B,a.D)),a.axis),cut=lctCenterCuts(field,x,a.axis,p.wavelengthNm*1e-9,a.A,a.B);
  for(const key of ['xz','yz']){let e=0,d=0;for(let i=0;i<a.axis.length;i++){e+=(cut[key][i]-full[key][i])**2;d+=full[key][i]**2;}assert.ok(Math.sqrt(e/d)<1e-11);}
 }
});
test('Local axial refinement resolves focus while preserving exact component planes',()=>{
 const g=geometry(p),zs=pathPlanes(p);for(const z of [g.mask,g.lens1,g.pupil,g.lens2,g.image])assert.ok(zs.includes(z));
 const near=zs.filter(z=>Math.abs(z-g.image)<3);assert.ok(near.length>=20);assert.ok(zs.length<280);
});
test('Projection interpolation is nonnegative, bounded by adjacent intensities and continuous through a phase-only lens',()=>{
 const cols=[0,1,2,3,4,5].map((z,i)=>({z,x:[-1,0,1],y:[-1,0,1],xz:[0,[1,2,4,8,16,32][i],0],yz:[0,1,0]})),r={geometry:{mask:-1,lens1:2.5},columns:cols,zMin:0,zMax:5,sharedPeak:32},sampler=createWaveSampler(r,'xz','shared');
 for(let z=1;z<4;z+=.017){const v=sampler(z).sample(0),i=Math.floor(z);assert.ok(v>=cols[i].xz[1]&&v<=cols[i+1].xz[1]);}
 assert.ok(Math.abs(sampler(2.5-1e-8).sample(0)-sampler(2.5+1e-8).sample(0))<1e-6);
 for(const c of cols)assert.equal(sampler(c.z).sample(0),c.xz[1]);
});
test('Expanded output respects the input sampling Nyquist bound for coarse near-mask cuts',()=>{
 const z=geometry(p).mask+.5,a=wavePlan(p,z),base=slicePlan(p,z),limit=p.wavelengthNm*1e-9*Math.abs(a.B)/(2*p.fieldSizeUm*1e-6/p.gridSize);
 assert.ok(a.axis.length<base.axis.length*3);assert.ok(Math.max(Math.abs(a.axis[0]),Math.abs(a.axis.at(-1)))<=limit+1e-12);
});
