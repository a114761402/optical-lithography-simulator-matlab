function slice = lithography_compute_xy_slice(params, result, zMm, sharedPeak)
if nargin < 2 || isempty(result) || ~isfield(result, 'projectionRelay') || ~isfield(result, 'mask')
    result = lithography_run_physics(params);
end

if nargin < 3 || ~isfinite(zMm)
    zMm = result.projectionRelay.imageDistanceMm;
end
if nargin < 4
    sharedPeak = [];
end

if ~isfield(params, 'yzMode') || isempty(params.yzMode)
    params.yzMode = 'Continuous';
end
if ~isfield(params, 'yzView') || isempty(params.yzView)
    params.yzView = 'Raw';
end
if ~isfield(params, 'intensityNorm') || isempty(params.intensityNorm)
    params.intensityNorm = 'Local';
end

geom = propagationGeometry(params, result.projectionRelay);
zSelected = min(max(zMm, geom.zSourcePlane), geom.zSliceMax);

specialSlice = specialPlaneSlice(params, result, geom, zSelected, sharedPeak);
if ~isempty(specialSlice)
    slice = specialSlice;
    return;
end

if strcmp(params.yzMode, 'Multi-point')
    mode = 'Multi-point';
    gridCount = 181;
else
    mode = 'Continuous';
    gridCount = 201;
end

if zSelected <= geom.zField
    slice = lithography_compute_illumination_xy_slice(params, geom, zSelected, mode, gridCount);
    [slice.intensity, slice.normalizationPeak] = lithography_normalize_intensity(slice.rawIntensity, params, result, sharedPeak);
    slice.normalizationMode = params.intensityNorm;
    return;
end

if zSelected < geom.zPupil
    slice = lithography_pre_lens_wave_slice(params, result, zSelected, sharedPeak);
    return;
end

slice = lithography_post_pupil_wave_slice(params, result, zSelected, sharedPeak);
return;

[coeffA, coeffB, halfA, halfB, stageLabel] = stageCoefficients(params, geom, zSelected);
axisHalf = 1.18 * max(0.10, abs(coeffA) * halfA + abs(coeffB) * halfB);
axisValues = linspace(-axisHalf, axisHalf, gridCount);
[mapA, mapB] = densityMaps(params, result, geom, zSelected, mode, axisValues);

scaledA = scaledDensityMap(mapA, axisValues, coeffA);
scaledB = scaledDensityMap(mapB, axisValues, coeffB);
rawIntensity = conv2(scaledA, scaledB, 'same');
[intensity, normalizationPeak] = lithography_normalize_intensity(rawIntensity, params, result, sharedPeak);

slice = struct();
slice.axis = axisValues;
slice.rawIntensity = rawIntensity;
slice.intensity = intensity;
slice.zMm = zSelected;
slice.stageLabel = stageLabel;
slice.mode = mode;
slice.titleText = '';
slice.xlabelText = 'normalized x';
slice.ylabelText = 'normalized y';
slice.normalizationMode = params.intensityNorm;
slice.normalizationPeak = normalizationPeak;
slice.isExact = false;
end

function slice = specialPlaneSlice(params, result, geom, zSelected, sharedPeak)
slice = [];
planeTolerance = specialPlaneTolerance(geom);

if abs(zSelected - geom.zSourcePlane) <= planeTolerance
    slice = buildExactPlaneSlice(result.sourceRaw, zSelected, 'source plane', ...
        'Source at source plane', [], false, params, result, sharedPeak);
    return;
end

if abs(zSelected - geom.zField) <= planeTolerance
    slice = buildExactPlaneSlice(result.mask, zSelected, 'field plane', ...
        'Mask transmission at field plane', [], false, params, result, sharedPeak);
    return;
end

