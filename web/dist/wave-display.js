import {brightness} from './wave.js?v=20260927-positions3';
import {projectionDisplayHalf,fullPathDisplayHalf} from './wave-components.js?v=20261003-full-path';

const mix=(a,b,t)=>a+(b-a)*t;
// Monotone cubic interpolation: no new extrema, negative intensity or ringing.
function slope(a,b,ha,hb){if(a*b<=0)return 0;const w1=2*hb+ha,w2=hb+2*ha;return (w1+w2)/(w1/a+w2/b);}
function hermite(v0,v1,v2,v3,z0,z1,z2,z3,t){
  const h=z2-z1,d=(v2-v1)/h,m1=slope((v1-v0)/(z1-z0),d,z1-z0,h),m2=slope(d,(v3-v2)/(z3-z2),h,z3-z2);
  const t2=t*t,t3=t2*t,value=(2*t3-3*t2+1)*v1+(t3-2*t2+t)*h*m1+(-2*t3+3*t2)*v2+(t3-t2)*h*m2;
  return Math.max(Math.min(v1,v2),Math.min(Math.max(v1,v2),value));
}
function atUnit(values,u){
  const f=Math.max(0,Math.min(1,u))*(values.length-1),i=Math.min(values.length-2,Math.floor(f));
  return mix(values[i],values[i+1],f-i);
}

// Blend at a fixed physical transverse coordinate. Stretching the profile
// with its changing calculation window incorrectly moves annular lobes.
export function createWaveSampler(result,section='xz',mode='local'){
  const columns=result.columns.map(col=>{
    const axis=section==='xz'?col.x:col.y,values=col[section];
    let peak=0;for(const value of values)peak=Math.max(peak,value);
    return {z:col.z,lo:axis[0],hi:axis.at(-1),values,peak};
  });
  const boundaries=['mask','pupil'].map(key=>result.geometry?.[key]).filter(Number.isFinite);
  return z=>{
    if(!columns.length||z<columns[0].z||z>columns.at(-1).z)return null;
    let lo=0,hi=columns.length-1;
    while(lo<hi){const mid=Math.ceil((lo+hi)/2);if(columns[mid].z<=z)lo=mid;else hi=mid-1;}
    const a=columns[lo];let b=columns[Math.min(lo+1,columns.length-1)],t=a===b?0:(z-a.z)/(b.z-a.z);
    // A thin component acts at its own plane; do not smear its change upstream.
    if(t===0||boundaries.some(at=>at>a.z&&at<=b.z)){b=a;t=0;}
    const lower=mix(a.lo,b.lo,t),upper=mix(a.hi,b.hi,t);
    const at=(col,y)=>y<col.lo||y>col.hi?0:atUnit(col.values,(y-col.lo)/(col.hi-col.lo));
    const previous=columns[lo-1],next=columns[lo+2];
    const cubic=t!==0&&previous&&next&&a.z>=result.geometry?.mask&&!boundaries.some(z=>z>previous.z&&z<=next.z);
    const value=y=>cubic?hermite(at(previous,y),at(a,y),at(b,y),at(next,y),previous.z,a.z,b.z,next.z,t):mix(at(a,y),at(b,y),t);
    let reference=result.sharedPeak;
    if(mode==='local'){
      reference=a.peak;
      if(t!==0){
        reference=0;
        // The maximum of a piecewise-linear blend occurs at one of its knots.
        for(const col of [a,b])for(let i=0;i<col.values.length;i++){const y=col.lo+(col.hi-col.lo)*i/(col.values.length-1);if(y>=lower&&y<=upper)reference=Math.max(reference,value(y));}
        reference=Math.max(reference,value(lower),value(upper));
      }
    }
    return {lower,upper,reference,sample(y){return y<lower||y>upper?null:value(y);}};
  };
}

export function renderWavePixels(result,{width,height,half,section='xz',mode='local',palette,illuminationPalette=null,showWindow=false,projectionCrop=false,fullPathIllustration=false,displayHeight=height}){
  const pixels=new Uint8ClampedArray(width*height*4),sampleAt=createWaveSampler(result,section,mode);
  const grey=showWindow?[223,230,237]:palette(0),colours=Array.from({length:1024},(_,i)=>palette(i/1023));
  const warm=illuminationPalette?Array.from({length:1024},(_,i)=>illuminationPalette(i/1023)):colours;
  const dy=2*half/height,dz=(result.zMax-result.zMin)/width;
  for(let x=0;x<width;x++){
    // Two horizontal subpixels plus exact vertical coverage antialias the window edge.
    const frames=[.25,.75].map(offset=>{const z=result.zMin+(x+offset)*dz;return {frame:sampleAt(z),ramp:z<result.geometry.mask?warm:colours,limit:fullPathIllustration?fullPathDisplayHalf(result,z,half,displayHeight):projectionCrop?projectionDisplayHalf(result,z,half,displayHeight):Infinity};});
    for(let y=0;y<height;y++){
      const top=half-y*dy,bottom=top-dy,rgb=[0,0,0];
      for(const {frame,ramp,limit} of frames){
        const low=frame?Math.max(bottom,frame.lower,-limit):0,high=frame?Math.min(top,frame.upper,limit):0;
        const coverage=Math.max(0,Math.min(1,(high-low)/dy));
        const colour=coverage>0?ramp[Math.round(brightness(frame.sample((low+high)/2),frame.reference,mode)*1023)]:grey;
        for(let channel=0;channel<3;channel++)rgb[channel]+=.5*mix(grey[channel],colour[channel],coverage);
      }
      const k=(y*width+x)*4;pixels[k]=rgb[0];pixels[k+1]=rgb[1];pixels[k+2]=rgb[2];pixels[k+3]=255;
    }
  }
  return pixels;
}
