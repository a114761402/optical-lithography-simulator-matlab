import {brightness} from './wave.js';

const mix=(a,b,t)=>a+(b-a)*t;
function atUnit(values,u){
  const f=Math.max(0,Math.min(1,u))*(values.length-1),i=Math.min(values.length-2,Math.floor(f));
  return mix(values[i],values[i+1],f-i);
}

// Interpolate the sampled mesh, including its changing transverse window.
// This is a display interpolation: no new propagation results are generated.
export function createWaveSampler(result,section='xz',mode='local'){
  const columns=result.columns.map(col=>{
    const axis=section==='xz'?col.x:col.y,values=col[section];
    let peak=0;for(const value of values)peak=Math.max(peak,value);
    return {z:col.z,lo:axis[0],hi:axis.at(-1),values,peak};
  });
  const boundaries=['condenser','mask','lens1','pupil','lens2','image'].map(key=>result.geometry?.[key]).filter(Number.isFinite);
  return z=>{
    if(!columns.length||z<columns[0].z||z>columns.at(-1).z)return null;
    let lo=0,hi=columns.length-1;
    while(lo<hi){const mid=Math.ceil((lo+hi)/2);if(columns[mid].z<=z)lo=mid;else hi=mid-1;}
    const a=columns[lo];let b=columns[Math.min(lo+1,columns.length-1)],t=a===b?0:(z-a.z)/(b.z-a.z);
    // A thin component acts at its own plane; do not smear its change upstream.
    if(t===0||boundaries.some(at=>at>a.z&&at<=b.z)){b=a;t=0;}
    const lower=mix(a.lo,b.lo,t),upper=mix(a.hi,b.hi,t);
    const value=u=>mix(atUnit(a.values,u),atUnit(b.values,u),t);
    let reference=result.sharedPeak;
    if(mode==='local'){
      reference=a.peak;
      if(t!==0){
        reference=0;
        // The maximum of a piecewise-linear blend occurs at one of its knots.
        for(const data of [a.values,b.values])for(let i=0;i<data.length;i++)reference=Math.max(reference,value(i/(data.length-1)));
      }
    }
    return {lower,upper,reference,sample(y){return y<lower||y>upper?null:value((y-lower)/(upper-lower));}};
  };
}

export function renderWavePixels(result,{width,height,half,section='xz',mode='local',palette,illuminationPalette=null}){
  const pixels=new Uint8ClampedArray(width*height*4),sampleAt=createWaveSampler(result,section,mode);
  const grey=[223,230,237],colours=Array.from({length:1024},(_,i)=>palette(i/1023));
  const warm=illuminationPalette?Array.from({length:1024},(_,i)=>illuminationPalette(i/1023)):colours;
  const dy=2*half/height,dz=(result.zMax-result.zMin)/width;
  for(let x=0;x<width;x++){
    // Two horizontal subpixels plus exact vertical coverage antialias the window edge.
    const frames=[.25,.75].map(offset=>{const z=result.zMin+(x+offset)*dz;return {frame:sampleAt(z),ramp:z<result.geometry.mask?warm:colours};});
    for(let y=0;y<height;y++){
      const top=half-y*dy,bottom=top-dy,rgb=[0,0,0];
      for(const {frame,ramp} of frames){
        const low=frame?Math.max(bottom,frame.lower):0,high=frame?Math.min(top,frame.upper):0;
        const coverage=Math.max(0,Math.min(1,(high-low)/dy));
        const colour=coverage>0?ramp[Math.round(brightness(frame.sample((low+high)/2),frame.reference,mode)*1023)]:grey;
        for(let channel=0;channel<3;channel++)rgb[channel]+=.5*mix(grey[channel],colour[channel],coverage);
      }
      const k=(y*width+x)*4;pixels[k]=rgb[0];pixels[k+1]=rgb[1];pixels[k+2]=rgb[2];pixels[k+3]=255;
    }
  }
  return pixels;
}
