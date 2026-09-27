// Continuous, mutually incoherent circular / annular source. Integrate the
// Gaussian over the exact circular boundary, rather than a rasterized pupil.
function erf(x){const sign=x<0?-1:1;x=Math.abs(x);const t=1/(1+.5*x);return sign*(1-t*Math.exp(-x*x-1.26551223+t*(1.00002368+t*(.37409196+t*(.09678418+t*(-.18628806+t*(.27886807+t*(-1.13520398+t*(1.48851587+t*(-.82215223+t*.17087277))))))))));}
function integrate(f,a,b,tolerance=2e-8){
  const c=(a+b)/2,fa=f(a),fb=f(b),fc=f(c),whole=(b-a)*(fa+4*fc+fb)/6;
  function refine(a,b,fa,fb,fc,whole,tol,depth){const c=(a+b)/2,l=(a+c)/2,r=(c+b)/2,fl=f(l),fr=f(r),left=(c-a)*(fa+4*fl+fc)/6,right=(b-c)*(fc+4*fr+fb)/6,delta=left+right-whole;if(depth===0||Math.abs(delta)<=15*tol)return left+right+delta/15;return refine(a,c,fa,fc,fl,left,tol/2,depth-1)+refine(c,b,fc,fb,fr,right,tol/2,depth-1);}
  return refine(a,b,fa,fb,fc,whole,Math.max(1e-20,tolerance*Math.max(Math.abs(fa),Math.abs(fb),Math.abs(fc))*(b-a)),16);
}
export function radialIllumination(beam,inner,outer,r){
  if(!(outer>inner)||beam.gainAbs2===0)return 0;
  const {alpha,eta,beta,gainAbs2}=beam,K=2*alpha*eta*eta-2*beta;
  if(K<1e-20)return gainAbs2*Math.exp(-2*alpha*r*r);
  if(r===0)return gainAbs2*Math.exp(-K*inner*inner)*(-Math.expm1(-K*(outer*outer-inner*inner)))/(K*(outer*outer-inner*inner));
  const root=Math.sqrt(K),center=2*alpha*eta*r/K,lo=Math.max(-9,root*(-outer-center)),hi=Math.min(9,root*(outer-center));
  if(hi<=lo)return 0;
  const f=t=>{const x=center+t/root,outerHeight=Math.sqrt(Math.max(0,outer*outer-x*x)),innerHeight=Math.sqrt(Math.max(0,inner*inner-x*x));return Math.exp(-t*t)*Math.max(0,erf(root*outerHeight)-erf(root*innerHeight));};
  const knots=[lo,hi,...[-6,-3,-1,0,1,3,6,root*(-inner-center),root*(inner-center)].filter(t=>t>lo&&t<hi)].sort((a,b)=>a-b);
  let sum=0;for(let i=1;i<knots.length;i++)sum+=integrate(f,knots[i-1],knots[i]);
  return Math.max(0,gainAbs2*Math.exp(4*alpha*beta*r*r/K)*Math.sqrt(Math.PI)*sum/(K*Math.PI*(outer*outer-inner*inner)));
}
export function radialIlluminationImage(p,beam,x,y=x){
  const outer=p.sourceOuter*beam.scale,inner=p.sourceType==='Annular'?p.sourceInner*beam.scale:0;
  const maxX=Math.max(Math.abs(x[0]),Math.abs(x.at(-1))),maxY=Math.max(Math.abs(y[0]),Math.abs(y.at(-1))),maxR=Math.hypot(maxX,maxY);
  const dx=Math.abs(x[1]-x[0]),step=Math.min(dx/4,1/(4*Math.sqrt(beam.alpha))),count=Math.min(16384,Math.max(2,Math.ceil(maxR/step)+1)),dr=maxR/(count-1);
  const values=Float64Array.from({length:count},(_,i)=>radialIllumination(beam,inner,outer,i*dr)),out=new Float64Array(x.length*y.length);
  for(let j=0;j<y.length;j++)for(let i=0;i<x.length;i++){const u=Math.hypot(x[i],y[j])/dr,k=Math.min(count-2,Math.floor(u)),t=u-k;out[j*x.length+i]=values[k]*(1-t)+values[k+1]*t;}
  return out;
}
