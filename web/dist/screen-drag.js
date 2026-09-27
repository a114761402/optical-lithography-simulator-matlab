import {pathFrame} from './path-layout.js?v=20260927-position-fit';
import {snapPosition} from './observation-state.js?v=20260927-position-fit';
// Capture on the stable SVG root: its children are replaced while dragging.
export function setupScreenDrag(svg,{geometry,currentZ,onMove,onSelect,onStart,compact,onDragStart=()=>{},onDragEnd=()=>{}}){
  let drag=null,ignoreClickUntil=0;
  const target=e=>e.target.closest('[data-position-marker],[data-observation-screen]');
  function finish(e,cancelled=false){
    if(!drag||e.pointerId!==drag.pointerId)return;
    const ended=drag;drag=null;
    svg.classList.remove('dragging-screen');
    if(svg.hasPointerCapture(e.pointerId))svg.releasePointerCapture(e.pointerId);
    if(ended.mobile){
      ignoreClickUntil=performance.now()+450;
      if(!cancelled&&!ended.moving&&ended.id)onSelect(ended.id);
    }
    if(ended.moving)onDragEnd();
  }
  svg.addEventListener('pointerdown',e=>{
    if(drag||e.button!==0||!e.isPrimary)return;
    const handle=target(e);if(!handle)return;
    const mobile=compact(),id=handle.dataset.positionMarker||null;
    if(!mobile&&id)return;
    const rect=svg.getBoundingClientRect(),frame=pathFrame(svg.viewBox.baseVal.width,geometry().image);
    drag={pointerId:e.pointerId,mobile,id,x:e.clientX,y:e.clientY,z:id?Number(handle.getAttribute('aria-valuenow')):currentZ(),pixels:(frame.right-frame.left)*rect.width/svg.viewBox.baseVal.width,max:geometry().image,snapped:null,moving:false};
    svg.setPointerCapture(e.pointerId);
    if(!mobile){e.preventDefault();onStart();drag.moving=true;svg.classList.add('dragging-screen');}
  });
  svg.addEventListener('pointermove',e=>{
    if(!drag||e.pointerId!==drag.pointerId)return;
    const dx=e.clientX-drag.x,dy=e.clientY-drag.y;
    if(!drag.moving){
      if(Math.abs(dy)>6&&Math.abs(dy)>Math.abs(dx)){finish(e,true);return;}
      if(Math.abs(dx)<6||Math.abs(dx)<Math.abs(dy)*1.2)return;
      drag.moving=true;
      onDragStart(drag.id,drag.z);
      if(drag.id)onSelect(drag.id);
      svg.classList.add('dragging-screen');
    }
    e.preventDefault();
    const z=Math.max(0,Math.min(drag.max,drag.z+dx*drag.max/drag.pixels));
    // Touch is continuous; exact reference planes remain available in Edit.
    const snap=drag.mobile?{z,plane:'custom'}:snapPosition(z,geometry(),drag.pixels,{bypass:e.altKey,previous:drag.snapped,displayMax:drag.max});
    drag.snapped=snap.plane;onMove(snap.z,snap.plane);
  });
  svg.addEventListener('pointerup',e=>finish(e));
  svg.addEventListener('pointercancel',e=>finish(e,true));
  svg.addEventListener('lostpointercapture',e=>finish(e,true));
  svg.addEventListener('click',e=>{
    if(performance.now()<ignoreClickUntil){e.preventDefault();e.stopImmediatePropagation();return;}
    const marker=e.target.closest('[data-observation],[data-position-marker]');
    if(marker){if(!compact())onStart();onSelect(marker.dataset.observation||marker.dataset.positionMarker);}
  },true);
  svg.addEventListener('keydown',e=>{
    const marker=e.target.closest('[data-observation],[data-position-marker]');
    if(marker&&['Enter',' '].includes(e.key)){e.preventDefault();if(!compact())onStart();onSelect(marker.dataset.observation||marker.dataset.positionMarker);return;}
    if(!target(e)||!['ArrowLeft','ArrowRight','Home','End'].includes(e.key))return;
    e.preventDefault();if(!compact())onStart();if(marker?.dataset.positionMarker)onSelect(marker.dataset.positionMarker);
    const g=geometry(),step=e.shiftKey?.001:1;onMove(e.key==='Home'?0:e.key==='End'?g.image:Math.max(0,Math.min(g.image,currentZ()+(e.key==='ArrowLeft'?-step:step))),'custom');
  });
}
