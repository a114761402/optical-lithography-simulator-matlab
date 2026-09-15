function params = lithography_default_params()
params = struct();

% Practical low-NA i-line laboratory example, not an industrial lens design.
params.maskPlateSizeMm = 50.8; % Context only; isolated patch, zero transmitted field outside ROI.
params.gridSize = 512;
params.sourceGridSize = 201;
params.maxSourceSamples = 625;
params.propagationPadding = 2;
params.enforceLimits = true;
params.illuminationModel = 'Incoherent Gaussian emitters';
params.sourceEmissionNA = 0.05;

params.sourceType = 'Circular';
params.sourceOuter = 0.30;
params.sourceInner = 0.20;
params.quadSeparation = 0.30;
params.pointSourceU = 0.00;
params.pointSourceV = 0.00;
params.customSourceMask = lithography_default_custom_source(129,params.sourceOuter);
params.condenserAperture = 1.00;

params.maskType = '1D Grating';
params.maskSizeUm = 60.0;
params.maskInnerRatio = 0.45;
params.gratingPitchUm = 20.0; % Three complete bars; no clipped edge fragments.
params.gratingDuty = 0.50;

params.lensType = 'Circular';
params.projNA = 0.15;
params.lensInner = 0.35;
params.customPupilMask = lithography_default_custom_pupil();
params.reduction = 4.0;

params.wavelengthNm = 365;
params.fieldSizeUm = 80.0;
params.defocusUm = 0.0;

params.condenserFocalMm = 100;
params.projectionFocalMm = 200; % 2*f1; f1=100 mm, f2=25 mm, gap=125 mm.
params.sourceToCondenserMm = 100;
params.fieldToPupilMm = 200;
params.xySliceZMm = params.sourceToCondenserMm + params.condenserFocalMm + ...
    params.fieldToPupilMm + params.projectionFocalMm/params.reduction;
params.rayDensity = 'Medium';
params.yzMode = 'Continuous';
params.yzView = 'Raw';
params.intensityNorm = 'XYZ';
params.autoYZ = false;
end