if abs(zSelected - geom.zPupil) <= planeTolerance
    % For beam-path XY slices, use the same local wave model at the pupil
    % so z = z_pupil and z = z_pupil + dz remain visually continuous.
    slice = lithography_post_pupil_wave_slice(params, result, geom.zPupil, sharedPeak);
    slice.zMm = zSelected;
    slice.stageLabel = 'pupil plane local';
    return;
end

if abs(zSelected - geom.zImage) <= planeTolerance
    slice = buildExactPlaneSlice(result.imageRaw, zSelected, 'image plane', ...
        'Detector image at image plane', [], true, params, result, sharedPeak);
end
end

function tolerance = specialPlaneTolerance(geom)
tolerance = 1e-6;
end

function slice = buildExactPlaneSlice(intensityRaw, zSelected, stageLabel, titleText, axisExtent, useSharedNormalization, params, result, sharedPeak)
if nargin < 5 || isempty(axisExtent) || ~isscalar(axisExtent) || ~isfinite(axisExtent) || axisExtent <= 0
    axisExtent = 1;
end
if nargin < 6
    useSharedNormalization = false;
end

if useSharedNormalization && ~(isfield(params, 'intensityNorm') && strcmp(params.intensityNorm, 'XYZ'))
    [displayIntensity, normalizationPeak] = lithography_normalize_intensity(intensityRaw, params, result, sharedPeak);
    normalizationMode = params.intensityNorm;
else
    [displayIntensity, normalizationPeak] = lithography_normalize_intensity(intensityRaw, struct('intensityNorm', 'Local'), result, []);
    normalizationMode = 'Local';
end

axisValues = linspace(-axisExtent, axisExtent, size(intensityRaw, 1));
slice = struct();
slice.axis = axisValues;
slice.rawIntensity = intensityRaw;
slice.intensity = displayIntensity;
slice.zMm = zSelected;
slice.stageLabel = stageLabel;
slice.mode = 'Exact plane';
slice.titleText = titleText;
slice.xlabelText = 'normalized x';
slice.ylabelText = 'normalized y';
slice.normalizationMode = normalizationMode;
slice.normalizationPeak = normalizationPeak;
slice.isExact = true;
end

function [coeffA, coeffB, halfA, halfB, stageLabel] = stageCoefficients(params, geom, zSelected)
if zSelected <= geom.zField
    stageLabel = 'illumination';
    apertureHalf = clampValue(params.condenserAperture, 0.05, 1.0) * geom.condenserHalf;
    if zSelected <= geom.zCondenser
        t = (zSelected - geom.zSourcePlane) / max(geom.zCondenser - geom.zSourcePlane, eps);
        coeffA = 1 - t;
        coeffB = t;
    else
        dz = zSelected - geom.zCondenser;
        sourceDistance = max(geom.zCondenser - geom.zSourcePlane, eps);
        focalLength = max(params.condenserFocalMm, eps);
        coeffA = -dz / sourceDistance;
        coeffB = 1 + dz / sourceDistance - dz / focalLength;
    end
    halfA = geom.sourceHalf;
    halfB = apertureHalf;
else
    stageLabel = 'projection';
    if zSelected <= geom.zPupil
        alpha = (zSelected - geom.zField) / max(geom.zPupil - geom.zField, eps);
        coeffA = 1 - alpha;
        coeffB = alpha;
        halfA = geom.maskHalf;
        halfB = geom.projectionHalf;
    elseif zSelected <= geom.zImage
        beta = (zSelected - geom.zPupil) / max(geom.zImage - geom.zPupil, eps);
        coeffA = beta * geom.projection.magnification;
        coeffB = 1 - beta;
        halfA = geom.maskHalf;
        halfB = geom.projectionHalf;
        stageLabel = 'projection';
    else
        beta = (zSelected - geom.zPupil) / max(geom.zImage - geom.zPupil, eps);
        coeffA = beta * geom.projection.magnification;
        coeffB = 1 - beta;
        halfA = geom.maskHalf;
        halfB = geom.projectionHalf;
        stageLabel = 'after image';
    end
