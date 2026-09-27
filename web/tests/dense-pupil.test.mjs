import test from 'node:test';
import assert from 'node:assert/strict';
import {defaults,compute,maximum} from '../dist/optics.js';
import {densePupil} from '../dist/dense-pupil.js';
import {sampleIntensity} from '../dist/image-sampling.js';
test('Dense pupil matches a padded FFT at matched physical coordinates',()=>{
  // Pick ROI spacing exactly equal to the independently padded FFT spacing.
  const p={...defaults,sourceType:'Point',gridSize:128,sourceBins:1,propagationPadding:8,projNA:.15};
  const fft=compute(p),step=fft.pupilAxis[1]-fft.pupilAxis[0],radius=fft.geometry.f2*.001*p.projNA;
  const size=145,q={...p,projNA:(size-1)*step/2/(1.1*fft.geometry.f2*.001)};
  const direct=densePupil(q,{size}),ref=compute(q),peak=maximum(ref.pupilRaw);let error=0;
  for(let y=0;y<size;y++)for(let x=0;x<size;x++){
    const ix=Math.round((direct.screenAxis[x]-ref.pupilAxis[0])/step),iy=Math.round((direct.screenAxis[y]-ref.pupilAxis[0])/step);
    error=Math.max(error,Math.abs(direct.screenRaw[y*size+x]-ref.pupilRaw[iy*ref.pupilAxis.length+ix])/peak);
  }
  assert.ok(error<1e-8,`relative intensity error ${error}`);
});
test('Display interpolation is nonnegative, bounded, exact at samples, and leaves raw data unchanged',()=>{
  const a=new Float64Array([0,2,4,6]),before=[...a];
  assert.equal(sampleIntensity(a,2,.5,.5),3);assert.equal(sampleIntensity(a,2,1,1),6);assert.equal(sampleIntensity(a,2,-.1,0),0);
  assert.equal(sampleIntensity(a,2,.2,.2,false),0);assert.deepEqual([...a],before);
});
import {densePupilCuts} from '../dist/dense-wave.js';
import {centerCuts} from '../dist/wave.js';
test('Fast dense wave cuts agree with the dense XY pupil, including off-axis illumination and blocked light',()=>{
  const p={...defaults,sourceType:'Dipole X',sourceOuter:.05,quadSeparation:.5,sourceBins:3,gridSize:128,lensType:'Annular',lensInner:.35};
  const xy=densePupil(p),cuts=centerCuts(xy.screenRaw,xy.screenAxis),fast=densePupilCuts(p);
  for(const k of ['xz','yz']){let err=0;const peak=maximum(cuts[k]);for(let i=0;i<cuts[k].length;i++)err=Math.max(err,Math.abs(cuts[k][i]-fast[k][i]));assert.ok(err/peak<1e-9);}
});
