function info = lithography_artifact_warnings(params, result)
messages = {};
if any(strcmp(params.maskType,{'1D Grating','2D Grating'})) && any(result.sourceWeights>0)
    extent=max(hypot(result.sourceSamplesU(result.sourceWeights>0),result.sourceSamplesV(result.sourceWeights>0)));
    minimumPitch=params.wavelengthNm*.001*params.reduction/(params.projNA*(1+extent));
    if params.gratingPitchUm<minimumPitch
        messages{end+1}='Note: nominal first grating orders lie outside the imaging cutoff; unresolved lines can be physical.';
    end
end
diameterPixels=numel(result.pupilAxisM)/max(result.pupilNativeExtent,eps);
if diameterPixels<12
    messages{end+1}=sprintf('Warning: pupil diameter uses only %.1f samples; enlarge the propagation window.',diameterPixels);
end
if max(result.mask(:))==0
    messages{end+1}='Warning: mask is empty or unresolved on this grid.';
end

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
    messages{end + 1} = sprintf( ...
        'Note: source quadrature uses %d / %d active pixels; check convergence for quantitative work.', ...
        result.sourceUsedCount, result.sourceActiveCount);
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

if isfield(result,'maskIllumination')
    messages{end+1}='Note: Gaussian emitters propagate through a Gaussian-aperture condenser into the mask; not a hard circular stop.';
else
    messages{end+1}='Note: legacy angular-source mathematical benchmark.';
end
messages{end + 1} = 'Note: pupil panel shows direct beam intensity at the pupil plane.';
messages{end + 1} = 'Note: detector image uses an equivalent 4f relay, not a full lens design.';
messages{end + 1} = 'Note: RS near mask; scalar paraxial relay elsewhere. See each panel for axis units.';
if params.projNA > 0.3
    messages{end + 1} = 'Warning: high image NA. Paraxial scalar relay is illustrative, not a quantitative high-NA model.';
end
if result.sourceUsedCount==0 || sum(result.sourceWeights)==0
    messages{end+1}='Warning: no transmitted illumination; image is dark.';
end
messages{end + 1} = 'Note: top sketch is geometry only; YZ is a coarse sampled wave preview. Use XY for full source quadrature.';

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
