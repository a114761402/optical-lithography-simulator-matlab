import test from 'node:test';
import assert from 'node:assert/strict';
import {defaults,geometry} from '../dist/optics.js';
import {createPlanes,createPlane,restorePlane,availablePlaneId,SliceBatch,sliceRequest,acceptsSlice,setObservation,SliceCache} from '../dist/observation-state.js';
import {SerialJobs} from '../dist/serial-jobs.js';
import {fileShareAvailable,shareSliceFile} from '../dist/slice-share.js';
const g=geometry(defaults);
test('Deleting and reusing a letter cannot accept the old calculation, including after Undo',()=>{
 const old=createPlane('B','custom',202),request=sliceRequest(old,g,defaults),replacement=createPlane('B','custom',202),restored=restorePlane(old);
 assert.equal(acceptsSlice(replacement,request,g,defaults),false);assert.equal(acceptsSlice(restored,request,g,defaults),false);assert.equal(acceptsSlice(null,request,g,defaults),false);
 assert.equal(restored.base,202);assert.equal(restored.pending,false);
});
test('Deleting any combination retains stable letters and permits empty/add state',()=>{
 const planes=createPlanes();assert.equal(availablePlaneId(planes),undefined);planes.splice(1,1);assert.deepEqual(planes.map(p=>p.id),['A','C','D']);assert.equal(availablePlaneId(planes),'B');planes.length=0;assert.equal(availablePlaneId(planes),'A');
});
test('Batch tracks all retained views; cancellations, failures and deletion cannot keep it busy',()=>{
 const planes=createPlanes(),batch=new SliceBatch(planes);assert.equal(batch.remaining,4);batch.settle(planes[0].instance);batch.settle(planes[1].instance,'error');batch.drop(planes[2].instance);batch.settle(planes[2].instance);assert.equal(batch.total,3);assert.equal(batch.completed,2);assert.equal(batch.active,true);batch.settle(planes[3].instance,'cancelled');assert.equal(batch.active,false);
});
test('Queued same-position views reuse a result computed earlier in the batch',()=>{
 const queue=new SerialJobs(),cache=new SliceCache(),planes=[createPlane('A','custom',205),createPlane('B','custom',205)],batch=new SliceBatch(planes);let work=0,complete;const results=[];
 for(const panel of planes){const r=sliceRequest(panel,g,defaults);queue.add({key:panel.id,run(done){if(cache.get(r.key)){done(null,cache.get(r.key));return;}work++;complete=()=>done(null,{value:42});},finished(result){cache.set(r.key,result);results.push(result);batch.settle(panel.instance);}});}
 complete();assert.equal(work,1);assert.equal(results.length,2);assert.equal(batch.active,false);assert.equal(queue.current,null);
});
test('Removing an in-flight view rejects late completion and other queued views continue',()=>{
 const q=new SerialJobs(),panels=createPlanes(),batch=new SliceBatch(panels.slice(0,2));let late,next;const results=[];
 q.add({key:'A',run(done){late=done;},cancelled(){batch.settle(panels[0].instance,'cancelled');},finished(){results.push('old');}});
 q.add({key:'B',run(done){next=done;},finished(){results.push('B');batch.settle(panels[1].instance);}});
 batch.drop(panels[0].instance);q.cancel('A');late(null,{});next(null,{});assert.deepEqual(results,['B']);assert.equal(batch.active,false);
});
test('Moving one target invalidates its result but not an independent view',()=>{
 const [a,b]=createPlanes(),ra=sliceRequest(a,g,defaults),rb=sliceRequest(b,g,defaults);setObservation(a,g,12);assert.equal(acceptsSlice(a,ra,g,defaults),false);assert.equal(acceptsSlice(b,rb,g,defaults),true);
});
test('Sharing checks actual PNG support, retains the file and distinguishes cancellation',async()=>{
 const file=new File(['png'],'slice.png',{type:'image/png'});let shared;
 const supported={canShare:({files})=>files[0]===file,share:async data=>{shared=data;}};
 assert.equal(fileShareAvailable(file,supported),true);assert.equal(await shareSliceFile(file,supported),'shared');assert.equal(shared.files[0],file);
 assert.equal(await shareSliceFile(file,{}),'unsupported');assert.equal(fileShareAvailable(file,{share(){},canShare(){throw Error();}}),false);
 assert.equal(await shareSliceFile(file,{...supported,share:async()=>{throw new DOMException('cancel','AbortError');}}),'cancelled');
 await assert.rejects(shareSliceFile(file,{...supported,share:async()=>{throw new Error('blocked');}}),/blocked/);
});
