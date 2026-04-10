function result = lithography_run_physics(params)
N = params.gridSize;
L = params.fieldSizeUm * 1e-6;
lambda = params.wavelengthNm * 1e-9;
dx = L / N;

condenserFocal = params.condenserFocalMm * 1e-3;
sourceToCondenser = params.sourceToCondenserMm * 1e-3;
projectionFocal = params.projectionFocalMm * 1e-3;
fieldToPupil = params.fieldToPupilMm * 1e-3;

x = ((0:N-1) - N/2) * dx;
[X, Y] = meshgrid(x, x);

freq = ((0:N-1) - N/2) / L;
[FX, FY] = meshgrid(freq, freq);
cutoff = params.projNA / lambda;
freqRadius = sqrt(FX.^2 + FY.^2) / cutoff;

sourceExtent = sourceCoordinateExtent(params);
[U, V] = meshgrid(linspace(-sourceExtent, sourceExtent, params.sourceGridSize));
sourceDisplay = makeSource(U, V, params);
source = applyCondenserAperture(U, V, sourceDisplay, params);
[sourceU, sourceV, sourceW, sourceActiveCount, sourceUsedCount] = sampleSource(U, V, source, params);

mask = makeMask(X, Y, params);
projectionPupilAmp = makeProjectionPupil(freqRadius, FX / cutoff, FY / cutoff, params);
projectionRelay = buildProjectionRelay(params);

% Equivalent lithography relay:
% sourceToCondenser = f_C gives nominal collimation at the mask plane.
% fieldToPupil = f_P gives the focused Fourier-imaging condition.
illuminationCurvature = (condenserFocal - sourceToCondenser) / max(condenserFocal^2, eps);
illuminationAngleScale = condenserFocal / max(sourceToCondenser, eps);
effectiveDefocus = (params.defocusUm * 1e-6) + (fieldToPupil - projectionFocal);
illuminationPhase = exp(1i * pi * illuminationCurvature * (X.^2 + Y.^2) / lambda);
defocusPhase = exp(-1i * pi * lambda * effectiveDefocus * (FX.^2 + FY.^2));
projectionPupil = projectionPupilAmp .* defocusPhase;

maskSpectrumPower = abs(fftshift(fft2(ifftshift(mask)))).^2;
sourceKernelPupil = makeSourceKernelAtPupil(FX / cutoff, FY / cutoff, illuminationAngleScale, params);
truePupilIntensity = abs(projectionPupilAmp).^2 .* fftConvolveSame(maskSpectrumPower, sourceKernelPupil);

accumulatedPupil = zeros(N, N);
imageIntensity = zeros(N, N);

for k = 1:numel(sourceW)
    fxShift = sourceU(k) * cutoff * illuminationAngleScale;
    fyShift = sourceV(k) * cutoff * illuminationAngleScale;
    incidentField = exp(1i * 2 * pi * (fxShift * X + fyShift * Y)) .* illuminationPhase;
    fieldAfterMask = mask .* incidentField;
    pupilField = fftshift(fft2(ifftshift(fieldAfterMask)));
    filteredField = pupilField .* projectionPupil;
    accumulatedPupil = accumulatedPupil + sourceW(k) * abs(filteredField).^2;
    detectorField = fftshift(ifft2(ifftshift(filteredField)));
    imageIntensity = imageIntensity + sourceW(k) * abs(detectorField).^2;
end

result = struct();
result.sourceRaw = sourceDisplay;
result.source = safeNormalize(sourceDisplay);
result.mask = mask;
result.pupilSampledRaw = accumulatedPupil;
result.pupilRaw = truePupilIntensity;
result.imageRaw = imageIntensity;
result.pupilSampled = safeNormalize(accumulatedPupil);
result.pupil = safeNormalize(truePupilIntensity);
result.pupilConsistencyError = normalizedDifference(result.pupil, result.pupilSampled);
result.image = safeNormalize(imageIntensity);
result.sourceSamplesU = sourceU;
result.sourceSamplesV = sourceV;
result.sourceWeights = sourceW;
result.sourceCount = numel(sourceW);
result.sourceActiveCount = sourceActiveCount;
result.sourceUsedCount = sourceUsedCount;
result.sourceSamplingClipped = sourceUsedCount < sourceActiveCount;
result.sourceExtent = sourceExtent;
result.maskExtentUm = params.fieldSizeUm / 2;
result.imageExtentUm = 0.5 * params.fieldSizeUm * projectionRelay.absMagnification;
result.pupilNativeExtent = max(abs(freq / cutoff));
result.pupilDisplayExtent = pupilCoordinateExtent(params);
result.freqExtent = result.pupilNativeExtent;
result.illuminationDetuneMm = params.sourceToCondenserMm - params.condenserFocalMm;
result.focusDetuneMm = params.fieldToPupilMm - params.projectionFocalMm;
result.projectionRelay = projectionRelay;
result.xyzReferencePeak = max([max(accumulatedPupil(:)), max(truePupilIntensity(:)), max(imageIntensity(:)), eps]);
end

function source = makeSource(U, V, params)
radial = sqrt(U.^2 + V.^2);

