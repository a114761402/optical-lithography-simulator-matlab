import {createPlanes,restorePlane,observationZ,sliceKey} from './observation-state.js?v=20260927-positions3';

// New identities prevent in-flight work for the replaced layout from attaching.
export function restorePositions(saved=null){return saved?saved.map(restorePlane):createPlanes();}
export function hydratePositions(planes,geometry,params,cache,revision){
  for(const panel of planes){
    const key=sliceKey(params,observationZ(panel,geometry)),result=cache.get(key);
    if(result){panel.result=result;panel.resultKey=key;panel.resultRevision=revision;panel.error='';}
  }
}
export function atReferencePositions(planes){
  return planes.length===4&&['source','mask','pupil','image'].every((plane,i)=>planes[i].id==='ABCD'[i]&&planes[i].plane===plane&&planes[i].offset===0);
}
export function referenceDisplayMode(panel,choices,current=true){
  if(!panel||!current||panel.offset!==0)return 'intensity';
  if(panel.plane==='source'&&choices.source==='weights')return 'weights';
  if(panel.plane==='mask'&&choices.mask==='amplitude')return 'mask-opening';
  if(panel.plane==='pupil'&&choices.pupil==='opening')return 'aperture-opening';
  return 'intensity';
}
