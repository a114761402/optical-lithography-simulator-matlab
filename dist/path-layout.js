// Both diagrams use the same physical z domain and 18px end insets.
export function pathFrame(width,max){
  const left=18,right=Math.max(left,width-18);
  return {left,right,x:z=>left+z/max*(right-left)};
}
export function pathRegions(g){
  return [
    {name:'Illumination',start:g.source,end:g.mask},
    {name:'Projection',start:g.mask,end:g.image}
  ].map(region=>({...region,left:100*region.start/g.max,width:100*(region.end-region.start)/g.max}));
}
export function regionMarkup(g){
  return pathRegions(g).map(r=>`<span style="left:${r.left}%;width:${r.width}%"><span>${r.name}</span></span>`).join('');
}
