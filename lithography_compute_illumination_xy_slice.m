function slice = lithography_compute_illumination_xy_slice(params, geom, zSelected, mode, gridCount)
[coeffA, coeffB] = illuminationMixingCoefficients(params, geom, zSelected);
[sourceX, sourceY, sourceW] = sourcePointCloud(params, geom, mode);
[apertureX, apertureY, apertureW] = condenserPointCloud(params, geom, mode);

[xPoints, yPoints, weights] = combineRayPoints(coeffA, coeffB, ...
    sourceX, sourceY, sourceW, apertureX, apertureY, apertureW);

radiusMax = max(sqrt(xPoints.^2 + yPoints.^2));
axisHalf = max(0.12, 1.10 * radiusMax);
axisValues = linspace(-axisHalf, axisHalf, gridCount);
    intensity = pointCloudToImage(xPoints, yPoints, weights, axisValues, mode);

slice = struct();
slice.axis = axisValues;
slice.rawIntensity = intensity;
slice.intensity = intensity;
slice.zMm = zSelected;
slice.stageLabel = 'illumination';
slice.mode = mode;
slice.titleText = '';
slice.xlabelText = 'normalized x';
slice.ylabelText = 'normalized y';
slice.isExact = false;
end

function [coeffA, coeffB] = illuminationMixingCoefficients(params, geom, zSelected)
sourceDistance = max(geom.zCondenser - geom.zSourcePlane, eps);
apertureHalf = min(max(params.condenserAperture, 0.05), 1.0) * geom.condenserHalf;
if apertureHalf <= 0
    coeffA = 1;
    coeffB = 0;
    return;
end

if zSelected <= geom.zCondenser
    t = (zSelected - geom.zSourcePlane) / sourceDistance;
    coeffA = 1 - t;
    coeffB = t;
else
    dz = zSelected - geom.zCondenser;
    focalLength = max(params.condenserFocalMm, eps);
    coeffA = -dz / sourceDistance;
    coeffB = 1 + dz / sourceDistance - dz / focalLength;
end
end

function [xValues, yValues, weights] = sourcePointCloud(params, geom, mode)
supportHalf = sourceDisplayHalf(params);
sampleCount = cloudSampleCount(mode, 27, 45);
axisValues = linspace(-supportHalf, supportHalf, sampleCount);
[X, Y] = meshgrid(axisValues, axisValues);
weights = sourceShapeValues(X, Y, params, geom);
active = weights > max(weights(:)) * 1e-6;
xValues = X(active);
yValues = Y(active);
weights = weights(active);
weights = normalizeWeights(weights);
end

function [xValues, yValues, weights] = condenserPointCloud(params, geom, mode)
apertureHalf = min(max(params.condenserAperture, 0.05), 1.0) * geom.condenserHalf;
sampleCount = cloudSampleCount(mode, 29, 49);
axisValues = linspace(-apertureHalf, apertureHalf, sampleCount);
[X, Y] = meshgrid(axisValues, axisValues);
weights = double(X.^2 + Y.^2 <= apertureHalf^2);
active = weights > 0;
xValues = X(active);
yValues = Y(active);
weights = weights(active);
weights = normalizeWeights(weights);
end

function [xPoints, yPoints, weights] = combineRayPoints(coeffA, coeffB, ...
        sourceX, sourceY, sourceW, apertureX, apertureY, apertureW)
sourceX = sourceX(:);
sourceY = sourceY(:);
sourceW = sourceW(:);
apertureX = apertureX(:)';
apertureY = apertureY(:)';
apertureW = apertureW(:)';

xPoints = coeffA * sourceX + coeffB * apertureX;
yPoints = coeffA * sourceY + coeffB * apertureY;
weights = sourceW * apertureW;

xPoints = xPoints(:);
yPoints = yPoints(:);
weights = weights(:);
weights = normalizeWeights(weights);
end

function imageData = pointCloudToImage(xPoints, yPoints, weights, axisValues, mode)
gridSize = numel(axisValues);
delta = max(axisValues(2) - axisValues(1), eps);
origin = axisValues(1);

xIndex = (xPoints - origin) / delta + 1;
yIndex = (yPoints - origin) / delta + 1;

xFloor = floor(xIndex);
yFloor = floor(yIndex);
tx = xIndex - xFloor;
ty = yIndex - yFloor;

imageData = zeros(gridSize, gridSize);
imageData = imageData + splatWeights(xFloor,     yFloor,     (1 - tx) .* (1 - ty) .* weights, gridSize);
imageData = imageData + splatWeights(xFloor + 1, yFloor,     tx .* (1 - ty) .* weights, gridSize);
imageData = imageData + splatWeights(xFloor,     yFloor + 1, (1 - tx) .* ty .* weights, gridSize);
imageData = imageData + splatWeights(xFloor + 1, yFloor + 1, tx .* ty .* weights, gridSize);

