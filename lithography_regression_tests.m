function report=lithography_regression_tests(displayReport)
% Independent physics references and adversarial cases, no shape cosmetics.
if nargin<1,displayReport=true;end
names={}; values=[]; limits=[];
p=lithography_benchmark_params();p.sourceType='Point';p.gridSize=128;
r=lithography_run_physics(p); lambda=p.wavelengthNm*1e-9;
x=r.objectAxisM;dx=x(2)-x(1);[X,Y]=meshgrid(x,x);
% RS reference evaluated directly, independently from FFT convolution.
maskNames={'Circular Aperture','Square Aperture','Diamond Aperture','Annular Aperture','1D Grating','2D Grating','Cross'};
for m=1:numel(maskNames)
    p.maskType=maskNames{m};r=lithography_run_physics(p);
    active=r.mask>0;xs=X(active);ys=Y(active);
    for z=[1,50,100]*1e-6
        actual=lithography_wave_propagate(r.mask,lambda,dx,z,4);
        ii=[53,65,77];jj=[58,65,72];expected=zeros(3,3);
        for row=1:3
            for col=1:3
                radius=sqrt((x(ii(col))-xs).^2+(x(jj(row))-ys).^2+z^2);
                h=z./radius.^2.*(1./(2*pi*radius)-1i/lambda).*exp(1i*2*pi*radius/lambda);
                expected(row,col)=sum(h.*r.mask(active))*dx^2;
            end
        end
        got=actual(jj,ii);
        record(sprintf('RS %s %.0f um',p.maskType,z*1e6),norm(got(:)-expected(:))/max(norm(expected(:)),eps),1e-9);
    end
end
% Bluestein/Collins reference: direct matrix quadrature with complex input.
xin=linspace(-3e-6,3e-6,32);yout=linspace(-2e-4,2e-4,47);
[XX,YY]=meshgrid(xin,xin);input=exp(-(XX.^2+YY.^2)/(1e-6)^2).*exp(1i*XX/1e-6);
for B=[-.01,.01]
    A=.4;D=.7;
    Q=input.*exp(1i*pi*A*(XX.^2+YY.^2)/(lambda*B));
    K=exp(-1i*2*pi*yout(:)*xin/(lambda*B));[OX,OY]=meshgrid(yout,yout);
    reference=K*Q*K.'.*exp(1i*pi*D*(OX.^2+OY.^2)/(lambda*B))*(xin(2)-xin(1))^2/(1i*lambda*B);
    actual=lithography_lct(input,xin,yout,lambda,A,B,D);
    record('Collins direct complex reference',norm(actual(:)-reference(:))/norm(reference(:)),1e-10);
end
% Pupil reconstructed backward THROUGH lens 2 must match the forward field.
% Analytic Gaussian diffraction checks a continuous solution, not just sums.
gx=linspace(-8e-6,8e-6,256);[GX,GY]=meshgrid(gx,gx);w0=2e-6;
gauss=exp(-(GX.^2+GY.^2)/w0^2);
for z=[50e-6,1e-3,10e-3]
    width=w0*sqrt(1+(lambda*z/(pi*w0^2))^2);
    gy=linspace(-2*width,2*width,101);[OX,OY]=meshgrid(gy,gy);
    expected=(w0/width)^2*exp(-2*(OX.^2+OY.^2)/width^2);
    got=abs(lithography_lct(gauss,gx,gy,lambda,1,z,1)).^2;
    record(sprintf('analytic Gaussian %.0f um',z*1e6),norm(got(:)-expected(:))/norm(expected(:)),1e-5);
end
p.gridSize=64;p.maskType='Cross';p.projNA=.2;
for R=[1,4,20]
    p.reduction=R;r=lithography_run_physics(p);g=r.geometry;
    record(sprintf('4f magnification R%d',R),abs(g.relayFocal2Mm/g.relayFocal1Mm-1/R),1e-12);
    propagation=@(d)[1,d;0,1];lens=@(f)[1,0;-1/f,1];
    ABCD=propagation(g.zImageNominal-g.zProjection2)*lens(g.relayFocal2Mm)*...
        propagation(g.zProjection2-g.zProjection1)*lens(g.relayFocal1Mm)*propagation(g.zProjection1-g.zField);
    record(sprintf('independent ray matrix R%d',R),max(abs(ABCD(1,:)-[-1/R,0])),1e-10);
    f=lithography_coherent_fields(p,r,0,0);
    back=lithography_lct(f.image,f.imageAxis,f.pupilAxis,lambda,0,-g.relayFocal2Mm*1e-3,0);
    a=abs(back).^2;b=abs(f.pupil).^2;
    record(sprintf('pupil reconstruction R%d',R),norm(a(:)-b(:))/max(norm(b(:)),eps),1e-9);
    pupilEnergy=sum(abs(f.pupil(:)).^2)*(f.pupilAxis(2)-f.pupilAxis(1))^2;
    imageEnergy=sum(abs(f.image(:)).^2)*(f.imageAxis(2)-f.imageAxis(1))^2;
    record(sprintf('relay power R%d',R),abs(pupilEnergy-imageEnergy)/max(pupilEnergy,eps),1e-10);
