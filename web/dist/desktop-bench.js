import {RAY_BLUE,RAY_YELLOW} from './light-palette.js?v=20260927-positions3';
import {pathFrame} from './path-layout.js?v=20260927-position-fit';
// Responsive drawing coordinates keep the physical z scale without stretching
// lenses when a wide monitor offers more horizontal space.
export function desktopBench({width,height=240,geometry:g,params:p,components,selected,screen,pupilValue,mode,defs,lensDiagram,maskDiagram,pictures,observations=[],activeId='D'}){
  const {left,right,x:X}=pathFrame(width,g.image),dense=height<240,C=dense?height-95:120,scale=dense?.38:.66,axis=dense?height-20:204,tickY=dense?height-2:226,markerY=dense?height-40:188,leader=dense?44:65,Y=y=>C-y*scale;
  let svg=defs+`<path d="M${left} ${C}H${right}" stroke="#c5d6e5" stroke-dasharray="5 6"/><path d="M${left} ${axis}H${right}" stroke="#bacbdc"/>`;
  const tickStep=g.image/(right-left)*80,step=tickStep<=50?50:tickStep<=100?100:200;
  for(let tick=0;tick<g.image-step*.35;tick+=step)svg+=`<path d="M${X(tick)} ${axis}v5" stroke="#a9bdcf"/><text x="${X(tick)}" y="${tickY}" text-anchor="${tick===0?'start':'middle'}" fill="#6e859b" font-size="12">${tick}</text>`;
  svg+=`<path d="M${right} ${axis}v5" stroke="#a9bdcf"/><text x="${right}" y="${tickY}" text-anchor="end" fill="#6e859b" font-size="12">${Number(g.image.toFixed(3))} mm</text>`;
  if(mode!=='none'){
    const colours=RAY_BLUE,objects=mode==='many'?[-32,-16,0,16,32]:[-28,0,28],angles=mode==='many'?[-43,-29,-15,0,15,29,43]:[-36,0,36];
    objects.forEach((h,k)=>{for(const a of angles){const blocked=pupilValue(p,0,a/48)===0,pts=[[g.mask,h],[g.lens1,h+a],[g.pupil,a],...(!blocked?[[g.lens2,a-h*g.f2/g.f1],[g.image,-h/p.reduction]]:[])];svg+=`<polyline points="${pts.map(([z,y])=>`${X(z)},${Y(y)}`).join(' ')}" fill="none" stroke="${colours[k%3]}" stroke-opacity="${mode==='many'?.36:.6}" stroke-width="1"/>`;}});
    for(const h of (p.sourceType==='Point'?[p.pointSourceV*65]:p.sourceType==='Annular'||p.sourceType==='Dipole Y'?[-23,23]:p.sourceType==='Dipole X'?[0]:[-23,0,23]))for(const a of mode==='many'?[-51,-26,0,26,51]:[-44,0,44])svg+=`<polyline points="${X(0)},${Y(h)} ${X(g.condenser)},${Y(a)} ${X(g.mask)},${Y(a-h)}" fill="none" stroke="${RAY_YELLOW}" stroke-width="1" opacity=".38"/>`;
  }
  const positions=components.map(([key])=>X(g[key])),labels=[...positions],labelGap=Math.min(80,(right-left)/6);
  for(let i=1;i<labels.length;i++)labels[i]=Math.max(labels[i],labels[i-1]+labelGap);
  labels[6]=Math.min(labels[6],right);
  for(let i=5;i>=0;i--)labels[i]=Math.min(labels[i],labels[i+1]-labelGap);
  components.forEach(([key,name],i)=>{
    const xx=positions[i],active=selected===key,gap=Math.min(i?xx-positions[i-1]:Infinity,i<6?positions[i+1]-xx:Infinity),sx=Math.min(.66,gap/45),hit=Math.min(18,gap*.44);
    let shape='';
    if(key==='source')shape=`<g transform="skewY(-12) scale(.48,1)"><rect x="-42" y="-44" width="84" height="88" rx="12" fill="#edf3f8" stroke="#7893a8" stroke-width="2"/><rect x="-36" y="-38" width="72" height="76" rx="8" fill="#20394b"/><image href="${pictures.source}" x="-34" y="-34" width="68" height="68"/></g>`;
    else if(key==='condenser')shape=lensDiagram(65,15);
    else if(key==='lens1'||key==='lens2')shape=lensDiagram(key==='lens1'?64:54,key==='lens1'?13:10);
    else if(key==='mask')shape=`<g transform="skewY(-9) scale(.29,1.1)">${maskDiagram()}</g>`;
    else if(key==='pupil'){const aperture=25;shape=`<path data-aperture-side class="aperture-blade" d="M0 -46V${-aperture}M0 ${aperture}V46" stroke="#283f53" stroke-width="4"/>${p.lensType==='Annular'?`<path class="aperture-blade" d="M0 ${-aperture*p.lensInner}V${aperture*p.lensInner}" stroke="#283f53" stroke-width="4"/>`:''}`;}
    else shape=`<g transform="skewY(18)"><rect x="-12" y="-32" width="26" height="64" fill="#ffffff" stroke="#8ba7c0" stroke-width="2"/>${pictures.image?`<image data-fixed-image-preview href="${pictures.image}" x="-10" y="-30" width="22" height="60" preserveAspectRatio="none"/>`:""}</g>`;
    svg+=`<g data-label="${key}" class="bench-label ${active?'selected':''}" style="cursor:pointer"><path d="M${xx} ${leader}V${leader-10}L${labels[i]} 41" fill="none" stroke="#c6d4e1"/><text class="component-index" x="${labels[i]}" y="14" text-anchor="${i===0?'start':i===6?'end':'middle'}">0${i+1}</text><text class="component-label" x="${labels[i]}" y="33" text-anchor="${i===0?'start':i===6?'end':'middle'}">${name}</text></g><g class="component ${active?'selected':''}" role="button" tabindex="0" data-component="${key}" aria-label="Select ${name}" aria-pressed="${active}" transform="translate(${xx},${C})"><rect class="selection" x="${-hit}" y="${dense?-41:-55}" width="${2*hit}" height="${dense?84:115}" rx="6" fill="#e3efff" stroke="#80b0ed" stroke-dasharray="3 4"/><g transform="scale(${sx},${scale})">${shape}<path d="M0 ${key==='image'?32:66}V90M-17 90h34" fill="none" stroke="#9badbc" stroke-width="2"/></g><rect x="${-hit}" y="${dense?-43:-57}" width="${2*hit}" height="${dense?88:117}" fill="transparent"/></g>`;
  });
  const positionsToDraw=(observations.length?observations:screen!==null?[{id:activeId,z:screen}]:[]).filter(o=>o.z>=0&&o.z<=g.image);
  for(const o of positionsToDraw.filter(o=>o.muted))svg+=`<path data-position-tick="${o.id}" d="M${X(o.z)} ${axis-7}v7" stroke="#b9c9d8"/>`;
  const ordered=positionsToDraw.filter(o=>!o.muted).map(o=>({...o,labelX:X(o.z)})).sort((a,b)=>a.z-b.z);
  for(let i=1;i<ordered.length;i++)ordered[i].labelX=Math.max(ordered[i].labelX,ordered[i-1].labelX+24);
  if(ordered.length){ordered.at(-1).labelX=Math.min(right,ordered.at(-1).labelX);for(let i=ordered.length-2;i>=0;i--)ordered[i].labelX=Math.min(ordered[i].labelX,ordered[i+1].labelX-24);}
  for(const observation of ordered){
    const xx=X(observation.z),active=observation.id===activeId,yy=markerY,offset=observation.labelX-xx;
    const marker=`<path d="M0 ${yy-21}L${offset} ${yy-15}" stroke="#9badbc" fill="none"/><g transform="translate(${offset},0)"><rect class="screen-knob" x="-10" y="${yy-15}" width="20" height="21" rx="3" fill="${active?'#155fdf':'#e6edf5'}"/><text x="0" y="${yy}" fill="${active?'white':'#4e657b'}" text-anchor="middle" font-size="12" font-weight="600">${observation.id}</text></g>`;
    if(active&&screen!==null)svg+=`<g class="observation-handle" data-observation-screen transform="translate(${xx},0)" role="slider" tabindex="0" aria-label="Observation ${activeId} position" aria-valuemin="0" aria-valuemax="${g.image}" aria-valuenow="${Number(screen.toFixed(3))}"><title>Observation screen · z = ${Number(screen.toFixed(3))} mm · Drag to move · Alt to move freely</title><path d="M0 ${leader+1}V${yy-16}" stroke="white" stroke-width="3"/><path class="screen-line" d="M0 ${leader+1}V${yy-16}" stroke="#155fdf" stroke-width="1.4" stroke-dasharray="4 4"/><rect x="-10" y="${leader+1}" width="20" height="${yy-leader+5}" fill="transparent"/>${marker}</g>`;
    else svg+=`<g class="screen-tick" data-observation="${observation.id}" transform="translate(${xx},0)" role="button" tabindex="0" aria-label="Select observation ${observation.id}">${marker}</g>`;
  }
  return {svg,height};
}