switch params.sourceType
    case 'Point'
        source = double((U - params.pointSourceU).^2 + (V - params.pointSourceV).^2 <= 0.04^2);

    case 'Circular'
        source = double(radial <= params.sourceOuter);

    case 'Square'
        source = double(max(abs(U), abs(V)) <= params.sourceOuter);

    case 'Annular'
        source = double(radial <= params.sourceOuter & radial >= params.sourceInner);

    case 'Dipole X'
        source = double((U - 0.5 * params.quadSeparation).^2 + V.^2 <= params.sourceOuter^2) + ...
                 double((U + 0.5 * params.quadSeparation).^2 + V.^2 <= params.sourceOuter^2);

    case 'Dipole Y'
        source = double(U.^2 + (V - 0.5 * params.quadSeparation).^2 <= params.sourceOuter^2) + ...
                 double(U.^2 + (V + 0.5 * params.quadSeparation).^2 <= params.sourceOuter^2);

    case 'Quadrupole'
        sigma = 0.10;
        shift = params.quadSeparation / sqrt(2);
        source = zeros(size(U));
        centers = [ shift,  shift;
                    shift, -shift;
                   -shift,  shift;
                   -shift, -shift];
        for idx = 1:size(centers, 1)
            source = source + exp(-((U - centers(idx, 1)).^2 + (V - centers(idx, 2)).^2) / (2 * sigma^2));
        end

    case 'Freeform'
        source = lithography_custom_source_values(U, V, params);

    otherwise
        source = double(radial <= params.sourceOuter);
end

source = safeNormalize(source);
end

function source = applyCondenserAperture(U, V, source, params)
apertureMask = double(sqrt(U.^2 + V.^2) <= params.condenserAperture);
source = source .* apertureMask;
source = safeNormalize(source);
end

function mask = makeMask(X, Y, params)
featureSize = params.maskSizeUm * 1e-6;

switch params.maskType
    case 'Circular Aperture'
        mask = double(X.^2 + Y.^2 <= (featureSize / 2)^2);

    case 'Square Aperture'
        mask = double(abs(X) <= featureSize / 2 & abs(Y) <= featureSize / 2);

    case 'Diamond Aperture'
        mask = double(abs(X) + abs(Y) <= featureSize / 2);

    case 'Annular Aperture'
        outerRadius = featureSize / 2;
        innerRadius = params.maskInnerRatio * outerRadius;
        radius = sqrt(X.^2 + Y.^2);
        mask = double(radius <= outerRadius & radius >= innerRadius);

    case '1D Grating'
        pitch = params.gratingPitchUm * 1e-6;
        duty = params.gratingDuty;
        gratingEnvelope = double(abs(X) <= featureSize / 2 & abs(Y) <= featureSize / 2);
        gratingPattern = double(mod(X + max(abs(X(:))), pitch) < duty * pitch);
        mask = gratingEnvelope .* gratingPattern;

    case '2D Grating'
        pitch = params.gratingPitchUm * 1e-6;
        duty = params.gratingDuty;
        gratingEnvelope = double(abs(X) <= featureSize / 2 & abs(Y) <= featureSize / 2);
        xPass = mod(X + max(abs(X(:))), pitch) < duty * pitch;
        yPass = mod(Y + max(abs(Y(:))), pitch) < duty * pitch;
        mask = gratingEnvelope .* double(xPass & yPass);

    case 'Cross'
        armWidth = featureSize / 3;
        mask = double((abs(X) <= armWidth / 2 & abs(Y) <= featureSize / 2) | ...
                      (abs(Y) <= armWidth / 2 & abs(X) <= featureSize / 2));

    otherwise
        mask = double(X.^2 + Y.^2 <= (featureSize / 2)^2);
end
end

function pupil = makeProjectionPupil(freqRadius, Ufreq, Vfreq, params)
switch params.lensType
    case 'Circular'
        pupil = double(freqRadius <= 1);

    case 'Annular'
        pupil = double(freqRadius <= 1 & freqRadius >= params.lensInner);

    case 'Square'
        pupil = double(abs(Ufreq) <= 1 & abs(Vfreq) <= 1);

    case 'Diamond'
        pupil = double(abs(Ufreq) + abs(Vfreq) <= 1);

    case 'Horizontal Slit'
        slitHalf = max(params.lensInner, 0.03);
        pupil = double(abs(Vfreq) <= slitHalf & abs(Ufreq) <= 1);

    case 'Vertical Slit'
        slitHalf = max(params.lensInner, 0.03);
        pupil = double(abs(Ufreq) <= slitHalf & abs(Vfreq) <= 1);

    case 'Freeform'
        pupil = lithography_custom_pupil_values(Ufreq, Vfreq, params);

    otherwise
        pupil = double(freqRadius <= 1);
end
end

function [sampleU, sampleV, sampleW, activeCount, usedCount] = sampleSource(U, V, source, params)
if strcmp(params.sourceType, 'Point')
    sampleU = params.pointSourceU;
    sampleV = params.pointSourceV;
    sampleW = 1;
    activeCount = 1;
    usedCount = 1;
    return;
