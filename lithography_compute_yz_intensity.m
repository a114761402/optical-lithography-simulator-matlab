function yzData = lithography_compute_yz_intensity(params, result)
if nargin < 2 || isempty(result) || ~isfield(result, 'projectionRelay') || ~isfield(result, 'mask')
    result = lithography_run_physics(params);
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
yHalf = 1.12 * max([1.0, geom.condenserHalf, geom.projectionHalf, geom.maskHalf, geom.imageHalf, geom.sourceHalf]);
yAxis = linspace(-yHalf, yHalf, 320);
zAxis = linspace(geom.xMin, geom.xMax, 820);
intensity = zeros(numel(yAxis), numel(zAxis));

if strcmp(params.yzMode, 'Multi-point')
    intensity = multiPointYZ(params, geom, zAxis, yAxis);
else
    intensity = continuousYZ(params, result, geom, zAxis, yAxis);
end

rawIntensity = intensity;
[intensity, normalizationPeak] = lithography_normalize_intensity(rawIntensity, params, result);

yzData = struct();
yzData.zMm = zAxis;
yzData.yNorm = yAxis;
yzData.rawIntensity = rawIntensity;
yzData.intensity = intensity;
yzData.mode = params.yzMode;
yzData.view = params.yzView;
yzData.normalizationMode = params.intensityNorm;
yzData.normalizationPeak = normalizationPeak;
yzData.planes = struct( ...
    'source', geom.zSourcePlane, ...
    'condenser', geom.zCondenser, ...
    'field', geom.zField, ...
    'projection1', geom.zProjection1, ...
    'pupil', geom.zPupil, ...
    'projection2', geom.zProjection2, ...
    'image', geom.zImage);
yzData.labels = struct( ...
    'condenser', 'Condenser Lens', ...
    'fieldElement', params.maskType, ...
    'projection', 'Projection Lenses');
end

function intensity = continuousYZ(params, result, geom, zAxis, yAxis)
intensity = zeros(numel(yAxis), numel(zAxis));
sigmaY = 0.030 * max(abs(yAxis));

[sourceY, sourceW] = continuousSourceProfile(params, geom);
[condenserY, condenserW] = condenserApertureProfile(params, geom);

for k = 1:numel(sourceY)
    ySource = sourceY(k);
    for n = 1:numel(condenserY)
        yLens = condenserY(n);
        weight = sourceW(k) * condenserW(n);
        if weight <= 0
            continue;
        end
        sourceDistance = max(geom.zCondenser - geom.zSourcePlane, eps);
        propagationDistance = geom.zField - geom.zCondenser;
        focalLength = max(params.condenserFocalMm, eps);
        slopeIn = (yLens - ySource) / sourceDistance;
        slopeOut = slopeIn - (yLens / focalLength);
        yField = yLens + slopeOut * propagationDistance;
        intensity = accumulatePolyline(intensity, zAxis, yAxis, ...
            [geom.zSourcePlane geom.zCondenser geom.zField], ...
            [ySource yLens yField], weight, sigmaY);
    end
end

[objectY, objectW] = maskTransmissionProfile(result, geom);

if strcmp(params.yzView, 'Transmitted')
    [pupilY, pupilW] = projectionPupilProfile(params, geom);
    for k = 1:numel(objectY)
        yField = objectY(k);
        for n = 1:numel(pupilY)
            weight = objectW(k) * pupilW(n);
            if weight <= 0
                continue;
            end
            path = lithography_projection_ray_path(params, geom, yField, pupilY(n));
            intensity = accumulatePolyline(intensity, zAxis, yAxis, path.zNodes, path.yNodes, weight, sigmaY);
        end
    end
else
    [rawPupilY, rawPupilW] = openProjectionProfile(geom);
    [actualPupilY, actualPupilW] = projectionPupilProfile(params, geom);
    for k = 1:numel(objectY)
        yField = objectY(k);
        for n = 1:numel(rawPupilY)
            weight = objectW(k) * rawPupilW(n);
            if weight <= 0
                continue;
            end
            path = lithography_projection_ray_path(params, geom, yField, rawPupilY(n));
            intensity = accumulatePolyline(intensity, zAxis, yAxis, path.preZ, path.preY, weight, sigmaY);
        end
        for n = 1:numel(actualPupilY)
            weight = objectW(k) * actualPupilW(n);
            if weight <= 0
                continue;
            end
            path = lithography_projection_ray_path(params, geom, yField, actualPupilY(n));
            intensity = accumulatePolyline(intensity, zAxis, yAxis, path.postZ, path.postY, weight, sigmaY);
        end
    end
