function slice = lithography_pre_lens_wave_slice(params, result, zSelected, sharedPeak)
if nargin < 2 || isempty(result) || ~isfield(result, 'projectionRelay') || ~isfield(result, 'mask')
    result = lithography_run_physics(params);
end
if nargin < 4
    sharedPeak = [];
end

geom = propagationGeometry(params, result.projectionRelay);
zSelected = min(max(zSelected, geom.zField), geom.zPupil);

N = params.gridSize;
fieldSizeM = params.fieldSizeUm * 1e-6;
dx = fieldSizeM / N;
x = ((0:N-1) - N/2) * dx;
[X, Y] = meshgrid(x, x);

condenserFocal = params.condenserFocalMm * 1e-3;
sourceToCondenser = params.sourceToCondenserMm * 1e-3;
lambda = params.wavelengthNm * 1e-9;
cutoff = params.projNA / lambda;
illuminationCurvature = (condenserFocal - sourceToCondenser) / max(condenserFocal^2, eps);
illuminationAngleScale = condenserFocal / max(sourceToCondenser, eps);
illuminationPhase = exp(1i * pi * illuminationCurvature * (X.^2 + Y.^2) / lambda);

rawIntensity = zeros(N, N);
[sourceU, sourceV, sourceW] = lithography_wave_source_samples(params, result);
lens1Phase = exp(-1i * pi * (X.^2 + Y.^2) / (lambda * max(geom.relayFocal1Mm, eps) * 1e-3));

for k = 1:numel(sourceW)
    fxShift = sourceU(k) * cutoff * illuminationAngleScale;
    fyShift = sourceV(k) * cutoff * illuminationAngleScale;
    fieldAfterMask = result.mask .* exp(1i * 2 * pi * (fxShift * X + fyShift * Y)) .* illuminationPhase;
    if zSelected <= geom.zProjection1
        propagated = lithography_wave_propagate(fieldAfterMask, lambda, dx, (zSelected - geom.zField) * 1e-3, 4);
    else
        atLens1 = lithography_wave_propagate(fieldAfterMask, lambda, dx, (geom.zProjection1 - geom.zField) * 1e-3, 4);
        afterLens1 = atLens1 .* lens1Phase;
        propagated = lithography_wave_propagate(afterLens1, lambda, dx, (zSelected - geom.zProjection1) * 1e-3, 4);
    end
    rawIntensity = rawIntensity + sourceW(k) * abs(propagated).^2;
end

if isRotationallySymmetricSetup(params)
    rawIntensity = radialAverageImage(rawIntensity);
end

[displayIntensity, normalizationPeak] = lithography_normalize_intensity(rawIntensity, params, result, sharedPeak);
axisExtent = max(abs(x(:)));
axisValues = x ./ max(axisExtent, eps);

slice = struct();
slice.axis = axisValues;
slice.rawIntensity = rawIntensity;
slice.intensity = displayIntensity;
slice.zMm = zSelected;
if zSelected < geom.zProjection1
    slice.stageLabel = 'projection pre-lens';
else
    slice.stageLabel = 'projection to pupil';
end
slice.mode = 'Wave';
slice.titleText = '';
slice.xlabelText = 'normalized x';
slice.ylabelText = 'normalized y';
slice.normalizationMode = params.intensityNorm;
slice.normalizationPeak = normalizationPeak;
slice.isExact = false;
end

function geom = propagationGeometry(params, projectionRelay)
geom = lithography_projection_geometry(params, projectionRelay);
end

function value = clampValue(value, lowValue, highValue)
value = min(max(value, lowValue), highValue);
end

function tf = isRotationallySymmetricSetup(params)
sourceSymmetric = any(strcmp(params.sourceType, {'Circular', 'Annular'}));
maskSymmetric = any(strcmp(params.maskType, {'Circular Aperture', 'Annular Aperture'}));
pointCentered = ~strcmp(params.sourceType, 'Point') || ...
    (abs(params.pointSourceU) < 1e-9 && abs(params.pointSourceV) < 1e-9);
tf = sourceSymmetric && maskSymmetric && pointCentered;
end

function radialImage = radialAverageImage(imageData)
N = size(imageData, 1);
center = (N + 1) / 2;
[X, Y] = meshgrid(1:N, 1:N);
R = round(sqrt((X - center).^2 + (Y - center).^2)) + 1;
radialMean = accumarray(R(:), imageData(:), [], @mean, 0);
radialImage = radialMean(R);
end
