import {pathFrame} from './path-layout.js?v=20260927-position-fit';
import {snapPosition} from './observation-state.js?v=20260927-position-fit';
export function setupScreenDrag(svg,{geometry,currentZ,onMove,onSelect,onStart,compact}){
  let drag=null;
  const enabled=()=>!compact()&&!svg.classList.contains('compact-beam');
  const move=e=>{
    if(!drag)return;
    const rect=svg.getBoundingClientRect(),width=svg.viewBox.baseVal.width,g=geometry(),frame=pathFrame(width,g.image),scale=rect.width/width;
    const z=((e.clientX-rect.left)/scale-frame.left)*g.image/(frame.right-frame.left);
    const snap=snapPosition(Math.max(0,Math.min(g.image,z)),g,(frame.right-frame.left)*scale,{bypass:e.altKey,previous:drag.snapped,displayMax:g.image});drag.snapped=snap.plane;onMove(snap.z,snap.plane);
  };
  svg.addEventListener('pointerdown',e=>{
    if(!enabled()||e.button!==0||!e.isPrimary||!e.target.closest('[data-observation-screen]'))return;
    e.preventDefault();onStart();drag={snapped:null};svg.setPointerCapture(e.pointerId);svg.classList.add('dragging-screen');
    svg.querySelector('[data-observation-screen]')?.focus({preventScroll:true});
  });
  svg.addEventListener('pointermove',move);
  const end=e=>{if(!drag)return;drag=null;svg.classList.remove('dragging-screen');if(svg.hasPointerCapture(e.pointerId))svg.releasePointerCapture(e.pointerId);};
  svg.addEventListener('pointerup',end);svg.addEventListener('pointercancel',end);svg.addEventListener('lostpointercapture',()=>{drag=null;svg.classList.remove('dragging-screen');});
  svg.addEventListener('click',e=>{const marker=e.target.closest('[data-observation]');if(marker){onStart();onSelect(marker.dataset.observation);}});
  svg.addEventListener('keydown',e=>{
    const marker=e.target.closest('[data-observation]');if(marker&&['Enter',' '].includes(e.key)){e.preventDefault();onStart();onSelect(marker.dataset.observation);return;}
    if(!enabled()||!e.target.closest('[data-observation-screen]')||!['ArrowLeft','ArrowRight','Home','End'].includes(e.key))return;
    e.preventDefault();onStart();const g=geometry(),step=e.shiftKey?.001:1;onMove(e.key==='Home'?0:e.key==='End'?g.image:Math.max(0,Math.min(g.image,currentZ()+(e.key==='ArrowLeft'?-step:step))),'custom');
  });
}
