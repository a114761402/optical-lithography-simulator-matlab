import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {gunzipSync} from 'node:zlib';
import {presetParams} from '../dist/presets.js';
import {gaussianBeam,slicePlan,illuminationIntensity,maximum} from '../dist/optics.js';
import {radialIllumination} from '../dist/radial-illumination.js';
import {createWaveSampler,renderWavePixels} from '../dist/wave-display.js';
import {centerCuts} from '../dist/wave.js';

test('Continuous annulus agrees with its independent closed-form on-axis integral',()=>{
 const p=presetParams('annular');
 for(const z of [0,.1,1,5,20,99,100,150,199]){const b=gaussianBeam(p,z),inner=p.sourceInner*b.scale,outer=p.sourceOuter*b.scale,K=2*b.alpha*b.eta*b.eta-2*b.beta,expected=b.gainAbs2*(Math.exp(-K*inner*inner)-Math.exp(-K*outer*outer))/(K*(outer*outer-inner*inner)),actual=radialIllumination(b,inner,outer,0);assert.ok(Math.abs(actual-expected)<Math.max(expected*2e-6,1e-9),`z=${z}: ${actual} vs ${expected}`);}
});
test('Circular and annular illumination preserve power before the condenser and symmetry',()=>{
 for(const id of ['default','annular']){const p=presetParams(id);for(const z of [0,.1,1,20,90]){const plan=slicePlan(p,z),raw=illuminationIntensity(p,plan.beam,plan.axis),dx=plan.axis[1]-plan.axis[0];let power=0;for(const v of raw)power+=v*dx*dx;assert.ok(Math.abs(power-1)<1e-4,`${id} ${z} power ${power}`);const peak=maximum(raw);for(let i=0;i<raw.length;i+=431)assert.ok(Math.abs(raw[i]-raw[raw.length-1-i])<peak*1e-9);}}
});
test('Off-axis illumination agrees with independent polar source quadrature',()=>{
 // Equal-area rings and midpoint angles integrate individual emitter intensities
 // directly, without the production erf reduction, LUT, or adaptive integrator.
 for(const id of ['default','annular'])for(const z of [20,100,199]){
  const p=presetParams(id),b=gaussianBeam(p,z),inner=(id==='annular'?p.sourceInner:0)*b.scale,outer=p.sourceOuter*b.scale;
  for(const r of [outer*.3,outer,outer*2]){let sum=0;const nr=240,nt=720;
   for(let j=0;j<nr;j++){const q=Math.sqrt(inner*inner+(j+.5)/nr*(outer*outer-inner*inner));for(let k=0;k<nt;k++){const theta=(k+.5)*2*Math.PI/nt;sum+=b.gainAbs2*Math.exp(2*b.beta*q*q-2*b.alpha*((r-b.eta*q*Math.cos(theta))**2+(b.eta*q*Math.sin(theta))**2));}}
   const expected=sum/(nr*nt),actual=radialIllumination(b,inner,outer,r);assert.ok(Math.abs(actual-expected)<Math.max(expected*1e-4,1e-10),`${id} z=${z} r=${r}: ${actual} vs ${expected}`);
  }
 }
});
test('Cached annular interpolation follows direct physical cuts between early source planes',()=>{
 const cache=JSON.parse(gunzipSync(readFileSync(new URL('../dist/data/presets/annular.json.gz',import.meta.url)))),sampler=createWaveSampler(cache.wave),p=presetParams('annular');
 for(const z of [.15,.75,3.671875,11.015625,27.125]){const plan=slicePlan(p,z),cut=centerCuts(illuminationIntensity(p,plan.beam,plan.axis),plan.axis).xz,peak=maximum(cut),frame=sampler(z);let error=0;for(let i=0;i<cut.length;i++)error=Math.max(error,Math.abs(cut[i]/peak-(frame.sample(plan.axis[i])||0)/frame.reference));assert.ok(error<.04,`z=${z}, normalized error=${error}`);}
});
test('The wave canvas defaults to rectangular dark background; window bounds remain optional',()=>{
 const axis=[-.1,0,.1],col=z=>({z,x:axis,y:axis,xz:[0,1,0],yz:[0,1,0]}),r={columns:[col(0),col(1)],geometry:{mask:.5},zMin:0,zMax:1,sharedPeak:1},palette=t=>[7+200*t,22,36];
 assert.deepEqual([...renderWavePixels(r,{width:20,height:20,half:1,palette}).slice(0,4)],[7,22,36,255]);
 assert.deepEqual([...renderWavePixels(r,{width:20,height:20,half:1,palette,showWindow:true}).slice(0,4)],[223,230,237,255]);
});
