function slice=lithography_compute_illumination_xy_slice(p,g,z,mode,n)
% Continuous ray-density convolution; NO sparse ray splatting or cosmetic blur.
aDist=g.zCondenser-g.zSourcePlane;
if z<=g.zCondenser
    B=(z-g.zSourcePlane)/aDist;A=1-B;
else
    d=z-g.zCondenser;A=-d/aDist;B=1+d/aDist-d/p.condenserFocalMm;
end
support=max([p.sourceOuter,p.quadSeparation/2+p.sourceOuter,1]);
if strcmp(p.sourceType,'Quadrupole'),support=p.quadSeparation/sqrt(2)+.6;end
if strcmp(p.sourceType,'Point'),support=max(abs([p.pointSourceU,p.pointSourceV]));end
aperture=p.condenserAperture*g.condenserHalf;
half=max(.12,1.1*(abs(A)*support+abs(B)*aperture));
axisValues=linspace(-half,half,n);[X,Y]=meshgrid(axisValues,axisValues);
if aperture==0 && z>=g.zCondenser
    raw=zeros(n);
elseif abs(B)*aperture<1e-12
    if abs(A)<1e-12,raw=zeros(n);else,raw=lithography_source_values(X/A,Y/A,p);end
elseif strcmp(p.sourceType,'Point')
    raw=double(hypot(X-A*p.pointSourceU,Y-A*p.pointSourceV)<=abs(B)*aperture);
elseif abs(A)<1e-12
    [U,V]=meshgrid(linspace(-support,support,129));
    light=lithography_source_values(U,V,p);
    raw=double(hypot(X,Y)<=abs(B)*aperture)*double(any(light(:)>0));
else
    source=lithography_source_values(X/A,Y/A,p);
    kernel=double(hypot(X,Y)<=abs(B)*aperture);
    if sum(kernel(:))==0,kernel(ceil(n/2),ceil(n/2))=1;end
    kernel=kernel/sum(kernel(:));
    P=2^nextpow2(2*n-1);
    full=real(ifft2(fft2(source,P,P).*fft2(kernel,P,P)));
    first=floor(n/2)+1;raw=max(0,full(first:first+n-1,first:first+n-1));
end
slice=struct('axis',axisValues,'rawIntensity',raw,'intensity',raw,'zMm',z,...
    'stageLabel','illumination','mode',mode,'titleText','','xlabelText','normalized x',...
    'ylabelText','normalized y','isExact',false);
end
