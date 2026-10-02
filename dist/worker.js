import {enhanceWave} from './dense-wave.js?v=20260927-positions3';
import {computeViews,computeScreen} from './views.js?v=20260927-positions3';
import {computeWave} from './wave.js?v=20260927-positions3';
import {computeTransmittedWave} from './transmitted-wave.js?v=20261002-transmitted2';
self.onmessage=({data})=>{try{const start=performance.now();let last=0;const progress=value=>{if(performance.now()-last>90||value===1){self.postMessage({type:'progress',value});last=performance.now();}};const result=data.type==='yz'?enhanceWave((data.transmittedOnly?computeTransmittedWave:computeWave)(data.params,data.scope,progress)):data.type==='screen'?computeScreen(data.params,data.z,progress):computeViews(data.params,data.z,progress);self.postMessage({type:'result',kind:data.type,result,elapsed:performance.now()-start});}catch(error){self.postMessage({type:'error',message:error.message});}};
