function slice = lithography_post_pupil_wave_slice(params, result, zSelected, sharedPeak)
if nargin < 2 || isempty(result) || ~isfield(result, 'projectionRelay') || ~isfield(result, 'mask')
    result = lithography_run_physics(params);
end
if nargin < 4
    sharedPeak = [];
end

geom = lithography_projection_geometry(params, result.projectionRelay);
zSelected = min(max(zSelected, geom.zPupil), geom.zSliceMax);

N = params.gridSize;
fieldSizeM = params.fieldSizeUm * 1e-6;
xField = ((0:N-1) - N/2) * (fieldSizeM / N);
[XField, YField] = meshgrid(xField, xField);

lambda = params.wavelengthNm * 1e-9;
condenserFocal = params.condenserFocalMm * 1e-3;
sourceToCondenser = params.sourceToCondenserMm * 1e-3;
illuminationCurvature = (condenserFocal - sourceToCondenser) / max(condenserFocal^2, eps);
illuminationAngleScale = condenserFocal / max(sourceToCondenser, eps);
illuminationPhase = exp(1i * pi * illuminationCurvature * (XField.^2 + YField.^2) / lambda);

freq = ((0:N-1) - N/2) / fieldSizeM;
[FX, FY] = meshgrid(freq, freq);
cutoff = params.projNA / lambda;
projectionPupilAmp = makeProjectionPupil(FX / cutoff, FY / cutoff, params);
effectiveDefocus = (params.defocusUm * 1e-6) + ...
    ((params.fieldToPupilMm - params.projectionFocalMm) * 1e-3);
defocusPhase = exp(-1i * pi * lambda * effectiveDefocus * (FX.^2 + FY.^2));
projectionPupil = projectionPupilAmp .* defocusPhase;

[sourceU, sourceV, sourceW] = lithography_wave_source_samples(params, result);
rawIntensity = zeros(N, N);
extraDefocus = (zSelected - geom.zImage) * 1e-3;
extraDefocusPhase = exp(-1i * pi * lambda * extraDefocus * (FX.^2 + FY.^2));

for k = 1:numel(sourceW)
    fxShift = sourceU(k) * cutoff * illuminationAngleScale;
    fyShift = sourceV(k) * cutoff * illuminationAngleScale;
    fieldAfterMask = result.mask .* exp(1i * 2 * pi * (fxShift * XField + fyShift * YField)) .* illuminationPhase;
    pupilField = fftshift(fft2(ifftshift(fieldAfterMask))) .* projectionPupil;
    detectorField = fftshift(ifft2(ifftshift(pupilField .* extraDefocusPhase)));
    rawIntensity = rawIntensity + sourceW(k) * abs(detectorField).^2;
end

if zSelected <= geom.zProjection2
    stageLabel = 'projection after pupil';
elseif zSelected <= geom.zImage
    stageLabel = 'projection to image';
else
    stageLabel = 'after image';
end

[displayIntensity, normalizationPeak] = lithography_normalize_intensity(rawIntensity, params, result, sharedPeak);
axisValues = xField ./ max(abs(xField(:)), eps);

slice = struct();
slice.axis = axisValues;
slice.rawIntensity = rawIntensity;
slice.intensity = displayIntensity;
slice.zMm = zSelected;
slice.stageLabel = stageLabel;
slice.mode = 'Wave';
slice.titleText = '';
slice.xlabelText = 'normalized x';
slice.ylabelText = 'normalized y';
slice.normalizationMode = params.intensityNorm;
slice.normalizationPeak = normalizationPeak;
slice.isExact = false;
end

function pupil = makeProjectionPupil(Ufreq, Vfreq, params)
radial = sqrt(Ufreq.^2 + Vfreq.^2);
switch params.lensType
    case 'Circular'
        pupil = double(radial <= 1);
    case 'Annular'
        pupil = double(radial <= 1 & radial >= params.lensInner);
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
        pupil = double(radial <= 1);
end
end
