function slice=lithography_illumination_wave_slice(p,r,z,peak,axisM)
% Integrate a continuous incoherent source as piecewise-constant radiance cells.
% Analytic Gaussian cell integrals resolve narrow beamlets without ray splatting.
if nargin<4,peak=[];end
b=lithography_gaussian_illumination(p,z);
adaptive=nargin<5 || isempty(axisM);
if adaptive
    support=r.sourceExtent*b.sourceScaleM;
    if strcmp(p.sourceType,'Point')
        support=max(abs([p.pointSourceU,p.pointSourceV]))*b.sourceScaleM;
    end
    half=max(abs(b.eta)*support+3/sqrt(b.alpha),1e-12);
    axisM=linspace(-half,half,201);
end
axisXM=axisM;axisYM=axisM;
if adaptive && strcmp(p.sourceType,'Point')
    offset=linspace(-3/sqrt(b.alpha),3/sqrt(b.alpha),201);
    axisXM=offset+b.eta*b.sourceScaleM*p.pointSourceU;
    axisYM=offset+b.eta*b.sourceScaleM*p.pointSourceV;
end
if strcmp(p.sourceType,'Point')
    f=lithography_gaussian_mode(b,axisXM,axisYM,p.pointSourceU,p.pointSourceV);
    raw=abs(f).^2;
else
    q=linspace(-r.sourceExtent,r.sourceExtent,size(r.sourceRaw,1))*b.sourceScaleM;
    dq=q(2)-q(1);
    G=cellIntegral(axisM(:),q,dq,b);
    raw=abs(b.gain)^2*(G*r.sourceRaw*G.')/max(sum(r.sourceRaw(:))*dq^2,realmin);
end
raw=max(0,raw);
if any(~isfinite(raw(:))),error('Lithography:Numerics','Nonfinite illumination field.');end
[intensity,scale]=lithography_normalize_intensity(raw,p,r,peak);
label='before condenser';
if z==0,label='source waist plane';elseif z>=p.sourceToCondenserMm,label='after Gaussian-aperture condenser';end
note='Continuous incoherent Gaussian emitters; ideal paraxial thin lens';
if ~any(raw(:)),note='DARK: no transmitted field';end
slice=struct('axis',axisXM*1e6,'axisM',axisXM,'rawIntensity',raw,'intensity',intensity,...
    'axisX',axisXM*1e6,'axisY',axisYM*1e6,'axisXM',axisXM,'axisYM',axisYM,...
    'zMm',z,'stageLabel',label,'mode','Wave','model','Paraxial Gaussian illumination',...
    'titleText','Wave illumination (Gaussian emitters / Gaussian condenser)',...
    'xlabelText','x (um)','ylabelText','y (um)','normalizationMode',p.intensityNorm,...
    'normalizationPeak',scale,'viewNote',note,'isExact',false);
end

function G=cellIntegral(x,q,dq,b)
K=2*b.alpha*b.eta^2-2*b.beta;
if K<=realmin
    G=exp(-2*b.alpha*x.^2)*ones(size(q))*dq;
    return;
end
centre=(2*b.alpha*b.eta/K)*x;
pref=exp((4*b.alpha*b.beta/K)*x.^2);
lo=sqrt(K)*(q-dq/2-centre);hi=sqrt(K)*(q+dq/2-centre);
delta=erf(hi)-erf(lo);
positive=lo>=0;negative=hi<=0;
% erfc avoids subtracting two numbers rounded to one in weak Gaussian tails.
delta(positive)=erfc(lo(positive))-erfc(hi(positive));
delta(negative)=erfc(-hi(negative))-erfc(-lo(negative));
G=pref.*(sqrt(pi)/(2*sqrt(K))).*delta;
end
