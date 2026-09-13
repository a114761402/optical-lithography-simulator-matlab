function params = lithography_reference_params()
% Frozen 193-nm small-pattern example for historical tests and presets.
% Not the startup configuration; do not let new GUI defaults change references.
params = struct();
params.maskPlateSizeMm = 50.8; % Context only; not part of the wave operator.

params.gridSize = 256;
params.sourceGridSize = 201;
params.maxSourceSamples = 625;
params.propagationPadding = 4;
params.enforceLimits = true;
params.illuminationModel = 'Incoherent Gaussian emitters';
params.sourceEmissionNA = 0.10;

params.sourceType = 'Circular';
params.sourceOuter = 0.70;
params.sourceInner = 0.45;
params.quadSeparation = 0.55;
params.pointSourceU = 0.00;
params.pointSourceV = 0.00;
params.customSourceMask = lithography_default_custom_source();
params.condenserAperture = 1.00;

params.maskType = '1D Grating';
params.maskSizeUm = 2.0;
params.maskInnerRatio = 0.45;
params.gratingPitchUm = 0.8;
params.gratingDuty = 0.50;

params.lensType = 'Circular';
params.projNA = 0.25;
params.lensInner = 0.35;
params.customPupilMask = lithography_default_custom_pupil();
params.reduction = 4.0;

params.wavelengthNm = 193;
params.fieldSizeUm = 8.0;
params.defocusUm = 0.0;

params.condenserFocalMm = 60;
params.projectionFocalMm = 85;
params.sourceToCondenserMm = 60;
params.fieldToPupilMm = 85;
params.xySliceZMm = params.sourceToCondenserMm + params.condenserFocalMm + params.fieldToPupilMm;
params.rayDensity = 'Medium';
params.yzMode = 'Continuous';
params.yzView = 'Raw';
params.intensityNorm = 'XYZ';
params.autoYZ = false;
end
