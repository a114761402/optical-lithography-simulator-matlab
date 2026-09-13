function report=lithography_illumination_tests(verbose)
% Independent Gaussian formulas, Fresnel quadrature, interfaces and coupling.
if nargin<1,verbose=true;end
names={};values=[];limits=[];
p=lithography_check_settings(lithography_reference_params());p.sourceType='Point';
lambda=p.wavelengthNm*1e-9;w0=lambda/(pi*p.sourceEmissionNA);
for divergence=[.02,.10,.15]
    p.sourceEmissionNA=divergence;w=lambda/(pi*divergence);
    for z=[0,.001,.1,30,59.999]
        b=lithography_gaussian_illumination(p,z);
        width=w*sqrt(1+(lambda*z*1e-3/(pi*w^2))^2);
        record('free Gaussian width',abs(1/sqrt(b.alpha)/width-1),1e-12);
        record('free Gaussian power',abs(b.powerPrefactor-1),1e-12);
    end
end
p.sourceEmissionNA=.1;
% Fresnel integral evaluated directly on a fine source-plane quadrature.
u=1e-6/(p.condenserFocalMm*1e-3*p.projNA/p.reduction);
b0=lithography_gaussian_illumination(p,0);
xin=linspace(-8*w0,8*w0,601)+1e-6;
fin=lithography_gaussian_mode(b0,xin,xin,u,u);
for z=[1,10,100]*1e-6
    b=lithography_gaussian_illumination(p,z*1e3);
    out=linspace(-2/sqrt(b.alpha),2/sqrt(b.alpha),51)+1e-6;
    K=exp(1i*pi*(out(:)-xin).^2/(lambda*z));
    direct=K*fin*K.'*(xin(2)-xin(1))^2/(1i*lambda*z);
    actual=lithography_gaussian_mode(b,out,out,u,u);
    phase=sum(conj(actual(:)).*direct(:));actual=actual*phase/abs(phase);
    record('independent complex Fresnel Gaussian',norm(actual(:)-direct(:))/norm(direct(:)),1e-6);
end
% Passive Gaussian aperture: integrate product of two displaced Gaussians.
for aperture=[.05,.3,1]
    p.condenserAperture=aperture;
    s=p.sourceToCondenserMm*1e-3;f=p.condenserFocalMm*1e-3;
    wc2=w0^2+(lambda*s/(pi*w0))^2;
    b=lithography_gaussian_illumination(p,p.sourceToCondenserMm);
    a=b.apertureRadiusM;q=.8*b.sourceScaleM;
    expected=a^2/(a^2+wc2)*exp(-2*q^2/(a^2+wc2));
    [~,power]=lithography_gaussian_mode(b,0,0,.8,0);
    record('Gaussian aperture analytic transmission',abs(power/expected-1),2e-8);
    record('Gaussian aperture centroid',abs(b.eta-a^2/(a^2+wc2)),1e-12);
    wcapped2=wc2*a^2/(wc2+a^2);
    invR=s/(s^2+(pi*w0^2/lambda)^2)-1/f;
    for d=[.001,.01,.06]
        b=lithography_gaussian_illumination(p,(s+d)*1e3);
        width2=wcapped2*((1+d*invR)^2+(lambda*d/(pi*wcapped2))^2);
        record('post-lens Gaussian width',abs(1/b.alpha/width2-1),1e-10);
        [~,power]=lithography_gaussian_mode(b,0,0,.8,0);
        record('post-lens power conservation',abs(power/expected-1),2e-8);
    end
