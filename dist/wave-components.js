// The overlay uses the geometry of the displayed calculation, never live inputs.
// Only z is to scale. Symbols describe ideal components, not their physical size.
const names = [['source','Source pupil'],['condenser','Condenser'],['mask','Mask'],['lens1','Lens 1'],['pupil','Aperture'],['lens2','Lens 2'],['image','Image']];
export function waveComponentLayout(result,width,height){
  const span=result.zMax-result.zMin;
  if(!(span>0)||!(width>0)||!(height>0))return [];
  const items=names.filter(([key])=>result.geometry[key]>=result.zMin&&result.geometry[key]<=result.zMax)
    .map(([key,name])=>({key,name,z:result.geometry[key],x:(result.geometry[key]-result.zMin)/span*width,y:height/2}));
  return items.map((item,i)=>{
    const gap=Math.min(i?item.x-items[i-1].x:Infinity,i<items.length-1?items[i+1].x-item.x:Infinity);
    return {...item,halfWidth:Math.max(.6,Math.min(8,gap*.22)),halfHeight:item.key==='lens2'?29:36,
      label:['source','mask','image'].includes(item.key)||(width>=680&&gap>46),labelY:height<=128?height-9:height-38+(width>=680&&i>3&&i%2?14:0)};
  });
}
export function waveComponentSVG(result,width,height){
  const verticalScale=Math.min(1,height/240);
  return waveComponentLayout(result,width,height).map(({key,name,z,x,y,halfWidth:w,halfHeight:h,label,labelY})=>{
    let shape;
    if(['condenser','lens1','lens2'].includes(key))shape=`<path d="M0 ${-h}Q${-2*w} 0 0 ${h}Q${2*w} 0 0 ${-h}Z"/>`;
    else if(key==='pupil')shape=`<path d="M${-w} -36H${w}V-14H${-w}ZM${-w} 14H${w}V36H${-w}Z"/>${result.params.lensType==='Annular'?`<path d="M${-w} ${-14*result.params.lensInner}H${w}V${14*result.params.lensInner}H${-w}Z"/>`:''}`;
    else if(key==='mask')shape=`<path d="M${-w} -34H${w}V34H${-w}ZM${-w} -17H${w}M${-w} 0H${w}M${-w} 17H${w}"/>`;
    else if(key==='source')shape='<path d="M0 -25V25M0 -25h7M0 25h7M0 -8l5 8-5 8"/>';
    else shape='<path d="M0 -33V33M-3 -33h6M-3 33h6"/>';
    const anchor=x<30?'start':x>width-65?'end':'middle',labelX=Math.max(7,Math.min(width-7,x));
    return `<g class="wave-element ${key==='image'?'image-reference':''}" data-wave-component="${key}" transform="translate(${x},${y})"><title>${name} · z = ${Number(z.toFixed(6))} mm</title><g transform="scale(1,${verticalScale})">${shape}</g></g>${label?`<text class="wave-element-label" x="${labelX}" y="${labelY}" text-anchor="${anchor}">${name}</text>`:''}`;
  }).join('');
}