end
end

function intensity = multiPointYZ(params, geom, zAxis, yAxis)
intensity = zeros(numel(yAxis), numel(zAxis));
sigmaY = blurWidth(params, max(abs(yAxis)));

sourceHeights = sourceHeightsForSketch(params);
lensHeights = illuminationRayHeights(params, geom);
illuminationWeight = 1 / max(1, numel(sourceHeights) * numel(lensHeights));

for k = 1:numel(sourceHeights)
    ySource = sourceHeights(k);
    for n = 1:numel(lensHeights)
        yLens = lensHeights(n);
        sourceDistance = max(geom.zCondenser - geom.zSourcePlane, eps);
        propagationDistance = geom.zField - geom.zCondenser;
        focalLength = max(params.condenserFocalMm, eps);
        slopeIn = (yLens - ySource) / sourceDistance;
        slopeOut = slopeIn - (yLens / focalLength);
        yField = yLens + slopeOut * propagationDistance;
        intensity = accumulatePolyline(intensity, zAxis, yAxis, ...
            [geom.zSourcePlane geom.zCondenser geom.zField], ...
            [ySource yLens yField], illuminationWeight, sigmaY);
    end
end

objectHeights = linspace(-0.80 * geom.maskHalf, 0.80 * geom.maskHalf, rayDensityCount(params, 3, 5, 7));

if strcmp(params.yzView, 'Transmitted')
    pupilHeights = projectionRayHeights(params, geom);
    imagingWeight = 1 / max(1, numel(objectHeights) * numel(pupilHeights));
    for k = 1:numel(objectHeights)
        yField = objectHeights(k);
        for n = 1:numel(pupilHeights)
            path = lithography_projection_ray_path(params, geom, yField, pupilHeights(n));
            intensity = accumulatePolyline(intensity, zAxis, yAxis, path.zNodes, path.yNodes, imagingWeight, sigmaY);
        end
    end
else
    rawPupilHeights = openProjectionRayHeights(params, geom);
    transmittedPupilHeights = projectionRayHeights(params, geom);
    preWeight = 1 / max(1, numel(objectHeights) * numel(rawPupilHeights));
    postWeight = 1 / max(1, numel(objectHeights) * numel(transmittedPupilHeights));
    for k = 1:numel(objectHeights)
        yField = objectHeights(k);
        for n = 1:numel(rawPupilHeights)
            path = lithography_projection_ray_path(params, geom, yField, rawPupilHeights(n));
            intensity = accumulatePolyline(intensity, zAxis, yAxis, path.preZ, path.preY, preWeight, sigmaY);
        end
        for n = 1:numel(transmittedPupilHeights)
            path = lithography_projection_ray_path(params, geom, yField, transmittedPupilHeights(n));
            intensity = accumulatePolyline(intensity, zAxis, yAxis, path.postZ, path.postY, postWeight, sigmaY);
        end
    end
end
end

