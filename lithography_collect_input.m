function params = lithography_collect_input(app)
defaults = lithography_default_params();

params = defaults;
params.sourceType = popupText(app.controls.sourceType);
params.sourceOuter = readClampedNumber(app.controls.sourceOuter, defaults.sourceOuter, 0.02, 5.0);
params.sourceInner = readClampedNumber(app.controls.sourceInner, defaults.sourceInner, 0.0, 5.0);
params.sourceInner = min(params.sourceInner, max(0, params.sourceOuter - 0.02));
set(app.controls.sourceInner, 'String', num2str(params.sourceInner));
params.quadSeparation = readClampedNumber(app.controls.quadSeparation, defaults.quadSeparation, 0.1, 5.0);
params.pointSourceU = readClampedNumber(app.controls.pointSourceU, defaults.pointSourceU, -5.0, 5.0);
params.pointSourceV = readClampedNumber(app.controls.pointSourceV, defaults.pointSourceV, -5.0, 5.0);
if isfield(app, 'fig') && isappdata(app.fig, 'customSourceMask')
    params.customSourceMask = getappdata(app.fig, 'customSourceMask');
else
    params.customSourceMask = defaults.customSourceMask;
end
params.condenserAperture = readClampedNumber(app.controls.condenserAperture, defaults.condenserAperture, 0.05, 5.0);

params.maskType = popupText(app.controls.maskType);
params.maskSizeUm = readClampedNumber(app.controls.maskSizeUm, defaults.maskSizeUm, 0.1, 50);
params.maskInnerRatio = readClampedNumber(app.controls.maskInnerRatio, defaults.maskInnerRatio, 0.05, 0.95);
params.gratingPitchUm = readClampedNumber(app.controls.gratingPitchUm, defaults.gratingPitchUm, 0.1, 50);
params.gratingDuty = readClampedNumber(app.controls.gratingDuty, defaults.gratingDuty, 0.05, 0.95);

params.lensType = popupText(app.controls.lensType);
params.projNA = readClampedNumber(app.controls.projNA, defaults.projNA, 0.05, 5.0);
params.lensInner = readClampedNumber(app.controls.lensInner, defaults.lensInner, 0, 0.95);
params.reduction = readClampedNumber(app.controls.reduction, defaults.reduction, 1, 20);
if isfield(app, 'fig') && isappdata(app.fig, 'customPupilMask')
    params.customPupilMask = getappdata(app.fig, 'customPupilMask');
else
    params.customPupilMask = defaults.customPupilMask;
end

params.wavelengthNm = readClampedNumber(app.controls.wavelengthNm, defaults.wavelengthNm, 50, 2000);
params.fieldSizeUm = readClampedNumber(app.controls.fieldSizeUm, defaults.fieldSizeUm, 1, 100);
params.defocusUm = readClampedNumber(app.controls.defocusUm, defaults.defocusUm, -20, 20);
params.condenserFocalMm = readClampedNumber(app.controls.condenserFocalMm, defaults.condenserFocalMm, 10, 200);
params.projectionFocalMm = readClampedNumber(app.controls.projectionFocalMm, defaults.projectionFocalMm, 10, 250);
params.sourceToCondenserMm = readSliderClamped(app.controls.sourceToCondenserMm, defaults.sourceToCondenserMm, 20, 160);
params.fieldToPupilMm = readSliderClamped(app.controls.fieldToPupilMm, defaults.fieldToPupilMm, 20, 220);
params.xySliceZMm = readClampedNumber(app.controls.xySliceZMm, defaults.xySliceZMm, 0, 500);
params.rayDensity = popupText(app.controls.rayDensity);
params.yzMode = popupText(app.controls.yzMode);
params.yzView = popupText(app.controls.yzView);
params.intensityNorm = popupText(app.controls.intensityNorm);

params.customSourceMask = sanitizeCustomMask(params.customSourceMask, defaults.customSourceMask);
params.customPupilMask = sanitizeCustomMask(params.customPupilMask, defaults.customPupilMask);
end

function value = readNumber(handle, defaultValue)
value = str2double(get(handle, 'String'));
if ~isfinite(value)
    value = defaultValue;
    set(handle, 'String', num2str(defaultValue));
end
end

function value = readClampedNumber(handle, defaultValue, lowValue, highValue)
value = clampValue(readNumber(handle, defaultValue), lowValue, highValue);
set(handle, 'String', num2str(value));
end

function value = readSlider(control, defaultValue)
value = get(control.slider, 'Value');
if ~isfinite(value)
    value = defaultValue;
    set(control.slider, 'Value', defaultValue);
    set(control.valueText, 'String', sprintf('%.0f', defaultValue));
else
        set(control.valueText, 'String', sprintf('%.0f', value));
end
end

function value = readSliderClamped(control, defaultValue, lowValue, highValue)
value = clampValue(readSlider(control, defaultValue), lowValue, highValue);
set(control.slider, 'Value', value);
set(control.valueText, 'String', sprintf('%.0f', value));
end

function textValue = popupText(handle)
items = get(handle, 'String');
textValue = items{get(handle, 'Value')};
end

function mask = sanitizeCustomMask(mask, fallbackMask)
if nargin < 2 || isempty(fallbackMask)
    fallbackMask = ones(129);
end
if isempty(mask) || ~isnumeric(mask) || ndims(mask) ~= 2
    mask = fallbackMask;
else
    mask = double(mask);
    mask(~isfinite(mask)) = 0;
    mask = min(max(mask, 0), 1);
end
end

function value = clampValue(value, lowValue, highValue)
value = min(max(value, lowValue), highValue);
end