end
p.condenserAperture=1;r=lithography_run_physics(p);g=r.geometry;
% Lens exit intensity is incident intensity times physical amplitude^2.
x=linspace(-.01,.01,101);
before=lithography_illumination_wave_slice(p,r,g.zCondenser-1e-8,[],x);
after=lithography_illumination_wave_slice(p,r,g.zCondenser,[],x);
[X,Y]=meshgrid(x,x);a=r.maskIllumination.apertureRadiusM;
expected=before.rawIntensity.*exp(-2*(X.^2+Y.^2)/a^2);
record('condenser interface transmission',relative(after.rawIntensity,expected),1e-8);
% At the mask, the same incident complex field feeds diffraction and the relay.
s=lithography_illumination_wave_slice(p,r,g.zField,[],r.objectAxisM);
record('point illumination to mask continuity',relative(s.rawIntensity,r.maskIncidentRaw),1e-12);
record('thin mask intensity boundary',relative(r.maskExitRaw,r.maskIncidentRaw.*abs(r.mask).^2),1e-12);
f=lithography_coherent_fields(p,r,0,0);
record('actual field drives image',relative(r.imageRaw,abs(f.image).^2),1e-12);
record('mask slice equals actual exit',relative(lithography_compute_xy_slice(p,r,g.zField).rawIntensity,r.maskExitRaw),1e-12);
% Sources: continuous cell integration vs a separately summed fine quadrature.
types={'Point','Circular','Square','Annular','Dipole X','Dipole Y','Quadrupole','Freeform'};
for j=1:numel(types)
    q=p;q.sourceType=types{j};q.pointSourceU=.7;q.pointSourceV=-.4;
    q.enforceLimits=false;q.maxSourceSamples=625;
    rr=lithography_run_physics(q);
    for z=[0,.001,g.zCondenser/2,g.zCondenser,g.zField-.001]
        ss=lithography_compute_xy_slice(q,rr,z);
        record([types{j} ' finite wave'],double(any(~isfinite(ss.rawIntensity(:)))||any(ss.rawIntensity(:)<0)||~strcmp(ss.mode,'Wave')),0);
    end
    ss=lithography_illumination_wave_slice(q,rr,g.zField,[],rr.objectAxisM);
    record([types{j} ' source integration at mask'],relative(ss.rawIntensity,rr.maskIncidentRaw),.005);
    if strcmp(types{j},'Circular')
        ss=lithography_compute_xy_slice(q,rr,0);[X,Y]=meshgrid(ss.axisM,ss.axisM);
        interior=ss.rawIntensity(hypot(X,Y)<.8*q.sourceOuter*rr.maskIllumination.sourceScaleM);
        record('circle no checkerboard',std(interior)/mean(interior),1e-10);
        record('source total power on global grid',abs(sum(ss.rawIntensity(:))*(ss.axisM(2)-ss.axisM(1))^2-1),.02);
        dense=linspace(-rr.sourceExtent,rr.sourceExtent,401);[U,V]=meshgrid(dense,dense);
        weights=lithography_source_values(U,V,q);weights=weights/sum(weights(:));
        b=lithography_gaussian_illumination(q,30);axis=linspace(-.006,.006,11);
        actual=lithography_illumination_wave_slice(q,rr,30,[],axis);
        direct=zeros(11);
        for k=find(weights(:)>0).'
            field=lithography_gaussian_mode(b,axis,axis,U(k),V(k));
            direct=direct+weights(k)*abs(field).^2;
        end
        record('continuous source vs dense independent sum',relative(actual.rawIntensity,direct),.005);
    end
end
% Empty source, empty pupil, blocked condenser and tiny-aperture rejection.
q=p;q.condenserAperture=0;rr=lithography_run_physics(q);
record('blocked condenser leaves source on',double(max(lithography_compute_xy_slice(q,rr,.001).rawIntensity,[],'all')<=0),0);
for z=[g.zCondenser,g.zField,g.zField+.001,g.zPupil,g.zImage]
    record('blocked condenser dark downstream',max(lithography_compute_xy_slice(q,rr,z).rawIntensity,[],'all'),0);
end
for kind={'source','pupil'}
    q=p;
    if strcmp(kind{1},'source'),q.sourceType='Freeform';q.customSourceMask=zeros(129);
    else,q.lensType='Freeform';q.customPupilMask=zeros(129);q.fieldSizeUm=16;q.reduction=2;q=lithography_check_settings(q);end
    rr=lithography_run_physics(q);record(['empty ' kind{1} ' image'],max(rr.imageRaw(:)),0);
end
for field={'sourceEmissionNA','condenserAperture'}
    q=p;q.(field{1})=1e-8;rejected=false;
    try,lithography_check_settings(q);catch e,rejected=strcmp(e.identifier,'Lithography:Settings');end
    record(['reject invalid ' field{1}],double(~rejected),0);
end
q=p;q.condenserAperture=.3;rr=lithography_run_physics(q);
record('smaller condenser reduces absolute image',double(sum(rr.imageRaw(:))>=sum(r.imageRaw(:))),0);
q=p;q.sourceEmissionNA=.02;rr=lithography_run_physics(q);
record('source divergence changes downstream result',double(relative(rr.imageRaw,r.imageRaw)<.01),0);
report=struct('names',{names},'values',values,'limits',limits,'pass',all(values<=limits),...
    'passCount',sum(values<=limits),'totalCount',numel(values));
if verbose,fprintf('Full illumination: %d/%d passed.\n',report.passCount,report.totalCount);end
assert(report.pass,'Full-path illumination tests failed.');
    function record(name,value,limit)
        names{end+1}=name;values(end+1)=value;limits(end+1)=limit;
        if verbose,fprintf('%s: %.5g (limit %.5g) %s\n',name,value,limit,string(value<=limit));end
    end
end
function e=relative(a,b)
e=norm(a(:)-b(:))/max(norm(b(:)),realmin);
end