end

selectionMask = source > 0.15 * max(source(:));
activeCount = nnz(selectionMask);
if activeCount == 0
    sampleU = 0;
    sampleV = 0;
    sampleW = 1;
    activeCount = 1;
    usedCount = 1;
    return;
end

if activeCount <= params.maxSourceSamples || activeCount <= 4 * params.maxSourceSamples
    indices = find(selectionMask);
    sampleU = U(indices);
    sampleV = V(indices);
    sampleW = source(indices);
    sampleW = sampleW / sum(sampleW);
    usedCount = numel(sampleW);
    return;
end

binCount = ceil(sqrt(params.maxSourceSamples));
rowEdges = round(linspace(1, size(source, 1) + 1, binCount + 1));
colEdges = round(linspace(1, size(source, 2) + 1, binCount + 1));
rowEdges(end) = size(source, 1) + 1;
colEdges(end) = size(source, 2) + 1;
rowEdges = unique(rowEdges);
colEdges = unique(colEdges);

sampleU = [];
sampleV = [];
sampleW = [];

for rowIdx = 1:(numel(rowEdges) - 1)
    rows = rowEdges(rowIdx):(rowEdges(rowIdx + 1) - 1);
    if isempty(rows)
        continue;
    end
    for colIdx = 1:(numel(colEdges) - 1)
        cols = colEdges(colIdx):(colEdges(colIdx + 1) - 1);
        if isempty(cols)
            continue;
        end
        cellWeights = source(rows, cols) .* selectionMask(rows, cols);
        totalWeight = sum(cellWeights(:));
        if totalWeight <= 0
            continue;
        end
        cellU = U(rows, cols);
        cellV = V(rows, cols);
        sampleU(end + 1, 1) = sum(cellU(:) .* cellWeights(:)) / totalWeight; %#ok<AGROW>
        sampleV(end + 1, 1) = sum(cellV(:) .* cellWeights(:)) / totalWeight; %#ok<AGROW>
        sampleW(end + 1, 1) = totalWeight; %#ok<AGROW>
    end
end

usedCount = numel(sampleW);
sampleW = sampleW / max(sum(sampleW), eps);
end

function sourceKernel = makeSourceKernelAtPupil(Ufreq, Vfreq, illuminationAngleScale, params)
scale = max(abs(illuminationAngleScale), eps);
sourceU = Ufreq / scale;
sourceV = Vfreq / scale;
source = makeSource(sourceU, sourceV, params);
source = applyCondenserAperture(sourceU, sourceV, source, params);
sourceKernel = source / max(sum(source(:)), eps);
end

function convSame = fftConvolveSame(arrayA, arrayB)
sizeA = size(arrayA);
sizeB = size(arrayB);
sizeConv = sizeA + sizeB - 1;

fftA = fft2(arrayA, sizeConv(1), sizeConv(2));
fftB = fft2(arrayB, sizeConv(1), sizeConv(2));
fullConv = real(ifft2(fftA .* fftB));

startRow = floor(sizeB(1) / 2) + 1;
startCol = floor(sizeB(2) / 2) + 1;
convSame = fullConv(startRow:(startRow + sizeA(1) - 1), startCol:(startCol + sizeA(2) - 1));
end

function projection = buildProjectionRelay(params)
projection = struct();
projection.modelType = 'equivalent-4f-relay';
projection.imageDistanceMm = params.projectionFocalMm;
projection.magnification = -1 / params.reduction;
projection.absMagnification = abs(projection.magnification);
end

function extent = sourceCoordinateExtent(params)
extent = 1.10;
extent = max(extent, 1.08 * params.sourceOuter);
extent = max(extent, 1.08 * params.sourceInner);
extent = max(extent, 0.55 * params.quadSeparation + 1.08 * params.sourceOuter);
extent = max(extent, params.quadSeparation + 0.28);
extent = max(extent, 1.02 * params.condenserAperture);
extent = max(extent, abs(params.pointSourceU) + 0.12);
extent = max(extent, abs(params.pointSourceV) + 0.12);
if strcmp(params.sourceType, 'Freeform')
    extent = max(extent, 1.08 * lithography_custom_source_half(params));
end
end

function extent = pupilCoordinateExtent(params)
extent = 1.10;
extent = max(extent, 1.08 * params.sourceOuter);
extent = max(extent, 1.08 * params.sourceInner);
extent = max(extent, 0.55 * params.quadSeparation + 1.08 * params.sourceOuter);
extent = max(extent, params.quadSeparation + 0.28);
extent = max(extent, abs(params.pointSourceU) + 0.12);
extent = max(extent, abs(params.pointSourceV) + 0.12);
if strcmp(params.sourceType, 'Freeform')
    extent = max(extent, 1.08 * lithography_custom_source_half(params));
end
end

function data = safeNormalize(data)
peak = max(data(:));
if peak > 0
    data = data / peak;
end
end

function diffValue = normalizedDifference(dataA, dataB)
denominator = max(norm(dataA(:)), eps);
diffValue = norm(dataA(:) - dataB(:)) / denominator;
end
