import test from 'node:test';
import assert from 'node:assert/strict';
import {comparisonScale,centeredHalf,scaleBar} from '../dist/slice-comparison.js';
import {presetParams} from '../dist/presets.js';
import {slicePlan,illuminationIntensity,maximum} from '../dist/optics.js';
import {sampleIntensity} from '../dist/image-sampling.js';

function illumination(z){const p=presetParams('default'),plan=slicePlan(p,z);return {z,screenAxis:plan.axis,screenAxisY:plan.axisY,screenRaw:illuminationIntensity(p,plan.beam,plan.axis,plan.axisY)};}
test('Reported illumination positions show widening and weakening on common display scales without changing raw arrays',()=>{
 const results=[.049,40.355,61.593,87.073].map(illumination),before=results.map(r=>r.screenRaw.slice()),common=results.map(r=>comparisonScale(r,results));
 assert.ok(common.every(s=>s.half===common[0].half&&s.peak===common[0].peak));
 const widths=results.slice(1).map(r=>{const n=r.screenAxis.length,center=Math.floor(n/2),peak=maximum(r.screenRaw),cut=r.screenRaw.subarray(center*n,(center+1)*n);let lo=0,hi=n-1;while(cut[lo]<peak*.5)lo++;while(cut[hi]<peak*.5)hi--;return (r.screenAxis[hi]-r.screenAxis[lo])/(2*common[0].half);});
 assert.ok(widths[0]<widths[1]&&widths[1]<widths[2]);
 assert.ok(maximum(results[1].screenRaw)>maximum(results[2].screenRaw)&&maximum(results[2].screenRaw)>maximum(results[3].screenRaw));
 results.forEach((r,i)=>assert.deepEqual(r.screenRaw,before[i]));
});
test('Turning comparisons off restores original framing; non-peer or stale results retain their own frame',()=>{
 const a={screenAxis:[-1,0,1],screenRaw:[0,8,0],screenHalf:.75},b={screenAxis:[-3,0,3],screenRaw:[0,2,0]};
 assert.deepEqual(comparisonScale(a,[a,b],{size:false,intensity:false}),{half:.75,peak:null,sharedSize:false,sharedIntensity:false});
 assert.equal(comparisonScale(a,[b]).half,.75);
 assert.equal(comparisonScale(a,[a]).peak,null);
 assert.equal(comparisonScale(a,[a,b],{size:false,intensity:true}).peak,8);
});
test('Common view includes both axes of off-axis sources without recentering the source',()=>{
 const a={screenAxis:[1,2,3],screenAxisY:[-6,-5,-4],screenRaw:[0,0,0,0,1,0,0,0,0]},b={screenAxis:[-1,0,1],screenRaw:[0,0,0,0,1,0,0,0,0]};
 assert.equal(centeredHalf(a),6);assert.equal(comparisonScale(a,[a,b]).half,6);
 assert.equal(sampleIntensity(a.screenRaw,3,(2-a.screenAxis[0]),(-5-a.screenAxisY[0])),1);
 assert.equal(sampleIntensity(a.screenRaw,3,-a.screenAxis[0],-a.screenAxisY[0]),0);
});
test('Scale bars represent physical lengths from micrometres to millimetres',()=>{
 for(const width of [20e-6,80e-6,.00245,.028552]){const bar=scaleBar(width);assert.ok(bar.fraction>.09&&bar.fraction<=.24+1e-12);assert.equal(bar.fraction*width,bar.length);}
 assert.equal(scaleBar(.028552).label,'5 mm');assert.equal(scaleBar(20e-6).label,'2 µm');assert.equal(scaleBar(0),null);
});

test('Fixed physical framing ignores changing peer extents and leaves brightness independent',()=>{
 const r={screenAxis:new Float64Array([-.001,.001]),screenHalf:.001,screenRaw:new Float64Array([1,2])};
 const s={screenAxis:new Float64Array([-.1,.1]),screenHalf:.1,screenRaw:new Float64Array([3,4])};
 const result=comparisonScale(r,[r,s],{fixedWidth:.04,size:true,intensity:false});
 assert.equal(result.half,.02);assert.equal(result.peak,null);assert.equal(comparisonScale(r,[],{fixedWidth:.04}).half,.02);
 assert.equal(r.screenHalf,.001);assert.deepEqual([...r.screenRaw],[1,2]);
});
