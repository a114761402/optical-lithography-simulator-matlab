import {parentPort,workerData} from 'node:worker_threads';
import {compute} from '../../dist/optics.js';
import {enhancePupil} from '../../dist/dense-pupil.js';
import {centerCuts} from '../../dist/wave.js';

// Recompute the full 2D field independently of the cache generator's cut optimization.
const result=enhancePupil(compute(workerData.params,workerData.z));
parentPort.postMessage({cuts:centerCuts(result.screenRaw,result.screenAxis,result.screenAxisY),x:result.screenAxis,y:result.screenAxisY,sharedPeak:result.sharedPeak});
