import {fft1} from './optics.js?v=20260927-illumination2';
const PI=Math.PI,TAU=2*PI;
// The same Bluestein transform as the full Collins integral, for one vector.
function transform(re,im,x,y,scale){
  const n=x.length,m=y.length,P=2**Math.ceil(Math.log2(2*n+m-2)),theta=(x[1]-x[0])*(y[1]-y[0])/scale;
  const kr=new Float64Array(P),ki=new Float64Array(P),a=new Float64Array(P),b=new Float64Array(P);
  for(let k=0;k<n+m-1;k++){const t=k-n+1,phi=PI*theta*t*t;kr[k]=Math.cos(phi);ki[k]=Math.sin(phi);}fft1(kr,ki);
  for(let j=0;j<n;j++){const phi=-TAU*x[j]*y[0]/scale-PI*theta*j*j,c=Math.cos(phi),s=Math.sin(phi);a[j]=re[j]*c-im[j]*s;b[j]=re[j]*s+im[j]*c;}
  fft1(a,b);for(let j=0;j<P;j++){const t=a[j]*kr[j]-b[j]*ki[j];b[j]=a[j]*ki[j]+b[j]*kr[j];a[j]=t;}fft1(a,b,true);
  const power=new Float64Array(m);
  // The omitted output chirp and -i prefactor have unit magnitude.
  for(let j=0;j<m;j++){const k=n-1+j;power[j]=a[k]*a[k]+b[k]*b[k];}
  return power;
}
// Evaluate the two rows and columns that bracket zero. Interpolate intensity,
// not the complex amplitude, exactly as centerCuts(full LCT) does.
export function lctCenterCuts(f,x,y,lambda,A,B){
  if(Math.abs(B)<1e-15)throw Error('Coincident plane requires the direct field.');
  const n=x.length,m=y.length,xz=new Float64Array(m),yz=new Float64Array(m);
  if(0<y[0]||0>y.at(-1))return {xz,yz};
  const fraction=(0-y[0])/(y[1]-y[0]),lo=Math.min(m-2,Math.max(0,Math.floor(fraction))),t=Math.max(0,Math.min(1,fraction-lo)),scale=lambda*B,amp2=((x[1]-x[0])**2/scale)**2;
  const phaseR=new Float64Array(n),phaseI=new Float64Array(n);
  for(let j=0;j<n;j++){const phi=PI*A*x[j]*x[j]/scale;phaseR[j]=Math.cos(phi);phaseI[j]=Math.sin(phi);}
  for(const [at,weight] of [[y[lo],1-t],[y[lo+1],t]]){
    if(weight===0)continue;
    const kr=new Float64Array(n),ki=new Float64Array(n),hr=new Float64Array(n),hi=new Float64Array(n),vr=new Float64Array(n),vi=new Float64Array(n);
    for(let j=0;j<n;j++){const phi=PI*A*x[j]*x[j]/scale-TAU*x[j]*at/scale;kr[j]=Math.cos(phi);ki[j]=Math.sin(phi);}
    for(let i=0;i<n;i++)for(let j=0;j<n;j++){
      const k=i*n+j,r=f.re[k],v=f.im[k];
      hr[j]+=r*kr[i]-v*ki[i];hi[j]+=r*ki[i]+v*kr[i];
      vr[i]+=r*kr[j]-v*ki[j];vi[i]+=r*ki[j]+v*kr[j];
    }
    for(let j=0;j<n;j++){
      const r=hr[j];hr[j]=r*phaseR[j]-hi[j]*phaseI[j];hi[j]=r*phaseI[j]+hi[j]*phaseR[j];
      const v=vr[j];vr[j]=v*phaseR[j]-vi[j]*phaseI[j];vi[j]=v*phaseI[j]+vi[j]*phaseR[j];
    }
    const horizontal=transform(hr,hi,x,y,scale),vertical=transform(vr,vi,x,y,scale);
    for(let j=0;j<m;j++){xz[j]+=horizontal[j]*amp2*weight;yz[j]+=vertical[j]*amp2*weight;}
  }
  return {xz,yz};
}
