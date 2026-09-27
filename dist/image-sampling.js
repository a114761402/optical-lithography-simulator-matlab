// Interpolate linear intensity before brightness mapping. Raw calculation and
// profile arrays are never resampled or modified by this display operation.
export function sampleIntensity(data,n,x,y,smooth=true){
  if(x<0||y<0||x>n-1||y>n-1)return 0;
  if(!smooth)return data[Math.round(y)*n+Math.round(x)];
  const ix=Math.floor(x),iy=Math.floor(y),jx=Math.min(n-1,ix+1),jy=Math.min(n-1,iy+1),tx=x-ix,ty=y-iy;
  return (data[iy*n+ix]*(1-tx)+data[iy*n+jx]*tx)*(1-ty)+(data[jy*n+ix]*(1-tx)+data[jy*n+jx]*tx)*ty;
}