if strcmp(mode, 'Continuous')
    sigmaPixels = 1.45;
else
    sigmaPixels = 1.80;
end
    imageData = conv2(imageData, gaussianKernel(sigmaPixels), 'same');
end

function imageData = splatWeights(ix, iy, weights, gridSize)
valid = ix >= 1 & ix <= gridSize & iy >= 1 & iy <= gridSize & weights > 0;
ix = ix(valid);
iy = iy(valid);
weights = weights(valid);
if isempty(weights)
    imageData = zeros(gridSize, gridSize);
    return;
end
linearIdx = sub2ind([gridSize, gridSize], iy, ix);
imageData = accumarray(linearIdx, weights, [gridSize * gridSize, 1], @sum, 0);
imageData = reshape(imageData, [gridSize, gridSize]);
end

function kernel = gaussianKernel(sigmaPixels)
radius = max(2, ceil(3 * sigmaPixels));
axisValues = -radius:radius;
[X, Y] = meshgrid(axisValues, axisValues);
kernel = exp(-0.5 * (X.^2 + Y.^2) / max(sigmaPixels^2, eps));
kernel = kernel / sum(kernel(:));
end

function values = sourceShapeValues(X, Y, params, geom)
switch params.sourceType
    case 'Point'
        values = exp(-(((X - params.pointSourceU) / max(geom.sourceHalf, eps)).^2 + ...
                       ((Y - params.pointSourceV) / max(geom.sourceHalf, eps)).^2) / 0.002);
    case 'Circular'
        values = double(X.^2 + Y.^2 <= geom.sourceHalf^2);
    case 'Square'
        values = double(max(abs(X), abs(Y)) <= geom.sourceHalf);
    case 'Annular'
        innerHalf = annularInnerHalf(params, geom.sourceHalf);
        radial = sqrt(X.^2 + Y.^2);
        values = double(radial <= geom.sourceHalf & radial >= innerHalf);
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
        sigma = 0.08;
        shift = min(0.78 * geom.sourceHalf, 0.72 * params.quadSeparation);
        values = zeros(size(X));
        centers = [ shift,  shift;
                    shift, -shift;
                   -shift,  shift;
                   -shift, -shift];
        for idx = 1:size(centers, 1)
            values = values + exp(-((X - centers(idx, 1)).^2 + (Y - centers(idx, 2)).^2) / (2 * sigma^2));
        end
    case 'Freeform'
        values = lithography_custom_source_values(X / max(geom.sourceHalf, eps), ...
            Y / max(geom.sourceHalf, eps), params);
    otherwise
        values = double(X.^2 + Y.^2 <= geom.sourceHalf^2);
end
end

function innerHalf = annularInnerHalf(params, outerHalf)
if params.sourceOuter <= 0
    innerHalf = 0;
else
    innerHalf = outerHalf * (params.sourceInner / params.sourceOuter);
end
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
    case 'Dipole X'
        sourceHalf = clampValue(0.85 * params.sourceOuter + 0.5 * params.quadSeparation, 0.18, 0.82);
    case 'Dipole Y'
        sourceHalf = clampValue(0.85 * params.sourceOuter + 0.5 * params.quadSeparation, 0.18, 0.82);
    case 'Quadrupole'
        sourceHalf = clampValue(0.72 * params.quadSeparation, 0.22, 0.72) + 0.09;
    case 'Freeform'
        sourceHalf = lithography_custom_source_half(params);
    otherwise
        sourceHalf = max(0.45, sqrt(params.pointSourceU^2 + params.pointSourceV^2) + 0.08);
end
end

function count = cloudSampleCount(mode, multiPointCount, continuousCount)
if strcmp(mode, 'Continuous')
    count = continuousCount;
else
    count = multiPointCount;
end
end

function weights = normalizeWeights(weights)
weights = weights(:);
total = sum(weights);
if total <= 0
    weights = 1;
else
    weights = weights / total;
end
end

function value = clampValue(value, lowValue, highValue)
value = min(max(value, lowValue), highValue);
end

function tf = isNearPointSource(params)
tf = strcmp(params.sourceType, 'Point') || ...
    (strcmp(params.sourceType, 'Circular') && params.sourceOuter <= 0.05) || ...
    (strcmp(params.sourceType, 'Square') && params.sourceOuter <= 0.05) || ...
    (strcmp(params.sourceType, 'Annular') && params.sourceOuter <= 0.05) || ...
    (any(strcmp(params.sourceType, {'Dipole X', 'Dipole Y'})) && ...
        params.sourceOuter <= 0.03 && params.quadSeparation <= 0.06);
end
