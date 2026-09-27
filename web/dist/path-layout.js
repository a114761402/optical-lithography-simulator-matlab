// Both diagrams use the same physical z domain and 7px end insets.
export function pathFrame(width,max){
  const left=7,right=Math.max(left,width-7);
  return {left,right,x:z=>left+z/max*(right-left)};
}
export function pathRegions(g){
  return [
    {name:'Illumination',start:g.source,end:g.mask},
    {name:'Projection',start:g.mask,end:g.image}
  ].map(region=>({...region,left:100*region.start/g.image,width:100*(region.end-region.start)/g.image}));
}
export function regionMarkup(g){
  return pathRegions(g).map(r=>`<span style="left:${r.left}%;width:${r.width}%"><span>${r.name}</span></span>`).join('');
}

// Display bounds are independent of the cached propagation and defocus range.
export function waveView(result){
  return result.scope==='near'?result:{...result,zMin:result.geometry.source,zMax:result.geometry.image};
}
