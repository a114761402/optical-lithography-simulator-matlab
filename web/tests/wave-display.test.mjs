import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createWaveSampler,renderWavePixels} from '../dist/wave-display.js';
import {waveView} from '../dist/path-layout.js';
import {brightness} from '../dist/wave.js';
import {projectionDisplayHalf,waveComponentLayout} from '../dist/wave-components.js';

const column=(z,half,fn,n=5)=>{const x=Array.from({length:n},(_,i)=>-half+2*half*i/(n-1));return {z,x,y:x,xz:x.map(v=>fn(v,z)),yz:x.map(v=>fn(v,z)*2)};};
const result=columns=>({columns,geometry:{},zMin:columns[0].z,zMax:columns.at(-1).z,sharedPeak:100});
const near=(a,b)=>assert.ok(Math.abs(a-b)<=1e-10*Math.max(1,Math.abs(b)),`${a} != ${b}`);

test('Interpolated mesh follows physical coordinates and smoothly changing window bounds',()=>{
 const r=result([column(0,1,(y,z)=>5+2*y+3*z,3),column(4,3,(y,z)=>5+2*y+3*z,7)]),before=structuredClone(r);
 const frame=createWaveSampler(r)(2);assert.equal(frame.lower,-2);assert.equal(frame.upper,2);
 for(const y of [-.75,0,.75])near(frame.sample(y),5+2*y+6);
 near(frame.reference,13);assert.equal(frame.sample(2.01),null);assert.deepEqual(r,before);
});

test('Exact calculated planes retain both raw cuts and their original peak',()=>{
 const r=JSON.parse(readFileSync(new URL('../dist/data/default-wave-circular-fine-v4.json',import.meta.url))).result;
 for(const section of ['xz','yz']){
  const sample=createWaveSampler(r,section);
  for(const col of r.columns){const frame=sample(col.z),axis=col[section==='xz'?'x':'y'];
   for(const i of [0,Math.floor(axis.length/3),Math.floor(axis.length/2),axis.length-1])near(frame.sample(axis[i]),col[section][i]);
   near(frame.reference,Math.max(...col[section]));
  }
 }
});

test('A thin optical component is not blended into the preceding free-space interval',()=>{
 const r=result([column(0,1,()=>1),column(9,1,()=>1),column(10,.25,()=>0),column(11,.25,()=>0)]);r.geometry.mask=10;
 const sample=createWaveSampler(r);assert.equal(sample(9.999).sample(0),1);assert.equal(sample(9.999).upper,1);
 assert.equal(sample(10).sample(0),0);assert.equal(sample(10).upper,.25);
});

test('Interpolation stays bounded; local normalization uses the peak of the blended profile',()=>{
 const a=column(0,1,()=>0,3),b=column(2,2,()=>0,5);a.xz=[1,0,0];b.xz=[0,0,0,0,1];
 const frame=createWaveSampler(result([a,b]))(1);near(frame.reference,.5);
 for(let i=0;i<=100;i++){const value=frame.sample(-1.5+3*i/100);assert.ok(value>=0&&value<=.5);}
});

test('Shared linear/log displays interpolate raw intensity before colour mapping',()=>{
 const r=result([column(0,1,()=>1),column(2,1,()=>100)]),frame=createWaveSampler(r,'xz','shared-log')(1);
 assert.equal(frame.sample(0),50.5);assert.equal(frame.reference,100);
 near(brightness(frame.sample(0),frame.reference,'shared-log'),(10*Math.log10(.505)+120)/120);
});

test('Fractional pixel coverage smooths the computational edge and keeps outside pixels grey',()=>{
 const r=result([column(0,.2,()=>1),column(2,.8,()=>1)]),pixels=renderWavePixels(r,{width:32,height:32,half:1,palette:t=>[255*t,0,0],showWindow:true});
 assert.equal(pixels.length,32*32*4);assert.deepEqual(Array.from(pixels.slice(0,4)),[223,230,237,255]);
 let antialiased=0;for(let i=0;i<pixels.length;i+=4){assert.equal(pixels[i+3],255);if(pixels[i+1]>0&&pixels[i+1]<230)antialiased++;}
 assert.ok(antialiased>32,'Expected fractional boundary pixels rather than binary staircase edges');
});

test('Dark fields, one saved plane, and unsupported positions remain well-defined',()=>{
 const r=result([column(0,1,()=>0)]),sample=createWaveSampler(r);
 assert.equal(sample(-1),null);assert.equal(sample(1),null);assert.equal(sample(0).reference,0);
 const pixels=renderWavePixels(r,{width:4,height:4,half:1,palette:t=>[t*255,t*255,t*255]});
 for(let i=0;i<pixels.length;i+=4)assert.deepEqual(Array.from(pixels.slice(i,i+4)),[0,0,0,255]);
});

test('Cropping at Image uses the same physical samples and does not paint downstream light',()=>{
 const r=result([column(0,1,()=>1),column(2,1,()=>1),column(4,1,()=>9)]);r.geometry={source:0,image:2,mask:2};r.scope='full';
 const options={width:40,height:8,half:1,mode:'shared',palette:t=>[255*t,0,0]};
 const before=structuredClone(r),full=renderWavePixels(r,options),cropped=renderWavePixels(waveView(r),{...options,width:20});
 for(let y=0;y<8;y++)assert.deepEqual(cropped.slice(y*80,(y+1)*80),full.slice(y*160,y*160+80));
 assert.deepEqual(r,before);
});

test('Projection display crop preserves illumination, retained intensities and raw fields in both sections',()=>{
 const r=result([0,1,2,3,4].map(z=>column(z,1,()=>25)));
 r.geometry={source:0,mask:1,lens1:2,pupil:2.5,lens2:3,image:4};
 r.params={fieldSizeUm:200000,reduction:4};r.scope='full';
 const before=structuredClone(r),options={width:80,height:240,half:1,mode:'shared',palette:t=>[255*t,0,0],illuminationPalette:t=>[0,255*t,0]};
 for(const section of ['xz','yz']){
  const full=renderWavePixels(r,{...options,section}),cropped=renderWavePixels(r,{...options,section,projectionCrop:true});
  for(let y=0;y<240;y++)for(let x=0;x<20;x++){
   const k=(y*80+x)*4;assert.deepEqual(cropped.slice(k,k+4),full.slice(k,k+4));
  }
  const inside=(120*80+40)*4,outside=(20*80+40)*4;
  assert.deepEqual(cropped.slice(inside,inside+4),full.slice(inside,inside+4));
  assert.ok(full[outside]>0);assert.deepEqual(Array.from(cropped.slice(outside,outside+4)),[0,0,0,255]);
 }
 assert.deepEqual(r,before);
 r.scope='near';assert.deepEqual(renderWavePixels(r,{...options,projectionCrop:true}),renderWavePixels(r,options));
});

test('Projection crop aligns to illustrated lens outlines at different display heights',()=>{
 const r={geometry:{source:0,condenser:1,mask:2,lens1:3,pupil:4,lens2:5,image:6},params:{fieldSizeUm:80,reduction:4},scope:'full',zMin:0,zMax:6};
 for(const height of [104,128,240,300])for(const key of ['lens1','lens2']){
  const item=waveComponentLayout(r,800,height).find(item=>item.key===key);
  near(projectionDisplayHalf(r,r.geometry[key],1,height),item.halfHeight*Math.min(1,height/240)*2/height);
 }
 assert.equal(projectionDisplayHalf(r,1,1,240),Infinity);
 near(projectionDisplayHalf(r,2,1,240),40e-6);
 near(projectionDisplayHalf(r,6,1,240),10e-6);
});