end
end

function [mapA, mapB] = densityMaps(params, result, geom, zSelected, mode, axisValues)
if zSelected <= geom.zField
    mapA = sourceDensityMap(params, geom, mode, axisValues);
    mapB = condenserDensityMap(params, geom, mode, axisValues);
else
    mapA = maskDensityMap(params, result, geom, mode, axisValues);
    if strcmp(params.yzView, 'Raw')
        mapB = truePupilDensityMap(result, axisValues);
    else
        mapB = pupilDensityMap(params, geom, mode, axisValues);
    end
end
end

function map = scaledDensityMap(baseMap, axisValues, scale)
if abs(scale) < 1e-9
    map = zeros(size(baseMap));
    center = ceil(size(baseMap, 1) / 2);
    map(center, center) = 1;
    return;
end

[X, Y] = meshgrid(axisValues, axisValues);
sourceAxis = axisValues;
map = interp2(sourceAxis, sourceAxis, baseMap, X / scale, Y / scale, 'linear', 0);
map = safeNormalize(map);
end

function map = sourceDensityMap(params, geom, mode, axisValues)
axisHalf = max(abs(axisValues));
[X, Y] = meshgrid(axisValues, axisValues);

if strcmp(mode, 'Continuous')
    map = sourceShapeValues(X, Y, params, geom);
else
    pointCount = pointDensityCount(params, 5, 7, 9);
    gridValues = linspace(-axisHalf, axisHalf, pointCount);
    [Xs, Ys] = meshgrid(gridValues, gridValues);
    sampled = sourceShapeValues(Xs, Ys, params, geom);
    active = sampled > 0.10 * max(sampled(:));
    map = sparsePointMap(axisValues, Xs(active), Ys(active), sampled(active), 0.045 * axisHalf);
end
map = safeNormalize(map);
end

function map = condenserDensityMap(params, geom, mode, axisValues)
axisHalf = clampValue(params.condenserAperture, 0.05, 1.0) * geom.condenserHalf;
[X, Y] = meshgrid(axisValues, axisValues);

if strcmp(mode, 'Continuous')
    map = double(X.^2 + Y.^2 <= axisHalf^2);
else
    pointCount = pointDensityCount(params, 5, 7, 9);
    gridValues = linspace(-axisHalf, axisHalf, pointCount);
    [Xs, Ys] = meshgrid(gridValues, gridValues);
    active = Xs.^2 + Ys.^2 <= axisHalf^2;
    map = sparsePointMap(axisValues, Xs(active), Ys(active), ones(nnz(active), 1), 0.040 * axisHalf);
end
map = safeNormalize(map);
end

function map = maskDensityMap(params, result, geom, mode, axisValues)
axisHalf = geom.maskHalf;
[X, Y] = meshgrid(axisValues, axisValues);
maskAxis = linspace(-axisHalf, axisHalf, size(result.mask, 1));

if strcmp(mode, 'Continuous')
    map = interp2(maskAxis, maskAxis, result.mask, X, Y, 'linear', 0);
else
    pointCount = pointDensityCount(params, 6, 9, 12);
    sampleAxis = linspace(-axisHalf, axisHalf, pointCount);
    [Xs, Ys] = meshgrid(sampleAxis, sampleAxis);
    sampled = interp2(maskAxis, maskAxis, result.mask, Xs, Ys, 'linear', 0);
    active = sampled > 0.25;
    map = sparsePointMap(axisValues, Xs(active), Ys(active), sampled(active), 0.035 * axisHalf);
end
map = safeNormalize(map);
end

function map = pupilDensityMap(params, geom, mode, axisValues)
axisHalf = geom.projectionHalf;
[X, Y] = meshgrid(axisValues, axisValues);
normalizedX = X / max(axisHalf, eps);
normalizedY = Y / max(axisHalf, eps);

