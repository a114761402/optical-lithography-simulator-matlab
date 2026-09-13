function params = lithography_collect_input(app)
defaults = lithography_default_params();

params = defaults;
params.sourceType = popupText(app.controls.sourceType);
params.sourceEmissionNA = readClampedNumber(app.controls.sourceEmissionNA, defaults.sourceEmissionNA, .02, .15);
params.sourceOuter = readClampedNumber(app.controls.sourceOuter, defaults.sourceOuter, 0.08, 1.0);
params.sourceInner = readClampedNumber(app.controls.sourceInner, defaults.sourceInner, 0.0, 0.96);
set(app.controls.sourceInner, 'String', num2str(params.sourceInner));
params.quadSeparation = readClampedNumber(app.controls.quadSeparation, defaults.quadSeparation, 0.1, 2.0);
params.pointSourceU = readClampedNumber(app.controls.pointSourceU, defaults.pointSourceU, -1.0, 1.0);
params.pointSourceV = readClampedNumber(app.controls.pointSourceV, defaults.pointSourceV, -1.0, 1.0);
if isfield(app, 'fig') && isappdata(app.fig, 'customSourceMask')
    params.customSourceMask = getappdata(app.fig, 'customSourceMask');
else
    params.customSourceMask = defaults.customSourceMask;
end
params.condenserAperture = readClampedNumber(app.controls.condenserAperture, defaults.condenserAperture, 0, 1.0);

params.maskType = popupText(app.controls.maskType);
params.maskPlateSizeMm = readClampedNumber(app.controls.maskPlateSizeMm,defaults.maskPlateSizeMm,1,200);
params.maskSizeUm = readClampedNumber(app.controls.maskSizeUm, defaults.maskSizeUm, 0.1, 75);
params.maskInnerRatio = readClampedNumber(app.controls.maskInnerRatio, defaults.maskInnerRatio, 0, 0.9);
params.gratingPitchUm = readClampedNumber(app.controls.gratingPitchUm, defaults.gratingPitchUm, 0.1, 50);
params.gratingDuty = readClampedNumber(app.controls.gratingDuty, defaults.gratingDuty, 0.1, 0.9);

params.lensType = popupText(app.controls.lensType);
params.projNA = readClampedNumber(app.controls.projNA, defaults.projNA, 0.05, 0.30);
params.lensInner = readClampedNumber(app.controls.lensInner, defaults.lensInner, 0, 0.9);
params.reduction = readClampedNumber(app.controls.reduction, defaults.reduction, 1, 20);
if isfield(app, 'fig') && isappdata(app.fig, 'customPupilMask')
    params.customPupilMask = getappdata(app.fig, 'customPupilMask');
else
    params.customPupilMask = defaults.customPupilMask;
end

params.wavelengthNm = readClampedNumber(app.controls.wavelengthNm, defaults.wavelengthNm, 50, 2000);
params.fieldSizeUm = readClampedNumber(app.controls.fieldSizeUm, defaults.fieldSizeUm, 1, 100);
params.defocusUm = readClampedNumber(app.controls.defocusUm, defaults.defocusUm, -20, 20);
params.condenserFocalMm = readClampedNumber(app.controls.condenserFocalMm, defaults.condenserFocalMm, 20, 160);
params.projectionFocalMm = 2*readClampedNumber(app.controls.projectionFocalMm, defaults.projectionFocalMm/2, 10, 110);
params.sourceToCondenserMm=params.condenserFocalMm;
params.fieldToPupilMm=params.projectionFocalMm;
set(app.controls.sourceToCondenserMm.slider,'Value',params.sourceToCondenserMm,'Enable','off');
set(app.controls.fieldToPupilMm.slider,'Value',params.fieldToPupilMm,'Enable','off');
set(app.controls.sourceToCondenserMm.valueText,'String',num2str(params.sourceToCondenserMm));
set(app.controls.fieldToPupilMm.valueText,'String',num2str(params.fieldToPupilMm));
params.xySliceZMm = readClampedNumber(app.controls.xySliceZMm, defaults.xySliceZMm, 0, 900);
% Named planes follow geometry changes; a custom z remains an absolute position.
if isfield(app.controls,'slicePlane')
    choice=get(app.controls.slicePlane,'Value');
    if choice>1
        maskZ=params.sourceToCondenserMm+params.condenserFocalMm;
        planes=[0 params.sourceToCondenserMm maskZ maskZ+.001,...
            maskZ+params.fieldToPupilMm,...
            maskZ+params.fieldToPupilMm+params.projectionFocalMm/params.reduction+params.defocusUm*.001];
        params.xySliceZMm=planes(choice-1);
        set(app.controls.xySliceZMm,'String',sprintf('%.12g',params.xySliceZMm));
    end
end
params.rayDensity = popupText(app.controls.rayDensity);
params.yzMode = popupText(app.controls.yzMode);
params.yzView = popupText(app.controls.yzView);
params.intensityNorm = popupText(app.controls.intensityNorm);

params=lithography_check_settings(params);
zImage=2*params.condenserFocalMm+params.projectionFocalMm+params.projectionFocalMm/params.reduction+params.defocusUm*.001;
zMax=zImage+max(20,.3*params.projectionFocalMm/params.reduction);
if params.xySliceZMm>zMax
    error('Lithography:Settings','XY slice z must be between 0 and %.6g mm for this geometry.',zMax);
end
end

function value = readNumber(handle, defaultValue)
value = str2double(get(handle, 'String'));
if ~isfinite(value)
    error('Lithography:Settings','Please enter a finite number; NaN and Inf are not allowed.');
end
end

function value = readClampedNumber(handle, defaultValue, lowValue, highValue)
value = readNumber(handle, defaultValue);
if value<lowValue || value>highValue
    error('Lithography:Settings','Entered value %g must be between %g and %g.',value,lowValue,highValue);
end
set(handle, 'String', sprintf('%.12g',value));
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
