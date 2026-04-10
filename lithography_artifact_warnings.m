function info = lithography_artifact_warnings(params, result)
messages = {};

if isfield(result, 'pupilNativeExtent') && isfield(result, 'pupilDisplayExtent') && ...
        result.pupilNativeExtent + 1e-9 < result.pupilDisplayExtent
    messages{end + 1} = sprintf( ...
        'Warning: grid clip. Need %.2f, have %.2f.', ...
        result.pupilDisplayExtent, result.pupilNativeExtent);
end

if isfield(result, 'pupilNativeExtent') && isfield(result, 'pupilDisplayExtent') && ...
        result.pupilNativeExtent > 0 && result.pupilDisplayExtent <= result.pupilNativeExtent && ...
        result.pupilDisplayExtent >= 0.92 * result.pupilNativeExtent
    messages{end + 1} = sprintf( ...
        'Note: pupil view is close to the grid edge (%.2f / %.2f).', ...
        result.pupilDisplayExtent, result.pupilNativeExtent);
end

if isfield(result, 'sourceSamplingClipped') && result.sourceSamplingClipped
    if isfield(result, 'pupilConsistencyError') && result.pupilConsistencyError <= 0.12
        messages{end + 1} = sprintf( ...
            'Note: source sampling reduced to %d / %d active pixels.', ...
            result.sourceUsedCount, result.sourceActiveCount);
    else
        messages{end + 1} = sprintf( ...
            'Warning: source sampling reduced to %d / %d active pixels.', ...
            result.sourceUsedCount, result.sourceActiveCount);
    end
end

if isfield(result, 'pupilConsistencyError') && result.pupilConsistencyError > 0.12
    messages{end + 1} = sprintf( ...
        'Warning: pupil mismatch %.3f.', ...
        result.pupilConsistencyError);
end

if any(strcmp(params.maskType, {'Circular Aperture', 'Square Aperture', 'Diamond Aperture', 'Annular Aperture'})) && ...
        params.maskSizeUm >= 0.95 * params.fieldSizeUm
    messages{end + 1} = sprintf( ...
        'Warning: %s nearly fills the %.2f um mask window.', ...
        params.maskType, params.fieldSizeUm);
end

if any(strcmp(params.maskType, {'1D Grating', '2D Grating'})) && params.maskSizeUm >= 0.95 * params.fieldSizeUm
    messages{end + 1} = 'Warning: grating envelope nearly fills the mask window.';
end

pixelsPerMinFeature = maskPixelsPerSmallestFeature(params);
if pixelsPerMinFeature > 0 && pixelsPerMinFeature < 4
    messages{end + 1} = sprintf( ...
        'Warning: mask feature uses only %.1f pixels.', ...
        pixelsPerMinFeature);
elseif pixelsPerMinFeature > 0 && pixelsPerMinFeature < 6
    messages{end + 1} = sprintf( ...
        'Note: mask feature uses only %.1f pixels.', ...
        pixelsPerMinFeature);
end

if params.condenserAperture > 1.02
    messages{end + 1} = 'Note: cond aperture > 1 acts like 1 here.';
end

if params.projNA > 1.02
    messages{end + 1} = 'Note: NA > 1 is a normalized stress test here.';
end

if strcmp(params.lensType, 'Freeform') && isfield(params, 'customPupilMask') && ~isempty(params.customPupilMask)
    openFraction = mean(double(params.customPupilMask(:)) > 0.5);
    if openFraction < 0.02
        messages{end + 1} = 'Warning: freeform pupil is almost closed.';
    end
end

if strcmp(params.sourceType, 'Freeform') && isfield(params, 'customSourceMask') && ~isempty(params.customSourceMask)
    activeFraction = mean(double(params.customSourceMask(:)) > 0.05);
    if activeFraction < 0.01
        messages{end + 1} = 'Warning: freeform source is almost empty.';
    end
end

if strcmp(params.sourceType, 'Point') && abs(params.pointSourceU) > 1e-3
    messages{end + 1} = 'Note: top sketch is Y-Z only; point x offset does not move ray height.';
end

messages{end + 1} = 'Note: illumination uses an angular source model at the mask.';
messages{end + 1} = 'Note: pupil panel shows direct beam intensity at the pupil plane.';
messages{end + 1} = 'Note: detector image uses an equivalent 4f relay, not a full lens design.';
messages{end + 1} = 'Note: XY beam path uses the same wave relay as the detector.';
messages{end + 1} = 'Note: top sketch and YZ are still visualization models.';

info = struct();
info.messages = messages;
info.hasWarning = any(startsWith(messages, 'Warning:'));
info.hasNote = any(startsWith(messages, 'Note:'));
if info.hasWarning
    info.statusText = 'Status: Warning';
    info.badgeColor = [1.00 0.90 0.78];
    info.boxColor = [1.00 0.96 0.90];
elseif info.hasNote
    info.statusText = 'Status: Note';
    info.badgeColor = [0.90 0.95 1.00];
    info.boxColor = [0.96 0.98 1.00];
else
    info.statusText = 'Status: OK';
    info.badgeColor = [0.89 0.97 0.90];
    info.boxColor = [0.95 0.99 0.95];
end
info.text = strjoin(messages, sprintf('\n'));
end

function pixelsPerFeature = maskPixelsPerSmallestFeature(params)
pixelSizeUm = params.fieldSizeUm / max(params.gridSize, 1);
if pixelSizeUm <= 0
    pixelsPerFeature = 0;
    return;
end

switch params.maskType
    case {'Circular Aperture', 'Square Aperture', 'Diamond Aperture', 'Cross'}
        featureUm = params.maskSizeUm;
    case 'Annular Aperture'
        featureUm = 0.5 * params.maskSizeUm * max(1 - params.maskInnerRatio, 0);
    case {'1D Grating', '2D Grating'}
        featureUm = min(params.gratingDuty * params.gratingPitchUm, ...
            (1 - params.gratingDuty) * params.gratingPitchUm);
    otherwise
        featureUm = params.maskSizeUm;
end

pixelsPerFeature = featureUm / pixelSizeUm;
end
