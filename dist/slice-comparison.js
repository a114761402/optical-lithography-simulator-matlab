// Display-only comparison. Preserve calculated arrays and their physical axes.
const peaks=new WeakMap();
function peak(result){
  if(!peaks.has(result.screenRaw)){let value=0;for(const v of result.screenRaw)value=Math.max(value,v);peaks.set(result.screenRaw,value);}
  return peaks.get(result.screenRaw);
}
export function centeredHalf(result){
  const x=result.screenAxis,y=result.screenAxisY||x;
  return Math.max(Math.abs(x[0]),Math.abs(x.at(-1)),Math.abs(y[0]),Math.abs(y.at(-1)));
}
export function comparisonScale(result,peers,{size=true,intensity=true,fixedWidth=null}={}){
  const comparable=peers.includes(result)&&peers.length>1;
  return {
    half:fixedWidth>0?fixedWidth/2:comparable&&size?Math.max(...peers.map(centeredHalf)):result.screenHalf,
    peak:comparable&&intensity?Math.max(...peers.map(peak)):null,
    sharedSize:comparable&&size,
    sharedIntensity:comparable&&intensity
  };
}
export function scaleBar(width){
  if(!(width>0))return null;
  const target=width*.24,power=10**Math.floor(Math.log10(target));
  const length=[5,2,1].map(v=>v*power).find(v=>v<=target*(1+1e-12));
  const unit=length>=.001?'mm':'µm',factor=unit==='mm'?1e3:1e6;
  return {length,fraction:length/width,label:`${Number((length*factor).toPrecision(3))} ${unit}`};
}
