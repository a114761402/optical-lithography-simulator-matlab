// The overlay uses the geometry of the displayed calculation, never live inputs.
// Only z is to scale. Symbols describe ideal components, not their physical size.
const names = [['source','Source pupil'],['condenser','Condenser'],['mask','Mask'],['lens1','Lens 1'],['pupil','Aperture'],['lens2','Lens 2'],['image','Image']];
// A display envelope, not a lens acceptance calculation. Match the illustrated
// lens heights; retain the physical mask/image windows at the two endpoints.
export function projectionDisplayHalf(result,z,half,height){
  const g=result.geometry,p=result.params;
  if(result.scope==='near'||z<g.mask||z>g.image)return Infinity;
  const symbolUnit=2*half/height*Math.min(1,height/240);
  const anchors=[[g.mask,p.fieldSizeUm*.5e-6],[g.lens1,36*symbolUnit],
    [g.lens2,29*symbolUnit],[g.image,p.fieldSizeUm*.5e-6/p.reduction]];
  for(let i=1;i<anchors.length;i++)if(z<=anchors[i][0]){
    const [a,ha]=anchors[i-1],[b,hb]=anchors[i];
    return ha+(hb-ha)*Math.max(0,Math.min(1,(z-a)/(b-a)));
  }
  return Infinity;
}
// Explicit full-path illustration: component outlines form a visual envelope.
// This never selects incident rays or modifies the computed intensities.
export function fullPathDisplayHalf(result,z,half,height){
  if(result.scope==='near')return Infinity;
  const g=result.geometry,p=result.params,u=2*half/height*Math.min(1,height/240);
  const anchors=[[g.source,25*u],[g.condenser,36*u],[g.mask,p.fieldSizeUm*.5e-6],
    [g.lens1,36*u],[g.pupil,Math.min(14*u,g.f2*.001*p.projNA)],
    [g.lens2,29*u],[g.image,p.fieldSizeUm*.5e-6/p.reduction]];
  if(z<g.source||z>g.image)return Infinity;
  for(let i=1;i<anchors.length;i++)if(z<=anchors[i][0]){
    const [a,ha]=anchors[i-1],[b,hb]=anchors[i];return ha+(hb-ha)*(z-a)/(b-a);
  }
  return Infinity;
}
export function waveComponentLayout(result,width,height){
  const span=result.zMax-result.zMin;
  if(!(span>0)||!(width>0)||!(height>0))return [];
  const items=names.filter(([key])=>result.geometry[key]>=result.zMin&&result.geometry[key]<=result.zMax)
    .map(([key,name])=>({key,name,z:result.geometry[key],x:(result.geometry[key]-result.zMin)/span*width,y:height/2}));
  return items.map((item,i)=>{
    const gap=Math.min(i?item.x-items[i-1].x:Infinity,i<items.length-1?items[i+1].x-item.x:Infinity);
    return {...item,halfWidth:Math.max(.6,Math.min(8,gap*.22)),halfHeight:item.key==='lens2'?29:36,
      label:['source','mask','image'].includes(item.key)||(height>128&&width>=680&&gap>65),labelY:height<=128?height-9:height-38+(width>=680&&i>3&&i%2?14:0)};
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
    return `<g class="wave-element ${key==='image'?'image-reference':''}" data-wave-component="${key}" transform="translate(${x},${y})"><title>${name} · z = ${Number(z.toFixed(3))} mm</title><g transform="scale(1,${verticalScale})">${shape}</g></g>${label?`<text class="wave-element-label" data-wave-label="${key}" x="${labelX}" y="${labelY}" text-anchor="${anchor}">${name}</text>`:''}`;
  }).join('');
}
