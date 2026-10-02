const clamp=(z,max)=>Math.max(0,Math.min(max,z));
const rounded=z=>Math.round(z*1000)/1000;
// Gain is bounded and gradual. Fine motion keeps its unrounded accumulator.
export class RelativeTuning {
  constructor(z,max,x,time,options={}){Object.assign(this,{z:clamp(z,max),max,x,time,speed:0,direction:0,velocity:0,fastTime:0,slow:[.5,1,2].includes(options.slow)?options.slow:1,fast:[.5,1,1.5].includes(options.fast)?options.fast:1,glide:[0,.5,1].includes(options.glide)?options.glide:1});}
  move(x,time){
    const dx=x-this.x,dt=Math.max(1,time-this.time),direction=Math.sign(dx);
    this.x=x;this.time=time;
    if(!dx){this.speed=0;this.velocity=0;this.fastTime=0;return rounded(this.z);}
    const instant=Math.abs(dx)/dt;
    if(direction!==this.direction||dt>120){this.speed=0;this.fastTime=0;}
    if(instant<this.speed)this.speed=instant;
    this.fastTime=instant>.6?this.fastTime+Math.min(dt,50):0;
    const steps=Math.max(1,Math.ceil(Math.min(dt,200)/2)),interval=dt/steps;
    for(let i=0;i<steps;i++){
      this.speed+=(instant-this.speed)*(1-Math.exp(-interval/35));
      const t=Math.max(0,(this.speed-.08)/.9);
      const fine=.002*this.slow,coarse=this.max/300*this.fast;
      const gain=fine+(coarse-fine)*t*t/(t*t+.5);
      this.velocity=direction*this.speed*gain;
      this.z=clamp(this.z+dx/steps*gain,this.max);
    }
    this.direction=direction;
    return rounded(this.z);
  }
  release(time){
    if(!this.glide||time-this.time>60||this.speed<.6||this.fastTime<45||this.z<=0||this.z>=this.max)return null;
    return new TuningCoast(this.z,this.max,Math.sign(this.velocity)*Math.min(Math.abs(this.velocity),this.max*.0008)*this.glide);
  }
}
// Analytic decay gives identical travel at 60/120 Hz. At most 240 ms and
// about 7% of the path; no elastic overshoot or motion after interruption.
export class TuningCoast {
  constructor(z,max,velocity){Object.assign(this,{start:z,max,velocity,z,done:false});}
  advance(elapsed){
    const t=Math.max(0,Math.min(elapsed,240));
    this.z=clamp(this.start+this.velocity*90*(1-Math.exp(-t/90)),this.max);
    this.done=elapsed>=240||this.z<=0||this.z>=this.max;
    return rounded(this.z);
  }
}
export function setupRelativeTuning(node,{currentZ,maximum,enabled,onMove,target,settings=()=>({}),onActiveChange=()=>{}}){
  let drag=null,coast=null,frame=null,queued=null,epoch=0,applying=false,tickOffset=0;
  const paintTicks=offset=>{tickOffset=offset%12;node.style.setProperty('--tick-offset',`${tickOffset}px`);};
  const apply=value=>{if(value!==currentZ()){applying=true;try{onMove(value);}finally{applying=false;}}};
  const flush=()=>{frame=null;if(queued!==null){const value=queued;queued=null;apply(value);}};
  const stop=(keepActive=false)=>{
    epoch++;coast=null;
    if(frame!==null)cancelAnimationFrame(frame);frame=null;
    const previous=drag;drag=null;
    if(previous?.identity!==target())queued=null;
    flush();node.classList.remove('scrubbing');if(keepActive!==true)onActiveChange(false);
    if(previous&&node.hasPointerCapture(previous.id))node.releasePointerCapture(previous.id);
  };
  const runCoast=(model,identity)=>{
    const ticket=epoch,initialTicks=tickOffset;let start=null,last=null;
    coast=model;onActiveChange(true);
    const tick=time=>{
      if(ticket!==epoch||coast!==model)return;
      frame=null;
      if(identity!==target()||!enabled()||document.hidden||(last!==null&&time-last>100)){stop();return;}
      if(start===null)start=time;last=time;
      apply(model.advance(time-start));
      paintTicks(initialTicks+model.z-model.start);
      if(model.done)stop();else frame=requestAnimationFrame(tick);
    };
    frame=requestAnimationFrame(tick);
  };
  node.addEventListener('pointerdown',e=>{
    const alreadyDragging=!!drag;stop();
    if(alreadyDragging||!enabled()||!e.isPrimary||e.button!==0)return;
    e.preventDefault();node.focus({preventScroll:true});
    drag={id:e.pointerId,identity:target(),origin:e.clientX,initialTicks:tickOffset,model:new RelativeTuning(currentZ(),maximum(),e.clientX,e.timeStamp,settings())};
    node.setPointerCapture(e.pointerId);node.classList.add('scrubbing');onActiveChange(true);
  });
  node.addEventListener('pointermove',e=>{
    if(!drag||drag.id!==e.pointerId)return;
    if(drag.identity!==target()){stop();return;}
    e.preventDefault();queued=drag.model.move(e.clientX,e.timeStamp);
    paintTicks(drag.initialTicks+e.clientX-drag.origin);
    if(frame===null){const ticket=epoch;frame=requestAnimationFrame(()=>{if(ticket===epoch)flush();});}
  });
  node.addEventListener('pointerup',e=>{
    if(drag?.id!==e.pointerId)return;
    const identity=drag.identity,model=identity===target()?drag.model.release(e.timeStamp):null;
    stop(!!model);if(model)runCoast(model,identity);
  });
  for(const name of ['pointercancel','lostpointercapture'])node.addEventListener(name,e=>{if(drag?.id===e.pointerId)stop();});
  window.addEventListener('blur',stop);document.addEventListener('visibilitychange',()=>{if(document.hidden)stop();});
  document.addEventListener('position-view-change',stop);
  document.addEventListener('pointerdown',e=>{if(coast||(drag&&e.pointerId!==drag.id))stop();},true);
  for(const name of ['click','input','change','keydown'])document.addEventListener(name,e=>{if(!node.contains(e.target))stop();},true);
  node.addEventListener('keydown',e=>{
    if(!enabled()||!['ArrowLeft','ArrowRight','ArrowUp','ArrowDown','Home','End'].includes(e.key))return;
    stop();onActiveChange(true);e.preventDefault();const step=e.shiftKey?1:.001;
    apply(e.key==='Home'?0:e.key==='End'?maximum():clamp(currentZ()+(['ArrowLeft','ArrowDown'].includes(e.key)?-step:step),maximum()));
  });
  node.addEventListener('keyup',stop);node.addEventListener('blur',stop);
  const sync=()=>{if(!applying)stop();node.setAttribute('aria-disabled',String(!enabled()));node.tabIndex=enabled()?0:-1;node.setAttribute('aria-valuemin','0');node.setAttribute('aria-valuemax',String(maximum()));node.setAttribute('aria-valuenow',String(clamp(currentZ(),maximum())));node.setAttribute('aria-valuetext',`${currentZ()} millimetres`);};
  document.addEventListener('observation-position-change',sync);sync();
  return {stop};
}
