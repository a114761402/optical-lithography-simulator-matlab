import test from 'node:test';
import assert from 'node:assert/strict';
import {defaults,geometry} from '../dist/optics.js';
import {waveComponentLayout,waveComponentSVG} from '../dist/wave-components.js';
const result=(params={...defaults})=>({params,geometry:geometry(params),zMin:0,zMax:geometry(params).max,scope:'full'});

test('Overlay follows the displayed physical geometry at phone and desktop widths without mutating it',()=>{
  for(const height of [160,240])for(const width of [280,366,430,844,1280])for(const changes of [{},{condenserFocalMm:180,f1Mm:50,reduction:8},{condenserFocalMm:50,f1Mm:180,reduction:1}]){
    const r=result({...defaults,...changes}),before=structuredClone(r),items=waveComponentLayout(r,width,height);
    assert.equal(items.length,7);
    for(const e of items){assert.ok(Math.abs(e.x/width-r.geometry[e.key]/r.zMax)<1e-12);assert.equal(e.y,height/2);assert.ok(e.x>=0&&e.x<=width);assert.ok(e.halfWidth>0);assert.ok(e.labelY-11>e.y+e.halfHeight*Math.min(1,height/240));assert.ok(e.labelY<height-15);}
    for(let i=1;i<items.length;i++)assert.ok(items[i-1].x+items[i-1].halfWidth<items[i].x-items[i].halfWidth);
    assert.deepEqual(r,before);assert.doesNotMatch(waveComponentSVG(r,width,height),/NaN|Infinity/);
  }
});

test('Near-mask overlay only includes the mask at the actual left edge, using the result window',()=>{
  const r=result();r.zMin=r.geometry.mask;r.zMax=r.zMin+.2;r.scope='near';
  const items=waveComponentLayout(r,320,240);assert.equal(items.length,1);assert.equal(items[0].key,'mask');assert.equal(items[0].x,0);
  assert.deepEqual(waveComponentLayout({...r,zMax:r.zMin},320,240),[]);
});

test('Sparse labels avoid the coordinate labels; annular aperture keeps its obstruction; Image is a fixed symbol',()=>{
  const r=result({...defaults,lensType:'Annular',lensInner:.65}),items=waveComponentLayout(r,320,240),svg=waveComponentSVG(r,320,240);
  assert.deepEqual(items.filter(e=>e.label).map(e=>e.key),['source','mask','image']);
  assert.ok(items.every(e=>e.labelY<=202));assert.match(svg,/image-reference/);assert.match(svg,/Aperture · z = 400 mm/);
  assert.notEqual(svg,waveComponentSVG(result({...defaults,lensType:'Circular'}),320,240));
});
