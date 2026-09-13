function p=lithography_check_settings(p)
% Guarded teaching-mode contract. These are numerical/model bounds, not
% a claim of agreement with a real lens or an exhaustive convergence proof.
choices={'sourceType',{'Point','Circular','Square','Annular','Dipole X','Dipole Y','Quadrupole','Freeform'};...
    'maskType',{'Circular Aperture','Square Aperture','Diamond Aperture','Annular Aperture','1D Grating','2D Grating','Cross'};...
    'lensType',{'Circular','Annular','Square','Diamond','Horizontal Slit','Vertical Slit','Freeform'};...
    'intensityNorm',{'Local','XYZ'}};
for j=1:size(choices,1)
    v=p.(choices{j,1});
    if ~(ischar(v)||(isstring(v)&&isscalar(v))) || ~any(strcmp(v,choices{j,2}))
        error('Lithography:Settings','Unsupported %s.',choices{j,1});
    end
end
bounds={ 'sourceOuter',.08,1;'sourceInner',0,.96;'quadSeparation',.1,2;...
    'pointSourceU',-1,1;'pointSourceV',-1,1;'condenserAperture',0,1;'sourceEmissionNA',.02,.15;...
    'maskSizeUm',.1,75;'maskInnerRatio',0,.9;'gratingPitchUm',.1,50;...
    'gratingDuty',.1,.9;'projNA',.05,.30;'lensInner',0,.9;...
    'reduction',1,20;'wavelengthNm',50,2000;'fieldSizeUm',1,100;...
    'defocusUm',-20,20;'condenserFocalMm',20,160;'projectionFocalMm',20,220;...
    'sourceToCondenserMm',20,160;'fieldToPupilMm',20,220;'xySliceZMm',0,900};
for j=1:size(bounds,1)
    name=bounds{j,1};v=p.(name);lo=bounds{j,2};hi=bounds{j,3};
    if ~isnumeric(v)||~isreal(v)||~isscalar(v)||~isfinite(v)||v<lo||v>hi
        error('Lithography:Settings','%s must be between %g and %g.',name,lo,hi);
    end
end
if ~strcmp(p.illuminationModel,'Incoherent Gaussian emitters')
    error('Lithography:Settings','The GUI uses the incoherent Gaussian-emitter full-path model.');
end
if isfield(p,'maskPlateSizeMm')
    v=p.maskPlateSizeMm;
    if ~isnumeric(v)||~isreal(v)||~isscalar(v)||~isfinite(v)||v<1||v>200
        error('Lithography:Settings','Mask plate side must be between 1 and 200 mm (context only).');
    end
    if p.fieldSizeUm>p.maskPlateSizeMm*1000
        error('Lithography:Settings','The local calculation window must fit inside the mask plate.');
    end
end
radius=p.condenserFocalMm*1e-3*p.projNA/p.reduction*p.condenserAperture;
if radius>0 && radius<p.wavelengthNm*1e-9/(pi*.15)
    error('Lithography:Settings','Gaussian condenser radius is too small for paraxial propagation. Increase it or set exactly 0 to block light.');
end
extent=lithography_source_extent(p);
if ~strcmp(p.sourceType,'Point') && 2*extent*p.projNA*p.maskSizeUm/(25*p.reduction*p.wavelengthNm*.001)>.25
    error('Lithography:Settings','Extended-source quadrature is too coarse for this mask/NA/wavelength combination. Reduce source extent, mask size or NA, or increase reduction.');
end
if sqrt(2)*extent*p.projNA/p.reduction>.30 && ~strcmp(p.sourceType,'Point')
    error('Lithography:Settings','Source support exceeds the paraxial angular range. Reduce source extent or NA, or increase reduction.');
end
if strcmp(p.sourceType,'Point') && hypot(p.pointSourceU,p.pointSourceV)*p.projNA/p.reduction>.30
    error('Lithography:Settings','Point-source offset exceeds the paraxial angular range.');