end
% Every mask / pupil and several longitudinal positions. No forced symmetry.
p=lithography_benchmark_params();p.gridSize=64;p.sourceType='Point';p.projNA=.25;
pupils={'Circular','Annular','Square','Diamond','Horizontal Slit','Vertical Slit','Freeform'};
for m=1:numel(maskNames)
    for j=1:numel(pupils)
        p.maskType=maskNames{m};p.lensType=pupils{j};r=lithography_run_physics(p);g=r.geometry;
        z=[g.zField+.05,g.zProjection1-.001,g.zProjection1+.001,g.zPupil,g.zPupil+.001,g.zProjection2-.001,g.zProjection2+.001,g.zImage,g.zImage+.001];
        ok=true;
        for q=1:numel(z)
            s=lithography_compute_xy_slice(p,r,z(q));
            ok=ok && all(isfinite(s.rawIntensity(:))) && all(s.rawIntensity(:)>=0) && max(s.rawIntensity(:))>0;
        end
        record([maskNames{m} ' / ' pupils{j}],double(~ok),0);
    end
end
% Blocked/empty illumination and pupil cannot invent a fallback light source.
sources={'Point','Circular','Square','Annular','Dipole X','Dipole Y','Quadrupole','Freeform'};
for k=1:numel(sources)
    p=lithography_benchmark_params();p.gridSize=64;p.maxSourceSamples=49;p.sourceType=sources{k};
    p.pointSourceU=.3;p.pointSourceV=-.2;r=lithography_run_physics(p);
    s=lithography_compute_xy_slice(p,r,r.geometry.zField+.05);
    record(['source shape ' sources{k}],double(any(~isfinite(s.intensity(:))) || any(~isfinite(r.image(:))) || max(r.image(:))==0),0);
end
for wavelength=[50,193,2000]
    for defocus=[-20,0,20]
        p=lithography_benchmark_params();p.sourceType='Point';p.gridSize=64;
        p.wavelengthNm=wavelength;p.defocusUm=defocus;r=lithography_run_physics(p);
        s=lithography_compute_xy_slice(p,r,r.geometry.zImage);
        record(sprintf('wavelength %g defocus %g',wavelength,defocus),double(any(~isfinite(s.rawIntensity(:)))),0);
    end
end
% Airy first dark ring is an independent continuum diffraction benchmark.
p=lithography_benchmark_params();p.gridSize=128;p.propagationPadding=8;p.sourceType='Point';p.projNA=.25;
r=lithography_run_physics(p);r.mask(:)=0;r.mask(65,65)=1;
f=lithography_coherent_fields(p,r,0,0);[~,ctr]=min(abs(f.imageAxis));
profile=abs(f.image(ctr,:)).^2; expectedRadius=.609835*p.wavelengthNm*1e-9/p.projNA;
candidate=find(f.imageAxis>.8*expectedRadius & f.imageAxis<1.2*expectedRadius);
[~,ii]=min(profile(candidate)); measured=f.imageAxis(candidate(ii));
record('Airy first zero',abs(measured-expectedRadius)/expectedRadius,.04);
p=lithography_benchmark_params();p.gridSize=64;p.sourceType='Point';p.pointSourceU=2;p.condenserAperture=.1;
r=lithography_run_physics(p);record('blocked point dark',max(r.imageRaw(:)),0);
s=lithography_compute_xy_slice(p,r,r.geometry.zField+.05);record('blocked near field dark',max(s.rawIntensity(:)),0);
p.sourceType='Freeform';p.customSourceMask=zeros(129);r=lithography_run_physics(p);record('empty source dark',max(r.imageRaw(:)),0);
p.sourceType='Point';p.pointSourceU=0;p.lensType='Freeform';p.customPupilMask=zeros(129);r=lithography_run_physics(p);record('closed pupil dark',max(r.imageRaw(:)),0);
% Shared physical normalization, zero and infinitesimal propagation.
for n=[63,65,96]
    p=lithography_benchmark_params();p.gridSize=n;p.sourceType='Point';
    rr=lithography_run_physics(p);
    record(sprintf('odd/even grid %d',n),double(any(~isfinite(rr.image(:)))),0);
    in=eye(n);out=lithography_wave_propagate(in,lambda,p.fieldSizeUm*1e-6/n,1e-14);
    record(sprintf('odd/even origin %d',n),norm(abs(out(:))-in(:))/norm(in(:)),1e-6);
end
in=ones(32);out=lithography_wave_propagate(in,lambda,dx,0);record('zero distance identity',norm(out-in),0);
out=lithography_wave_propagate(in,lambda,dx,1e-12);record('near-zero continuity',norm(abs(out(:)).^2-1)/sqrt(numel(in)),1e-5);
[~,scale]=lithography_normalize_intensity(ones(3),struct('intensityNorm','XYZ'),struct('xyzReferencePeak',7));record('shared normalization',abs(scale-7),0);
p.projNA=1.2;rejected=false;try,lithography_run_physics(p);catch,rejected=true;end;record('NA above air limit rejected',double(~rejected),0);
p.projNA=.2;p.fieldToPupilMm=10;rejected=false;try,lithography_run_physics(p);catch,rejected=true;end;record('invalid geometry rejected',double(~rejected),0);
for value=[0,.5,1,NaN]
    p.customSourceMask=value;p.customPupilMask=value;
    u=[-2,0,2];expected=[0,0,0];if isfinite(value),expected(2)=value;end
    record('single-pixel source',norm(lithography_custom_source_values(u,zeros(size(u)),p)-expected),0);
    record('single-pixel pupil',norm(lithography_custom_pupil_values(u,zeros(size(u)),p)-expected),0);
end
report=struct('names',{names},'errors',values,'limits',limits,'passed',values<=limits,'pass',all(values<=limits));
report.passCount=sum(report.passed);report.totalCount=numel(values);
if displayReport
    fprintf('Independent regression: %d/%d passed\n',report.passCount,report.totalCount);
    for k=find(~report.passed),fprintf('FAIL %s: %.6g (limit %.6g)\n',names{k},values(k),limits(k));end
end
    function record(name,value,limit)
        names{end+1}=name;values(end+1)=value;limits(end+1)=limit;
    end
end
