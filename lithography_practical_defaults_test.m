function [p,r] = lithography_practical_defaults_test()
% Actual startup setup, separate from frozen mathematical reference fixtures.
p=lithography_default_params();q=lithography_check_settings(p);
assert(isequaln(p,q),'Default numerical plan is not self-consistent.');
r=lithography_run_physics(p);g=r.geometry;
[~,centre]=min(abs(r.objectAxisM));line=r.mask(centre,:)>.5;
assert(sum(diff([false line false])==1)==3,'Default mask has clipped extra bars.');
assert(p.maskPlateSizeMm==50.8 && p.maskSizeUm==60 && p.fieldSizeUm==80);
assert(g.fieldToLens1Mm==100 && g.projectionLensSeparation==125 && g.lens2ToImageMm==25);
assert(g.zCondenser==100 && g.zField==200 && g.zPupil==400 && g.zImage==450);
assert(p.xySliceZMm==g.zImage,'Startup selection is not the image plane.');
T=@(d)[1 d;0 1];L=@(f)[1 0;-1/f 1];
M=T(25)*L(25)*T(125)*L(100)*T(100);
assert(norm(M-[-.25 0;0 -4])<1e-12,'Independent 4f ray-matrix check.');
s=lithography_compute_xy_slice(p,r,g.zImage);
assert(isequal(s.rawIntensity,r.imageRaw),'XY and overview images differ.');
x=r.imageAxisM*1e6;[~,iy]=min(abs(x));profile=r.image(iy,:);
ii=find(profile(2:end-1)>profile(1:end-2)&profile(2:end-1)>profile(3:end))+1;
ii=ii(abs(x(ii))<p.maskSizeUm/(2*p.reduction)&profile(ii)>.3);
assert(numel(ii)==3,'Default line pattern is not resolved.');
assert(max(abs(diff(x(ii))-p.gratingPitchUm/p.reduction))<.15);
gap=interp1(x,profile,(x(ii(1:2))+x(ii(2:3)))/2);
assert(max(gap)<.4,'Insufficient default line contrast.');
fprintf('Default: 3 resolved lines, pitch %.4g um; gap intensities %.4g, %.4g; illumination discrepancy %.4g%%.\n',mean(diff(x(ii))),gap,100*r.illuminationQuadratureError);
% Finer emitter quadrature and pupil grid: compare common physical image ROI.
for kind=1:3
    t=p;t.enforceLimits=false;
    if kind==1,t.maxSourceSamples=1225;elseif kind==2,t.propagationPadding=3;else,t.gridSize=768;end
    rr=lithography_run_physics(t);
    roi=abs(x)<=p.fieldSizeUm/(2*p.reduction);[X,Y]=meshgrid(x(roi)*1e-6);
    finer=interp2(rr.imageAxisM,rr.imageAxisM,rr.imageRaw,X,Y,'linear');
    base=r.imageRaw(roi,roi);err=norm(finer(:)-base(:))/norm(finer(:));
    fprintf('Default convergence case %d: relative intensity error %.4g%%.\n',kind,100*err);
    assert(err<.03,'Default has not converged within 3%%: %.5g',err);
end
% Other masks and true-dark cases. No normalization can manufacture light.
t=p;t.sourceType='Point';
for mask={'Circular Aperture','Square Aperture','Diamond Aperture','Annular Aperture','1D Grating','2D Grating','Cross'}
    t.maskType=mask{1};t=lithography_check_settings(t);rr=lithography_run_physics(t);
    for z=[g.zField g.zField+.001 g.zPupil g.zImage]
        ss=lithography_compute_xy_slice(t,rr,z);assert(all(isfinite(ss.rawIntensity(:))) && max(ss.rawIntensity(:))>0);
    end
end
for kind=1:2
    t=p;t.sourceType='Point';
    if kind==1,t.condenserAperture=0;else,t.lensType='Freeform';t.customPupilMask(:)=0;end
    t=lithography_check_settings(t);rr=lithography_run_physics(t);assert(~any(rr.imageRaw(:)));
end
% Large/undersampled or non-conjugate requests must be rejected, not clamped.
for kind=1:3
    t=p;
    if kind==1,t.fieldSizeUm=p.maskPlateSizeMm*1000;elseif kind==2,t.fieldToPupilMm=199;else,t.sourceOuter=1;end
    rejected=false;try,lithography_check_settings(t);catch,rejected=true;end
    assert(rejected,'An unsupported setting was silently accepted.');
end
fig=figure('Visible','off','Position',[40 80 850 470]);
cleanup=onCleanup(@()delete(fig));lithography_render_mask_scale(fig,p,r);
% Optional outputs let callers save results without a platform-specific path.
fprintf('Practical defaults: geometry, image/XY agreement, convergence, 28 mask/plane cases, 2 dark cases and 3 guard cases passed.\n');
end
