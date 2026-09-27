export const RAY_BLUE=['#487caf','#528fbd','#3771a9'];
export const RAY_YELLOW='#c18b2e';
export const lightRegion=(z,g)=>z<g.mask?'warm':'blue';
export function palette(t,kind='blue'){
  t=Math.max(0,Math.min(1,t));
  if(kind==='mono'){const v=Math.round(8+242*t);return [v,v+Math.round(3*(1-t)),v+Math.round(6*(1-t))];}
  // Both ramps rise in luminance; hue indicates optical region, not wavelength.
  const stops=kind==='warm'?[[7,22,36],[87,66,28],[163,125,43],[231,198,112],[255,251,227]]:[[7,22,36],[22,64,110],[44,131,187],[123,205,242],[233,250,255]];
  const f=t*(stops.length-1),j=Math.min(stops.length-2,Math.floor(f)),u=f-j;return stops[j].map((a,i)=>Math.round(a+(stops[j+1][i]-a)*u));
}
