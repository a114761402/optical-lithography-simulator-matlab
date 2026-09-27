import test from 'node:test';
import assert from 'node:assert/strict';
import {defaults,geometry,pupilValue} from '../dist/optics.js';
import {compactBench} from '../dist/compact-bench.js';
const components=[['source','Source'],['condenser','Condenser'],['mask','Mask'],['lens1','Lens 1'],['pupil','Pupil'],['lens2','Lens 2'],['image','Image']];
const near=(a,b)=>assert.ok(Math.abs(a-b)<1e-9,`${a} != ${b}`);

test('The whole compact bench fits narrow screens and preserves physical z ratios at geometry extremes',()=>{
  for(const width of [270,320,390,640])for(const changes of [{},{condenserFocalMm:180,f1Mm:50,reduction:8},{condenserFocalMm:50,f1Mm:180,reduction:1}]){
    const params={...defaults,...changes},before=structuredClone(params),g=geometry(params);
    const {svg,height}=compactBench({width,geometry:g,params,components,selected:'pupil',screen:g.image,pupilValue});
    assert.equal(height,164);assert.ok(!/NaN|Infinity/.test(svg));
    const locations=[...svg.matchAll(/data-component="([^"]+)"[^>]+transform="translate\(([^,]+),79\)"/g)];
    assert.equal(locations.length,7);
    for(const [,key,x]of locations){near((Number(x)-18)/(width-36),g[key]/g.max);assert.ok(Number(x)>=18&&Number(x)<=width-18);}
    assert.deepEqual(params,before);
  }
});

test('Selected components retain names and state; reference labels stay legible without a dense label row',()=>{
  const params={...defaults},g=geometry(params);
  const {svg}=compactBench({width:285,geometry:g,params,components,selected:'lens2',screen:g.mask,pupilValue});
  assert.match(svg,/data-component="lens2" aria-label="Select Lens 2" aria-pressed="true"/);
  for(const [,name]of components)assert.ok(svg.includes(`aria-label="Select ${name}"`));
  for(const name of ['Source','Mask','Image'])assert.match(svg,new RegExp(`<text[^>]+>${name}</text>`));
  assert.match(svg,/Observation screen · z = 200 mm/);
});

test('Compact rendering honors desktop ray controls, with more rays available without changing optics',()=>{
  const params={...defaults},g=geometry(params),draw=mode=>compactBench({width:450,geometry:g,params,components,selected:'pupil',screen:g.image,pupilValue,mode}).svg;
  const rays=svg=>(svg.match(/<polyline/g)||[]).length;
  assert.equal(rays(draw('none')),0);assert.ok(rays(draw('principal'))>0);assert.ok(rays(draw('many'))>rays(draw('principal')));
});
