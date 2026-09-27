import test from 'node:test';
import assert from 'node:assert/strict';
import {defaults,geometry} from '../dist/optics.js';
import {computeScreen} from '../dist/views.js';
import {createPlanes,observationZ,setObservation,tuneObservation,snapPosition,sliceKey,sliceRequest,acceptsSlice,referenceScreens,screenSnapshot,SliceCache} from '../dist/observation-state.js';
import {SerialJobs} from '../dist/serial-jobs.js';
import {palette,lightRegion} from '../dist/light-palette.js';
import {renderWavePixels} from '../dist/wave-display.js';
const p={...defaults,sourceType:'Point',gridSize:128,sourceBins:1},g=geometry(p);
const near=(a,b)=>assert.ok(Math.abs(a-b)<1e-8,`${a} != ${b}`);

test('Fine tuning works at every named plane and a custom plane, while the image reference stays fixed',()=>{
 const panel=createPlanes()[3];
 for(const name of ['source','condenser','mask','lens1','pupil','lens2','image','custom']){
  const z=name==='custom'?237.42:g[name];setObservation(panel,g,z,name);tuneObservation(panel,g,5);near(observationZ(panel,g),z+.005);
  tuneObservation(panel,g,0);near(observationZ(panel,g),z);
 }
 assert.equal(geometry(p).image,g.image);assert.equal(p.defocusUm,0);
});
test('Fine tuning clamps at both ends, resets on coarse positioning and follows changed geometry',()=>{
 const panel=createPlanes()[0];tuneObservation(panel,g,-100);assert.equal(observationZ(panel,g),0);
 setObservation(panel,g,g.max);tuneObservation(panel,g,100);assert.equal(observationZ(panel,g),g.max);
 setObservation(panel,g,g.mask,'mask');tuneObservation(panel,g,-10);near(observationZ(panel,g),g.mask-.01);
 const next=geometry({...p,condenserFocalMm:120});near(observationZ(panel,next),next.mask-.01);
 setObservation(panel,g,233.123);assert.equal(panel.offset,0);near(observationZ(panel,g),233.123);
 assert.equal(setObservation(panel,g,NaN),false);assert.equal(tuneObservation(panel,g,Infinity),false);
});
test('Four independent targets route results by identity, position generation and optical/detail settings',()=>{
 const [a,b,c,d]=createPlanes(),request=sliceRequest(a,g,p);setObservation(b,g,210);tuneObservation(b,g,10);
 assert.ok(acceptsSlice(a,request,g,p));assert.ok(!acceptsSlice(b,request,g,p));
 assert.equal(observationZ(c,g),g.pupil);assert.equal(observationZ(d,g),g.image);
 assert.ok(!acceptsSlice(a,request,g,{...p,projNA:.12}));assert.ok(!acceptsSlice(a,request,g,{...p,gridSize:256}));
 setObservation(a,g,3);setObservation(a,g,0,'source');assert.ok(!acceptsSlice(a,request,g,p));
 assert.equal(sliceKey({...p,defocusUm:20},0),sliceKey(p,0));
});
test('Element snapping is pixel-based, sticky only inside release radius, and can be bypassed',()=>{
 const width=940,nearPupil=g.pupil+3;
 assert.equal(snapPosition(nearPupil,g,width).plane,'pupil');
 assert.equal(snapPosition(g.pupil+5,g,width,{previous:'pupil'}).plane,'pupil');
 assert.equal(snapPosition(g.pupil+7,g,width,{previous:'pupil'}).plane,'custom');
 assert.equal(snapPosition(nearPupil,g,width,{bypass:true}).z,nearPupil);
 for(const key of ['source','condenser','mask','lens1','pupil','lens2','image'])assert.equal(snapPosition(g[key],g,width).plane,key);
 assert.equal(snapPosition(-20,g,width).z,0);assert.equal(snapPosition(g.max+10,g,width).z,g.max);
});
test('Default comparison views reuse exactly the independently calculated XY intensities, axes and scales',()=>{
 const fixed=computeScreen(p,g.image),screens=referenceScreens(fixed);
 for(const r of screens){const direct=screenSnapshot(computeScreen(p,r.z));for(const key of ['screenRaw','screenAxis','screenAxisY','screenHalf','sharedPeak','label'])assert.deepEqual(r[key],direct[key],`${r.label}: ${key}`);}
});
test('Queue retains other views, replaces only the same view, ignores late completion and recovers from errors',()=>{
 const jobs=new SerialJobs(),events=[],finish={};
 const job=(key,label)=>({key,run(done){finish[label]=done;events.push('start '+label);return ()=>events.push('stop '+label);},finished(v){events.push(v);},failed(e){events.push(e.message);}});
 jobs.add(job('A','a1'));jobs.add(job('B','b1'));jobs.add(job('B','b2'));assert.deepEqual(events,['start a1']);
 finish.a1(null,'A ready');assert.ok(events.includes('start b2'));assert.ok(!events.includes('start b1'));
 jobs.add(job('B','b3'));finish.b2(null,'obsolete');assert.ok(!events.includes('obsolete'));
 finish.b3(Error('failed'));jobs.add(job('D','d'));finish.d(null,'D ready');assert.ok(events.includes('D ready'));assert.equal(jobs.current,null);
});
test('Slice cache has a bounded least-recently-used lifetime',()=>{
 const cache=new SliceCache(2);cache.set('A',{});cache.set('B',{});cache.get('A');cache.set('C',{});assert.equal(cache.get('B'),undefined);assert.ok(cache.get('A'));cache.clear();assert.equal(cache.get('A'),undefined);
});
test('Yellow/blue palette switches exactly at mask without changing wave data or brightness values',()=>{
 const columns=[0,200,470].map(z=>({z,x:[-1,1],y:[-1,1],xz:[1,1],yz:[1,1]}));
 const r={columns,geometry:g,zMin:0,zMax:470,sharedPeak:1},before=structuredClone(r);
 const pixels=renderWavePixels(r,{width:470,height:1,half:1,palette:t=>palette(t,'blue'),illuminationPalette:t=>palette(t,'warm')});
 assert.deepEqual([...pixels.slice(199*4,199*4+3)],palette(1,'warm'));assert.deepEqual([...pixels.slice(200*4,200*4+3)],palette(1,'blue'));assert.deepEqual(r,before);
 assert.equal(lightRegion(g.mask-.0005,g),'warm');assert.equal(lightRegion(g.mask,g),'blue');
 for(const kind of ['warm','blue']){let prior=0;for(let i=0;i<=100;i++){const [r,g,b]=palette(i/100,kind),l=.2126*r+.7152*g+.0722*b;assert.ok(l>=prior);prior=l;}}
});
