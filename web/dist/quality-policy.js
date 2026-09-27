import {sliceKey} from './observation-state.js?v=20260927-detail1';
import {QUALITY} from './quality.js?v=20260927-positions3';
export function sameSlice(result,params,z){
  return !!result&&sliceKey({...result.params,gridSize:params.gridSize,sourceBins:params.sourceBins},result.z)===sliceKey(params,z);
}
export function sufficientSlice(result,params,z){return sameSlice(result,params,z)&&result.params.gridSize>=params.gridSize&&result.params.sourceBins>=params.sourceBins;}
export function bestSlice(results,params,z){return results.filter(r=>sufficientSlice(r,params,z)).sort((a,b)=>b.params.gridSize-a.params.gridSize||b.params.sourceBins-a.params.sourceBins)[0];}
export class DetailPreferences{
  constructor(){this.standard=false;this.expert=true;}
  get(compact,keyView){return compact&&!keyView?this.standard:this.expert;}
  set(compact,keyView,value){this[compact&&!keyView?'standard':'expert']=value;}
  quality(compact,keyView){return this.get(compact,keyView)?QUALITY.fine:QUALITY.standard;}
}
