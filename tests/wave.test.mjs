import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {defaults,compute,geometry,maximum} from '../dist/optics.js';
import {centerCuts,brightness,computeWave,pathPlanes,sampleLine} from '../dist/wave.js';
const relative=(a,b)=>Math.sqrt(a.reduce((s,v,i)=>s+(v-b[i])**2,0)/Math.max(b.reduce((s,v)=>s+v*v,0),Number.MIN_VALUE));
test('Physical centre cuts interpolate x=0 and y=0 on distinct offset axes',()=>{
 const x=Float64Array.from([-2,1,4]),y=Float64Array.from([-3,-1,1]),raw=Float64Array.from(Array.from(y,yy=>Array.from(x,xx=>10+2*xx+3*yy)).flat());const c=centerCuts(raw,x,y);
 assert.deepEqual(Array.from(c.xz),[6,12,18]);assert.deepEqual(Array.from(c.yz),[1,7,13]);
 assert.deepEqual(Array.from(centerCuts(new Float64Array(9).fill(9),x,Float64Array.from([1,2,3])).xz),[0,0,0]);
});
test('Linear and decibel scales preserve ratios, floors, clipping, and darkness',()=>{
 assert.equal(brightness(1,10,'shared'),.1);assert.equal(brightness(1e-6,1,'shared-log'),.5);assert.equal(brightness(0,1,'shared-log'),0);assert.equal(brightness(0,0,'log'),0);assert.equal(brightness(2,1,'log'),1);
});
test('XYZ reference stays fixed while the observation screen moves',()=>{
 const p={...defaults,sourceType:'Point',gridSize:128,defocusUm:8},zs=[0,200,200.1,400,450.008];const peaks=zs.map(z=>compute(p,z).sharedPeak);for(const value of peaks)assert.equal(value,peaks[0]);
});
test('Near-mask path includes 61 physical planes from 0 to 200 micrometres',()=>{
 const zs=pathPlanes(defaults,'near'),g=geometry(defaults);assert.equal(zs.length,61);assert.equal(zs[0],g.mask);assert.ok(Math.abs(zs.at(-1)-g.mask-.2)<1e-12);
 for(const z of [g.condenser,g.mask,g.lens1,g.pupil,g.lens2,g.image])assert.ok(pathPlanes(defaults).includes(z));
});
test('Wave results use the requested grid and agree with corresponding XY centre cuts',()=>{
 const p={...defaults,gridSize:128,sourceBins:5,sourceType:'Point'},zs=[200.001,350,400,410,450];const w=computeWave(p,'full',()=>{},zs);assert.equal(w.params.gridSize,128);for(const col of w.columns){const r=compute(p,col.z),cut=centerCuts(r.screenRaw,r.screenAxis,r.screenAxisY);assert.ok(relative(col.xz,cut.xz)<1e-12);assert.ok(relative(col.yz,cut.yz)<1e-12);}
});
test('Closed condenser and empty custom source yield zero wave fields',()=>{
 for(const extra of [{condenserAperture:0},{sourceType:'Freeform',customSource:Array(1024).fill(0)}]){const w=computeWave({...defaults,sourceType:'Point',gridSize:128,...extra},'near',()=>{},[200,200.05]);for(const col of w.columns){assert.equal(maximum(col.xz),0);assert.equal(maximum(col.yz),0);}}
});
const fixtures=JSON.parse(readFileSync(new URL('./matlab-wave-reference.json',import.meta.url),'utf8'));
for(const c of fixtures)test(`MATLAB XZ/YZ parity: ${c.name}`,()=>{
 const p={...defaults,...c.params,f1Mm:c.params.projectionFocalMm/2,sourceBins:Math.ceil(Math.sqrt(c.params.maxSourceSamples))},w=computeWave(p,'full',()=>{},c.columns.map(col=>col.z));let worst=0;
 for(let i=0;i<c.columns.length;i++){const actual=w.columns[i],expected=c.columns[i];for(const key of ['x','y'])assert.ok(relative(actual[key],expected[key])<1e-9,`${key} axis at ${actual.z}`);for(const key of ['xz','yz']){const err=relative(actual[key],expected[key]);worst=Math.max(worst,err);assert.ok(err<1e-6,`${key} at ${actual.z}, error ${err}`);}}
 assert.ok(Math.abs(w.sharedPeak/c.sharedPeak-1)<1e-6,`XYZ reference ${w.sharedPeak/c.sharedPeak}`);console.log(`${c.name}: worst relative cut error ${worst}`);
});

test('Point grating image converges as spatial grid doubles',()=>{
 const rs=[128,256,512].map(gridSize=>compute({...defaults,sourceType:'Point',gridSize}));let previous=Infinity;
 for(let i=0;i<2;i++){const a=rs[i],b=rs[i+1],ca=centerCuts(a.screenRaw,a.screenAxis).xz,cb=centerCuts(b.screenRaw,b.screenAxis).xz;const expected=Float64Array.from(a.screenAxis,x=>sampleLine(b.screenAxis,cb,x)),error=relative(ca,expected);assert.ok(error<.003,`Centreline error ${error}`);assert.ok(error<previous/2);previous=error;const energy=r=>r.screenRaw.reduce((a,b)=>a+b,0)*(r.screenAxis[1]-r.screenAxis[0])**2;assert.ok(Math.abs(energy(a)/energy(b)-1)<.003);}
});
test('Invalid numbers, grids, pattern values and clipped masks fail clearly',()=>{
 for(const params of [{gridSize:300},{sourceBins:0},{projNA:NaN},{defocusUm:Infinity},{fieldSizeUm:0},{condenserAperture:-1},{gratingDuty:1},{customPupil:[1,2,0,1]},{maskSizeUm:61,fieldSizeUm:80}])assert.throws(()=>compute({...defaults,...params}));
});
