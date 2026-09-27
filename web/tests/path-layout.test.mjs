import test from 'node:test';
import assert from 'node:assert/strict';
import {defaults,geometry,pupilValue} from '../dist/optics.js';
import {pathFrame,pathRegions,waveView} from '../dist/path-layout.js';
import {waveComponentLayout} from '../dist/wave-components.js';
import {desktopBench} from '../dist/desktop-bench.js';
const components=[['source','Source'],['condenser','Condenser'],['mask','Mask'],['lens1','Lens 1'],['pupil','Pupil'],['lens2','Lens 2'],['image','Image']];
const settings=[{},{condenserFocalMm:180,f1Mm:50,reduction:8},{condenserFocalMm:50,f1Mm:180,reduction:1}];
const close=(a,b)=>assert.ok(Math.abs(a-b)<1e-8,`${a} != ${b}`);
const render=(width,p,screen,mode='principal')=>desktopBench({width,geometry:geometry(p),params:p,components,selected:'pupil',screen,pupilValue,mode,defs:'',lensDiagram:()=>'<path/>',maskDiagram:()=>'<path/>',pictures:{source:'',pupil:''}});
test('Illumination ends at the mask and projection ends at the fixed image, including defocus and changed geometry',()=>{
  for(const changes of settings){const p={...defaults,...changes},g=geometry(p),regions=pathRegions(g);
    assert.equal(regions[0].start,0);assert.equal(regions[0].end,g.mask);assert.equal(regions[1].start,g.mask);assert.equal(regions[1].end,g.image);
    close(regions[0].left+regions[0].width,regions[1].left);
    assert.deepEqual(pathRegions(geometry({...p,defocusUm:50})),regions);
  }
});
test('Responsive desktop components use the same z mapping as the wave at all widths; inputs are unchanged',()=>{
  for(const width of [680,800,1100,1400])for(const changes of settings){const p={...defaults,...changes},g=geometry(p),before=structuredClone(p),frame=pathFrame(width,g.image),drawing=render(width,p,g.image);
    assert.equal(drawing.height,240);assert.doesNotMatch(drawing.svg,/NaN|Infinity/);
    const matches=[...drawing.svg.matchAll(/data-component="([^"]+)"[^>]+transform="translate\(([^,]+),120\)"/g)];assert.equal(matches.length,7);
    for(const [,key,x]of matches){close(+x,frame.left+g[key]/g.image*(frame.right-frame.left));assert.ok(+x>=7&&+x<=width-7);}
    const overlay=waveComponentLayout(waveView({geometry:g,scope:'full',zMin:0,zMax:g.max}),frame.right-frame.left,160);
    for(const item of overlay)close(frame.left+item.x,frame.x(item.z));
    assert.deepEqual(p,before);
  }
});
test('Moving the observation marker does not move fixed components; ray modes remain available',()=>{
  const p={...defaults},g=geometry(p),a=render(1000,p,g.image).svg,b=render(1000,p,g.mask).svg;
  const transforms=s=>[...s.matchAll(/data-component="[^"]+"[^>]+transform="([^"]+)"/g)].map(m=>m[1]);
  assert.deepEqual(transforms(a),transforms(b));assert.match(b,/Observation screen · z = 200 mm/);
  assert.equal((render(1000,p,g.image,'none').svg.match(/<polyline/g)||[]).length,0);
  assert.ok((render(1000,p,g.image,'many').svg.match(/<polyline/g)||[]).length>(a.match(/<polyline/g)||[]).length);
});

test('All position labels remain below the beam, including four coincident targets and no selection',()=>{
  const p={...defaults},g=geometry(p);
  for(const z of [0,200,g.image])for(const activeId of [null,'A','D']){
    const r=desktopBench({width:680,geometry:g,params:p,components,selected:'pupil',screen:activeId?z:null,pupilValue,mode:'none',defs:'',lensDiagram:()=>'',maskDiagram:()=>'',pictures:{source:'',pupil:''},observations:[...'ABCD'].map(id=>({id,z})),activeId});
    assert.doesNotMatch(r.svg,/F₁|F₂|NaN/);
    for(const id of 'ABCD')assert.match(r.svg,new RegExp('y="188"[^>]*>'+id+'</text>'));
    assert.equal((r.svg.match(/data-observation-screen/g)||[]).length,activeId?1:0);
  }
});

test('Image-ended display preserves raw propagation and near-mask bounds',()=>{
 const g=geometry(defaults),columns=[{z:0},{z:g.image},{z:g.max}],raw={geometry:g,scope:'full',zMin:0,zMax:g.max,columns};
 const view=waveView(raw);assert.equal(view.zMax,g.image);assert.equal(raw.zMax,g.max);assert.equal(view.columns,columns);
 const near={...raw,scope:'near',zMin:g.mask,zMax:g.mask+.2};assert.equal(waveView(near),near);
 const drawing=render(680,defaults,g.image+.01);assert.doesNotMatch(drawing.svg,/data-observation-screen/);
});