end
if abs(p.sourceToCondenserMm-p.condenserFocalMm)>1e-9 || abs(p.fieldToPupilMm-p.projectionFocalMm)>1e-9
    error('Lithography:Settings','Guarded mode requires the nominal condenser and 4f conjugate distances.');
end
if strcmp(p.sourceType,'Annular') && p.sourceOuter-p.sourceInner<.04-1e-12
    error('Lithography:Settings','Source ring thickness must be at least 0.04.');
end
if p.maskSizeUm>.75*p.fieldSizeUm
    error('Lithography:Settings','Mask size must be <= 75%% of the mask window; enlarge the window.');
end
feature=p.maskSizeUm;
switch p.maskType
    case {'1D Grating','2D Grating'}
        if p.gratingPitchUm>p.maskSizeUm
            error('Lithography:Settings','Grating pitch must not exceed its mask envelope.');
        end
        feature=p.gratingPitchUm*min(p.gratingDuty,1-p.gratingDuty);
    case 'Annular Aperture',feature=p.maskSizeUm*(1-p.maskInnerRatio)/2;
    case 'Cross',feature=p.maskSizeUm/3;
end
lambda=p.wavelengthNm/1000; % micrometres
if feature<lambda
    error('Lithography:Settings','Smallest mask feature must be >= wavelength (%g um) in this thin scalar-mask mode.',lambda);
end
maxDefocus=min(20,.25*lambda/p.projNA^4);
if abs(p.defocusUm)>maxDefocus
    error('Lithography:Settings','For this NA and wavelength, |defocus| must be <= %.3g um (paraxial phase-error guard).',maxDefocus);
end
% Eight mask samples and four samples per admitted illumination/pupil period.
required=max([256,ceil(2*p.fieldSizeUm/lambda),ceil(8*p.fieldSizeUm/feature),ceil(8*p.fieldSizeUm*p.projNA/(p.reduction*lambda))]);
choices=[256,384,512];i=find(choices>=required,1);
if isempty(i),error('Lithography:Settings','Mask/window combination needs more than 512 pixels. Enlarge features or reduce the window.');end
p.gridSize=choices(i);
diameterRequired=20;
if strcmp(p.lensType,'Annular'),diameterRequired=max(20,8/(1-p.lensInner));end
if any(strcmp(p.lensType,{'Horizontal Slit','Vertical Slit'}))
    if p.lensInner<.1,error('Lithography:Settings','Slit pupil width ratio must be >= 0.1.');end
    diameterRequired=max(20,4*sqrt(1+p.lensInner^2)/p.lensInner);
end
if strcmp(p.lensType,'Freeform'),diameterRequired=64;end
p.propagationPadding=max(2,ceil(diameterRequired*lambda*p.reduction/(2*p.fieldSizeUm*p.projNA)));
if p.propagationPadding>8 || p.gridSize*p.propagationPadding>2048
    error('Lithography:Settings','Pupil is undersampled within the memory limit. Enlarge the mask window, reduce reduction, or use a wider pupil.');
end
imageMargin=(p.propagationPadding*p.fieldSizeUm-p.maskSizeUm)/(2*p.reduction);
if abs(p.defocusUm)*p.projNA>.5*imageMargin
    error('Lithography:Settings','Defocused beam may leave the computational window. Reduce defocus or enlarge the window.');
end
for field={'customSourceMask','customPupilMask'}
    v=p.(field{1});
    if ~isnumeric(v)||~isreal(v)||isempty(v)||ndims(v)~=2||any(~isfinite(v(:)))||any(v(:)<0|v(:)>1)||max(size(v))>129||size(v,1)~=size(v,2)
        error('Lithography:Settings','%s must be a finite square array, size 1..129, with values 0..1.',field{1});
    end
end
p.sourceGridSize=201;p.maxSourceSamples=625;
p.enforceLimits=true;
end
