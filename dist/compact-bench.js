import {RAY_BLUE,RAY_YELLOW} from './light-palette.js?v=20260927-positions3';
// A screen-sized schematic. z coordinates keep their physical scale; component
// heights and ray heights are illustrative, just as in the large bench view.
export function compactBench({width,geometry:g,params:p,components,selected,screen,pupilValue,mode='many',observations=[],activeId=null}){
  const height=164,left=18,right=width-18,X=z=>left+z/g.max*(right-left),cy=79;
  const positions=components.map(([key])=>X(g[key]));
  const number=n=>Number(n.toFixed(3));
  let svg=`<path d="M${left} ${cy}H${right}" stroke="#bccbd8" stroke-dasharray="3 4"/><path d="M${left} 139H${right}" stroke="#d5dfe7"/>`;
  const points=list=>list.map(([z,y])=>`${X(z)},${cy-y}`).join(' ');
  if(mode!=='none')for(const h of mode==='many'?[-12,-6,0,6,12]:[-12,0,12])for(const a of mode==='many'?[-19,-13,-6,0,6,13,19]:[-19,0,19]){
    const blocked=pupilValue(p,0,a/21)===0,tail=blocked?[]:[[g.lens2,a-h*g.f2/g.f1],[g.image,-h/p.reduction]];
    svg+=`<polyline points="${points([[g.mask,h],[g.lens1,h+a],[g.pupil,a],...tail])}" fill="none" stroke="${RAY_BLUE[h<0?0:h>0?1:2]}" stroke-width=".65" opacity=".36"/>`;
  }
  const starts=p.sourceType==='Point'?[p.pointSourceV*26]:p.sourceType==='Dipole X'?[0]:['Annular','Dipole Y'].includes(p.sourceType)?[-10,10]:[-10,0,10];
  if(mode!=='none')for(const h of starts)for(const a of mode==='many'?[-21,-11,0,11,21]:[-21,0,21])svg+=`<polyline points="${points([[0,h],[g.condenser,a],[g.mask,a-h]])}" fill="none" stroke="${RAY_YELLOW}" stroke-width=".65" opacity=".4"/>`;
  components.forEach(([key,name],i)=>{
    const x=positions[i],gap=Math.min(i?x-positions[i-1]:Infinity,i<6?positions[i+1]-x:Infinity),half=Math.max(.65,Math.min(6,gap*.24)),active=selected===key;
    let shape='';
    if(key==='source')shape=`<rect x="${-half}" y="-17" width="${2*half}" height="34" rx="2" fill="#476579"/><ellipse rx="${Math.max(.5,half-2)}" ry="12" fill="#f9df9c"/>${p.sourceType==='Annular'?`<ellipse rx="${Math.max(.25,(half-2)*p.sourceInner/p.sourceOuter)}" ry="${12*p.sourceInner/p.sourceOuter}" fill="#163040"/>`:""}`;
    else if(['condenser','lens1','lens2'].includes(key)){const h=key==='lens2'?22:29;shape=`<path d="M0 ${-h}Q${-half*2} 0 0 ${h}Q${half*2} 0 0 ${-h}Z" fill="#dceefa" fill-opacity=".75" stroke="#527e9c" stroke-width="1"/>`;}
    else if(key==='mask')shape=`<rect x="${-half*.7}" y="-24" width="${half*1.4}" height="48" rx="1" fill="#52687a"/><path d="M${-half*.65} -13h${half*1.3}m${-half*1.3} 13h${half*1.3}m${-half*1.3} 13h${half*1.3}" stroke="#eff8ff" stroke-width="2.5"/>`;
    else if(key==='pupil'){const aperture=14;shape=`<path class="aperture-blade" d="M0 -26V${-aperture}M0 ${aperture}V26" stroke="#283f53" stroke-width="${Math.min(2,Math.max(1,half))}"/>${p.lensType==='Annular'?`<path class="aperture-blade" d="M0 ${-aperture*p.lensInner}V${aperture*p.lensInner}" stroke="#283f53" stroke-width="${Math.min(2,Math.max(1,half))}"/>`:''}`;}
    else shape=`<rect x="${-half*.6}" y="-18" width="${half*1.2}" height="36" rx=".7" fill="#e5eef6" stroke="#647f94" stroke-width="1"/>`;
    svg+=`<g class="component ${active?'selected':''}" role="button" tabindex="0" data-component="${key}" aria-label="Select ${name}" aria-pressed="${active}" transform="translate(${x},${cy})"><title>${name} · z = ${number(g[key])} mm</title><rect class="selection" x="${-half-2}" y="-35" width="${2*half+4}" height="70" rx="4" fill="#dcecff" stroke="#74a4e1"/>${shape}<rect x="${-Math.min(15,gap*.42)}" y="-34" width="${Math.min(30,gap*.84)}" height="68" fill="transparent"/></g>`;
    // Keep the three reference labels readable even when relay planes cluster.
    // All seven names remain in the component editor with 44px touch targets.
    if(['source','mask','image'].includes(key))svg+=`<text x="${x}" y="25" text-anchor="${key==='source'?'start':key==='image'?'end':'middle'}" fill="#50677b" font-size="12">${name}</text>`;
  });
  const at=Math.max(left,Math.min(right,X(screen)));
  if(screen!==null)svg+=`<g aria-label="Selected observation plane"><title>Observation screen · z = ${number(screen)} mm</title><path d="M${at} 39V117" stroke="#155fdf" stroke-width="1.1" stroke-dasharray="3 3"/><path d="M${at-3} 36h6l-3 5Z" fill="#155fdf"/></g>`;
  for(const o of observations.filter(o=>o.muted))svg+=`<path data-position-tick="${o.id}" d="M${X(o.z)} 135v5" stroke="#b9c9d8"/>`;
  const ordered=observations.filter(o=>!o.muted).map(o=>({...o,labelX:X(o.z)})).sort((a,b)=>a.z-b.z);
  for(let i=1;i<ordered.length;i++)ordered[i].labelX=Math.max(ordered[i].labelX,ordered[i-1].labelX+23);
  if(ordered.length){ordered.at(-1).labelX=Math.min(right-2,ordered.at(-1).labelX);for(let i=ordered.length-2;i>=0;i--)ordered[i].labelX=Math.min(ordered[i].labelX,ordered[i+1].labelX-23);}
  for(const o of ordered){const active=o.id===activeId;svg+=`<g class="compact-position-marker" data-position-marker="${o.id}" aria-label="Position ${o.id} at ${number(o.z)} mm"><path d="M${X(o.z)} 113L${o.labelX} 119" fill="none" stroke="#9badbc"/><rect x="${o.labelX-9}" y="118" width="18" height="18" rx="3" fill="${active?'#155fdf':'#e6edf5'}"/><text x="${o.labelX}" y="131" text-anchor="middle" font-size="12" font-weight="600" fill="${active?'white':'#4e657b'}">${o.id}</text></g>`;}
  for(const z of [0,g.mask,g.image])svg+=`<path d="M${X(z)} 136v6" stroke="#8ca0b0"/><text x="${X(z)}" y="157" text-anchor="${z===0?'start':z===g.image?'end':'middle'}" fill="#667d8f" font-size="12">${number(z)}${z===g.image?' mm':''}</text>`;
  return {svg,height};
}