function intensity = accumulatePolyline(intensity, zAxis, yAxis, zNodes, yNodes, weight, sigmaY)
for seg = 1:(numel(zNodes) - 1)
    z1 = zNodes(seg);
    z2 = zNodes(seg + 1);
    y1 = yNodes(seg);
    y2 = yNodes(seg + 1);
    if z2 == z1
        continue;
    end
    idx = find(zAxis >= min(z1, z2) & zAxis <= max(z1, z2));
    if isempty(idx)
        continue;
    end
    t = (zAxis(idx) - z1) / (z2 - z1);
    yLine = y1 + t * (y2 - y1);
    profile = exp(-0.5 * ((yAxis(:) - yLine(:)') / sigmaY).^2);
    intensity(:, idx) = intensity(:, idx) + weight * profile;
end
end

function geom = propagationGeometry(params, projectionRelay)
geom = lithography_projection_geometry(params, projectionRelay);
geom.sourceHalf = sourceDisplayHalf(params);
geom.condenserHalf = clampValue(max([0.82, geom.sourceHalf + 0.16, geom.maskHalf + 0.12]), 0.82, 1.05);
end

function [yValues, weights] = continuousSourceProfile(params, geom)
if isNearPointSource(params)
    yValues = params.pointSourceV;
    weights = 1;
    return;
end

count = 61;
switch params.sourceType
    case {'Circular', 'Square', 'Annular', 'Dipole X', 'Dipole Y'}
        yValues = linspace(-geom.sourceHalf, geom.sourceHalf, count);
    case 'Quadrupole'
        yValues = linspace(-geom.sourceHalf, geom.sourceHalf, 81);
    otherwise
        yValues = linspace(-geom.sourceHalf, geom.sourceHalf, count);
end

switch params.sourceType
    case 'Circular'
        physicalY = (params.sourceOuter / max(geom.sourceHalf, eps)) * yValues;
        weights = sqrt(max(params.sourceOuter^2 - physicalY.^2, 0));
    case 'Square'
        weights = double(abs(yValues) <= geom.sourceHalf);
    case 'Annular'
        physicalY = (params.sourceOuter / max(geom.sourceHalf, eps)) * yValues;
        outerTerm = sqrt(max(params.sourceOuter^2 - physicalY.^2, 0));
        innerTerm = sqrt(max(params.sourceInner^2 - physicalY.^2, 0));
        weights = max(outerTerm - innerTerm, 0);
    case 'Dipole X'
        physicalY = (params.sourceOuter / max(geom.sourceHalf, eps)) * yValues;
        weights = 2 * sqrt(max(params.sourceOuter^2 - physicalY.^2, 0));
    case 'Dipole Y'
        physicalShift = 0.5 * params.quadSeparation;
        displayShift = clampValue(0.72 * physicalShift, 0.12, 0.72);
        scale = physicalShift / max(displayShift, eps);
        physicalY = scale * yValues;
        weights = sqrt(max(params.sourceOuter^2 - (physicalY - physicalShift).^2, 0)) + ...
                  sqrt(max(params.sourceOuter^2 - (physicalY + physicalShift).^2, 0));
    case 'Quadrupole'
        sigma = 0.10;
        physicalShift = params.quadSeparation / sqrt(2);
        displayShift = clampValue(0.72 * params.quadSeparation, 0.22, 0.72);
        scale = physicalShift / max(displayShift, eps);
        physicalY = scale * yValues;
        weights = exp(-0.5 * ((physicalY - physicalShift) / sigma).^2) + ...
                  exp(-0.5 * ((physicalY + physicalShift) / sigma).^2);
    case 'Freeform'
        if isfield(params, 'customSourceMask') && ~isempty(params.customSourceMask)
            denseY = linspace(-geom.sourceHalf, geom.sourceHalf, size(params.customSourceMask, 1));
            rowWeights = sum(double(params.customSourceMask), 2);
            yValues = linspace(-geom.sourceHalf, geom.sourceHalf, count);
            weights = interp1(denseY, rowWeights(:), yValues, 'linear', 0);
        else
            weights = ones(size(yValues));
        end
    otherwise
        weights = ones(size(yValues));
end

[yValues, weights] = normalizeProfile(yValues, weights);
end

function [yValues, weights] = condenserApertureProfile(params, geom)
apertureHalf = clampValue(params.condenserAperture, 0.05, 1.0) * geom.condenserHalf;
yValues = linspace(-apertureHalf, apertureHalf, 25);
reduced = yValues / max(apertureHalf, eps);
weights = sqrt(max(1 - reduced.^2, 0));
[yValues, weights] = normalizeProfile(yValues, weights);
end

function [yValues, weights] = maskTransmissionProfile(result, geom)
maskProfile = sum(result.mask, 2);
yDense = linspace(-geom.maskHalf, geom.maskHalf, numel(maskProfile));
yValues = linspace(-geom.maskHalf, geom.maskHalf, 61);
weights = interp1(yDense, maskProfile(:), yValues, 'linear', 0);
[yValues, weights] = normalizeProfile(yValues, weights);
end

function [yValues, weights] = projectionPupilProfile(params, geom)
yValues = linspace(-0.98 * geom.projectionHalf, 0.98 * geom.projectionHalf, 31);
normalizedY = yValues / max(geom.projectionHalf, eps);

switch params.lensType
    case 'Circular'
        weights = sqrt(max(1 - normalizedY.^2, 0));
    case 'Annular'
        outerTerm = sqrt(max(1 - normalizedY.^2, 0));
        innerTerm = sqrt(max(params.lensInner^2 - normalizedY.^2, 0));
        weights = max(outerTerm - innerTerm, 0);
    case 'Square'
        weights = double(abs(normalizedY) <= 1);
    case 'Diamond'
        weights = max(1 - abs(normalizedY), 0);
    case 'Horizontal Slit'
        slitHalf = clampValue(params.lensInner, 0.03, 0.90);
        weights = double(abs(normalizedY) <= slitHalf);
    case 'Vertical Slit'
        weights = double(abs(normalizedY) <= 1);
    case 'Freeform'
        if isfield(params, 'customPupilMask') && ~isempty(params.customPupilMask)
            denseY = linspace(-geom.projectionHalf, geom.projectionHalf, size(params.customPupilMask, 1));
            rowWeights = sum(double(params.customPupilMask), 2);
            weights = interp1(denseY, rowWeights(:), yValues, 'linear', 0);
        else
            weights = sqrt(max(1 - normalizedY.^2, 0));
        end
    otherwise
        weights = sqrt(max(1 - normalizedY.^2, 0));
end

[yValues, weights] = normalizeProfile(yValues, weights);
end

function [yValues, weights] = openProjectionProfile(geom)
yValues = linspace(-0.98 * geom.projectionHalf, 0.98 * geom.projectionHalf, 31);
normalizedY = yValues / max(geom.projectionHalf, eps);
weights = sqrt(max(1 - normalizedY.^2, 0));
[yValues, weights] = normalizeProfile(yValues, weights);
end

function heights = sourceHeightsForSketch(params)
if isNearPointSource(params)
    heights = params.pointSourceV;
    return;
end

switch params.sourceType
    case 'Point'
        heights = params.pointSourceV;
    case 'Circular'
        outer = clampValue(0.85 * params.sourceOuter, 0.08, 0.82);
        heights = linspace(-outer, outer, rayDensityCount(params, 3, 5, 7));
    case 'Square'
        outer = clampValue(0.85 * params.sourceOuter, 0.08, 0.82);
        heights = linspace(-outer, outer, rayDensityCount(params, 3, 5, 7));
    case 'Annular'
        outer = clampValue(0.80 * params.sourceOuter, 0.22, 0.82);
        inner = clampValue(0.80 * params.sourceInner, 0.08, outer - 0.08);
        sideCount = max(2, ceil(rayDensityCount(params, 4, 6, 8) / 2));
        heights = [linspace(-outer, -inner, sideCount), linspace(inner, outer, sideCount)];
    case 'Dipole X'
        heights = [0 0];
    case 'Dipole Y'
        sep = clampValue(0.36 * params.quadSeparation, 0.12, 0.72);
        heights = [-sep sep];
    case 'Quadrupole'
        sep = clampValue(0.72 * params.quadSeparation, 0.22, 0.72);
        spread = linspace(-0.07, 0.07, rayDensityCount(params, 2, 3, 4));
        heights = sort([sep + spread, -sep + spread]);
    case 'Freeform'
        if isfield(params, 'customSourceMask') && ~isempty(params.customSourceMask)
            denseY = linspace(-sourceDisplayHalf(params), sourceDisplayHalf(params), size(params.customSourceMask, 1));
            rowWeights = sum(double(params.customSourceMask), 2);
            active = rowWeights > 0.08 * max(rowWeights(:));
            activeY = denseY(active);
            if isempty(activeY)
                heights = 0;
            else
                sampleCount = rayDensityCount(params, 3, 5, 7);
                heights = interp1(linspace(0, 1, numel(activeY)), activeY, ...
                    linspace(0, 1, sampleCount), 'linear');
            end
        else
            heights = linspace(-0.45, 0.45, rayDensityCount(params, 3, 5, 7));
        end
    otherwise
        heights = linspace(-0.45, 0.45, rayDensityCount(params, 3, 5, 7));
end
end

function heights = illuminationRayHeights(params, geom)
apertureHalf = clampValue(params.condenserAperture, 0.05, 1.0) * geom.condenserHalf;
if isNearPointSource(params)
    heights = linspace(-0.72 * apertureHalf, 0.72 * apertureHalf, rayDensityCount(params, 3, 5, 7));
else
    heights = linspace(-0.68 * apertureHalf, 0.68 * apertureHalf, rayDensityCount(params, 2, 3, 5));
end
end

function lensHeights = projectionRayHeights(params, geom)
densityCount = rayDensityCount(params, 3, 5, 7);

switch params.lensType
    case 'Annular'
        innerHalf = clampValue(params.lensInner * geom.projectionHalf, 0.10, 0.90 * geom.projectionHalf);
        outerHalf = 0.90 * geom.projectionHalf;
        sideCount = max(2, ceil(densityCount / 2));
        lensHeights = [linspace(-outerHalf, -innerHalf, sideCount), linspace(innerHalf, outerHalf, sideCount)];
    case 'Square'
        lensHeights = linspace(-0.90 * geom.projectionHalf, 0.90 * geom.projectionHalf, densityCount);
    case 'Diamond'
        lensHeights = linspace(-0.82 * geom.projectionHalf, 0.82 * geom.projectionHalf, densityCount);
    case 'Horizontal Slit'
        slitHalf = clampValue(params.lensInner, 0.03, 0.90) * geom.projectionHalf;
        lensHeights = linspace(-slitHalf, slitHalf, densityCount);
    case 'Vertical Slit'
        lensHeights = linspace(-0.90 * geom.projectionHalf, 0.90 * geom.projectionHalf, densityCount);
    case 'Freeform'
        if isfield(params, 'customPupilMask') && ~isempty(params.customPupilMask)
            denseY = linspace(-geom.projectionHalf, geom.projectionHalf, size(params.customPupilMask, 1));
            rowWeights = sum(double(params.customPupilMask), 2);
            active = rowWeights > 0.10 * max(rowWeights(:));
            activeY = denseY(active);
            if isempty(activeY)
                lensHeights = 0;
            else
                lensHeights = interp1(linspace(0, 1, numel(activeY)), activeY, linspace(0, 1, densityCount), 'linear');
            end
        else
            lensHeights = linspace(-0.70 * geom.projectionHalf, 0.70 * geom.projectionHalf, densityCount);
        end
    otherwise
        lensHeights = linspace(-0.70 * geom.projectionHalf, 0.70 * geom.projectionHalf, densityCount);
end
end

function lensHeights = openProjectionRayHeights(params, geom)
densityCount = rayDensityCount(params, 3, 5, 7);
lensHeights = linspace(-0.70 * geom.projectionHalf, 0.70 * geom.projectionHalf, densityCount);
end

function sourceHalf = sourceDisplayHalf(params)
if isNearPointSource(params)
    sourceHalf = max(0.08, sqrt(params.pointSourceU^2 + params.pointSourceV^2) + 0.08);
    return;
end

switch params.sourceType
    case {'Circular', 'Square', 'Dipole X'}
        sourceHalf = clampValue(0.85 * params.sourceOuter, 0.08, 0.82);
    case 'Annular'
        sourceHalf = clampValue(0.80 * params.sourceOuter, 0.22, 0.82);
    case 'Dipole Y'
        sourceHalf = clampValue(0.36 * params.quadSeparation + 0.85 * params.sourceOuter, 0.18, 0.82);
    case 'Quadrupole'
        sourceHalf = clampValue(0.72 * params.quadSeparation, 0.22, 0.72) + 0.09;
    case 'Freeform'
        sourceHalf = lithography_custom_source_half(params);
    otherwise
        sourceHalf = max(0.45, sqrt(params.pointSourceU^2 + params.pointSourceV^2) + 0.08);
end
end

function [yValues, weights] = normalizeProfile(yValues, weights)
weights = max(weights(:)', 0);
if all(weights <= 0)
    yValues = 0;
    weights = 1;
    return;
end
weights = weights / sum(weights);
if numel(yValues) > 1
    active = weights > max(weights) * 1e-3;
    yValues = yValues(active);
    weights = weights(active);
    weights = weights / sum(weights);
end
end

function projection = buildProjectionRelay(params)
projection = struct();
projection.modelType = 'equivalent-4f-relay';
projection.imageDistanceMm = params.projectionFocalMm;
projection.magnification = -1 / params.reduction;
projection.absMagnification = abs(projection.magnification);
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

function count = rayDensityCount(params, lowCount, mediumCount, highCount)
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

function width = blurWidth(params, yHalf)
switch params.rayDensity
    case 'Low'
        width = 0.055 * yHalf;
    case 'High'
        width = 0.030 * yHalf;
    case 'Ultra High'
        width = 0.022 * yHalf;
    otherwise
        width = 0.040 * yHalf;
end
end

function tf = isNearPointSource(params)
tf = strcmp(params.sourceType, 'Point') || ...
    (strcmp(params.sourceType, 'Circular') && params.sourceOuter <= 0.05) || ...
    (strcmp(params.sourceType, 'Square') && params.sourceOuter <= 0.05) || ...
    (strcmp(params.sourceType, 'Annular') && params.sourceOuter <= 0.05) || ...
    (any(strcmp(params.sourceType, {'Dipole X', 'Dipole Y'})) && ...
        params.sourceOuter <= 0.03 && params.quadSeparation <= 0.06);
end