if strcmp(mode, 'Continuous')
    map = pupilShapeValues(normalizedX, normalizedY, params);
else
    pointCount = pointDensityCount(params, 5, 7, 9);
    sampleAxis = linspace(-axisHalf, axisHalf, pointCount);
    [Xs, Ys] = meshgrid(sampleAxis, sampleAxis);
    sampled = pupilShapeValues(Xs / max(axisHalf, eps), Ys / max(axisHalf, eps), params);
    active = sampled > 0.1 * max(sampled(:));
    map = sparsePointMap(axisValues, Xs(active), Ys(active), sampled(active), 0.040 * axisHalf);
end
map = safeNormalize(map);
end

function map = truePupilDensityMap(result, axisValues)
[X, Y] = meshgrid(axisValues, axisValues);
pupilAxis = linspace(-result.freqExtent, result.freqExtent, size(result.pupil, 1));
map = interp2(pupilAxis, pupilAxis, result.pupil, X, Y, 'linear', 0);
map = safeNormalize(map);
end

function values = sourceShapeValues(X, Y, params, geom)
switch params.sourceType
    case 'Point'
        values = exp(-(((X - params.pointSourceU) / max(geom.sourceHalf, eps)).^2 + ...
                       ((Y - params.pointSourceV) / max(geom.sourceHalf, eps)).^2) / 0.002);

    case 'Circular'
        scale = params.sourceOuter / max(geom.sourceHalf, eps);
        values = double((scale * X).^2 + (scale * Y).^2 <= params.sourceOuter^2);

    case 'Square'
        scale = params.sourceOuter / max(geom.sourceHalf, eps);
        values = double(max(abs(scale * X), abs(scale * Y)) <= params.sourceOuter);

    case 'Annular'
        scale = params.sourceOuter / max(geom.sourceHalf, eps);
        radial = sqrt((scale * X).^2 + (scale * Y).^2);
        values = double(radial <= params.sourceOuter & radial >= params.sourceInner);

    case 'Dipole X'
        lobeHalf = clampValue(0.85 * params.sourceOuter, 0.08, 0.82);
        shift = min(0.5 * params.quadSeparation, max(geom.sourceHalf - lobeHalf, 0.05));
        values = double((X - shift).^2 + Y.^2 <= lobeHalf^2) + ...
                 double((X + shift).^2 + Y.^2 <= lobeHalf^2);

    case 'Dipole Y'
        lobeHalf = clampValue(0.85 * params.sourceOuter, 0.08, 0.82);
        shift = min(0.5 * params.quadSeparation, max(geom.sourceHalf - lobeHalf, 0.05));
        values = double(X.^2 + (Y - shift).^2 <= lobeHalf^2) + ...
                 double(X.^2 + (Y + shift).^2 <= lobeHalf^2);

    case 'Quadrupole'
        sigma = 0.10;
        physicalShift = params.quadSeparation / sqrt(2);
        displayShift = clampValue(0.72 * params.quadSeparation, 0.22, 0.72);
        scale = physicalShift / max(displayShift, eps);
        physicalX = scale * X;
        physicalY = scale * Y;
        values = zeros(size(X));
        centers = [ physicalShift,  physicalShift;
                    physicalShift, -physicalShift;
                   -physicalShift,  physicalShift;
                   -physicalShift, -physicalShift];
        for idx = 1:size(centers, 1)
            values = values + exp(-((physicalX - centers(idx, 1)).^2 + (physicalY - centers(idx, 2)).^2) / (2 * sigma^2));
        end
    case 'Freeform'
        values = lithography_custom_source_values(X / max(geom.sourceHalf, eps), ...
            Y / max(geom.sourceHalf, eps), params);

    otherwise
        scale = params.sourceOuter / max(geom.sourceHalf, eps);
        values = double((scale * X).^2 + (scale * Y).^2 <= params.sourceOuter^2);
end
end

