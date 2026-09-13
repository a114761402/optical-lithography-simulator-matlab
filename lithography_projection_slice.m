function slice=lithography_projection_slice(p,r,z,peak)
if nargin<4, peak=[]; end
g=r.geometry; lambda=p.wavelengthNm*1e-9;
N=p.gridSize; x=r.objectAxisM; dx=x(2)-x(1);
f1=g.relayFocal1Mm*1e-3; f2=g.relayFocal2Mm*1e-3;
dz=(z-g.zField)*1e-3;
nearLimit=0.5e-3;
if abs(z-g.zField)<1e-10
    axisM=x; raw=r.maskExitRaw; label='mask exit'; model='Thin mask';
elseif abs(z-g.zPupil)<1e-10
    axisM=r.pupilAxisM; raw=r.pupilRaw; label='pupil exit'; model='Paraxial relay';
else
    useNear=dz>0 && dz<nearLimit && z<g.zProjection1;
    afterLens=z>=g.zProjection2;
    nearImage=afterLens && abs(z-g.zImageNominal)*1e-3<nearLimit && ...
        abs(z-g.zImageNominal)*1e-3*p.projNA<.2*max(abs(r.imageAxisM));
    if useNear
        axisM=x; label='mask diffraction'; model='Scalar diffraction (RS / band-limited AS)';
    elseif nearImage
        axisM=r.imageAxisM; label='image neighbourhood'; model='Paraxial relay';
    else
        if z<g.zProjection1
            A=1; B=dz; D=1; label='before lens 1';
        elseif z<g.zPupil
            a=(g.zProjection1-g.zField)*1e-3; d=(z-g.zProjection1)*1e-3;
            A=1-d/f1; B=a+d-a*d/f1; D=1-a/f1; label='lens 1 to pupil';
        elseif z<g.zProjection2
            % Backward Collins transform THROUGH lens 2 from nominal image.
            A=(z-g.zPupil)*1e-3/f2; B=-f2; D=0; label='pupil to lens 2';
        else
            A=1; B=(z-g.zImageNominal)*1e-3; D=1; label='after lens 2';
        end
        if z<g.zPupil
            support=max(abs(x)); angle=min(.4,max(p.projNA/p.reduction,lambda/(p.maskSizeUm*1e-6)))*(1+p.sourceOuter);
        else
            support=max(abs(r.imageAxisM)); angle=min(.8,p.projNA)*(1+p.sourceOuter);
        end
        half=max(support,abs(A)*support+abs(B)*angle);
        axisM=linspace(-half,half,N); model='Paraxial relay';
    end
    raw=zeros(numel(axisM));
    for k=1:numel(r.sourceWeights)
        if r.sourceWeights(k)==0, continue; end
        f=lithography_coherent_fields(p,r,r.sourceSamplesU(k),r.sourceSamplesV(k));
        if useNear
            field=lithography_wave_propagate(f.mask,lambda,dx,dz,4);
        elseif nearImage
            field=lithography_fresnel_same(f.image,lambda,axisM(2)-axisM(1),(z-g.zImageNominal)*1e-3);
        elseif z<g.zPupil
            field=lithography_lct(f.mask,x,axisM,lambda,A,B,D);
        else
            field=lithography_lct(f.image,f.imageAxis,axisM,lambda,A,B,D);
        end
        raw=raw+r.sourceWeights(k)*abs(field).^2;
    end
end
% An observation plane must not select a different propagation grid/operator.
if abs(z-g.zImage)<1e-10,label='image plane';elseif z>g.zImage,label='after image';end
viewNote='';
if z>g.zField && z<g.zProjection1 && dz<nearLimit
    viewNote='Cropped ROI: the beam may extend beyond these axes';
end
if max(raw(:))==0
    viewNote='DARK: no transmitted field';
elseif min(raw(:))/max(raw(:))>.9
    viewNote=[viewNote ' | Nearly uniform in this view'];
end
[intensity,scale]=lithography_normalize_intensity(raw,p,r,peak);
slice=struct('axis',axisM*1e6,'axisM',axisM,'rawIntensity',raw,'intensity',intensity,...
    'zMm',z,'stageLabel',label,'mode','Wave','model',model,'titleText',model,...
    'xlabelText','x (um)','ylabelText','y (um)','normalizationMode',p.intensityNorm,...
    'normalizationPeak',scale,'viewNote',viewNote,'isExact',false);
if abs(z-g.zPupil)<1e-10
    slice.displayHalfWidthM=1.1*f2*p.projNA;
end
end