function values = pupilShapeValues(U, V, params)
radial = sqrt(U.^2 + V.^2);
switch params.lensType
    case 'Circular'
        values = double(radial <= 1);
    case 'Annular'
        values = double(radial <= 1 & radial >= params.lensInner);
    case 'Square'
        values = double(abs(U) <= 1 & abs(V) <= 1);
    case 'Diamond'
        values = double(abs(U) + abs(V) <= 1);
    case 'Horizontal Slit'
        slitHalf = clampValue(params.lensInner, 0.03, 0.90);
        values = double(abs(V) <= slitHalf & abs(U) <= 1);
    case 'Vertical Slit'
        slitHalf = clampValue(params.lensInner, 0.03, 0.90);
        values = double(abs(U) <= slitHalf & abs(V) <= 1);
    case 'Freeform'
        values = lithography_custom_pupil_values(U, V, params);
    otherwise
        values = double(radial <= 1);
end
end

function map = sparsePointMap(axisValues, xPoints, yPoints, weights, sigma)
[X, Y] = meshgrid(axisValues, axisValues);
map = zeros(size(X));
if isempty(weights)
    center = ceil(size(map, 1) / 2);
    map(center, center) = 1;
    return;
end
weights = weights(:);
weights = weights / max(sum(weights), eps);
sigma = max(sigma, 0.015 * max(abs(axisValues)));
for idx = 1:numel(weights)
    map = map + weights(idx) * exp(-0.5 * (((X - xPoints(idx)) / sigma).^2 + ((Y - yPoints(idx)) / sigma).^2));
end
end

function count = pointDensityCount(params, lowCount, mediumCount, highCount)
ultraHighCount = highCount + max(2, ceil(0.4 * highCount));
switch params.rayDensity
    case 'Low'
        count = lowCount;
    case 'High'
        count = highCount;
    case 'Ultra High'
        count = ultraHighCount;
    otherwise
        count = mediumCount;
end
end

function geom = propagationGeometry(params, projectionRelay)
geom = lithography_projection_geometry(params, projectionRelay);
geom.sourceHalf = sourceDisplayHalf(params);
geom.condenserHalf = clampValue(max([0.82, geom.sourceHalf + 0.16, geom.maskHalf + 0.12]), 0.82, 1.05);
end

function sourceHalf = sourceDisplayHalf(params)
if isNearPointSource(params)
    sourceHalf = max(0.08, sqrt(params.pointSourceU^2 + params.pointSourceV^2) + 0.08);
    return;
end

switch params.sourceType
    case {'Circular', 'Square'}
        sourceHalf = clampValue(0.85 * params.sourceOuter, 0.08, 0.82);
    case 'Annular'
        sourceHalf = clampValue(0.80 * params.sourceOuter, 0.22, 0.82);
    case {'Dipole X', 'Dipole Y'}
        sourceHalf = clampValue(0.85 * params.sourceOuter + 0.5 * params.quadSeparation, 0.18, 0.82);
    case 'Quadrupole'
        sourceHalf = clampValue(0.72 * params.quadSeparation, 0.22, 0.72) + 0.09;
    case 'Freeform'
        sourceHalf = lithography_custom_source_half(params);
    otherwise
        sourceHalf = max(0.45, sqrt(params.pointSourceU^2 + params.pointSourceV^2) + 0.08);
end
end

function data = safeNormalize(data)
peak = max(data(:));
if peak > 0
    data = data / peak;
end
end

function value = clampValue(value, lowValue, highValue)
value = min(max(value, lowValue), highValue);
end

function tf = isNearPointSource(params)
tf = strcmp(params.sourceType, 'Point') || ...
    (strcmp(params.sourceType, 'Circular') && params.sourceOuter <= 0.05) || ...
    (strcmp(params.sourceType, 'Square') && params.sourceOuter <= 0.05) || ...
    (strcmp(params.sourceType, 'Annular') && params.sourceOuter <= 0.05);
end
