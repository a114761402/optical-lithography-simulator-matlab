 function lithography_specular_gui(varargin)
% LITHOGRAPHY_SPECULAR_GUI
% GUI for a simplified specular lithography illumination simulation.
%
% Usage:
%   lithography_specular_gui
%   lithography_specular_gui('selftest')

if nargin >= 1 && ischar(varargin{1})
    switch lower(varargin{1})
        case 'selftest'
            runSelfTest();
            return;
        case 'validate'
            lithography_validation_report(true);
            return;
        case 'physicality'
            lithography_physicality_report(true);
            return;
        case 'xyphysicality'
            lithography_intermediate_xy_physicality_test(true);
            return;
        case 'gratingtest'
            lithography_grating_wave_slice_test(true);
            return;
        case 'fullpathtest'
            lithography_full_path_wave_test(true);
            return;
    end
end

buildGui('on');
end

function runSelfTest()
params = lithography_default_params();
params.gridSize = 64;
params.sourceGridSize = 25;
params.maxSourceSamples = 49;

physicsParams = lithography_default_params();
physicsParams.gridSize = 96;
physicsParams.sourceGridSize = 41;
physicsParams.maxSourceSamples = 121;

testCases = {
    struct('sourceType', 'Point',      'maskType', 'Circular Aperture', 'lensType', 'Circular')
    struct('sourceType', 'Annular',    'maskType', '1D Grating',        'lensType', 'Circular')
    struct('sourceType', 'Dipole X',   'maskType', 'Circular Aperture', 'lensType', 'Circular')
    struct('sourceType', 'Quadrupole', 'maskType', 'Square Aperture',   'lensType', 'Square')
    struct('sourceType', 'Freeform',   'maskType', 'Circular Aperture', 'lensType', 'Circular')
    };

for k = 1:numel(testCases)
    testParams = params;
    fields = fieldnames(testCases{k});
    for n = 1:numel(fields)
        testParams.(fields{n}) = testCases{k}.(fields{n});
    end
    result = lithography_run_physics(testParams);
    assert(all(isfinite(result.image(:))), 'Image contains non-finite values.');
    assert(max(result.image(:)) > 0, 'Image intensity is zero.');
    assert(all(isfinite(result.pupil(:))), 'Pupil contains non-finite values.');
end

baseResult = lithography_run_physics(params);
baseWarnings = lithography_artifact_warnings(params, baseResult);
assert(isfield(baseWarnings, 'messages') && ~isempty(baseWarnings.messages), 'Artifact warning helper should return messages.');

distanceParams = params;
distanceParams.sourceToCondenserMm = params.sourceToCondenserMm + 20;
sourceDistanceResult = lithography_run_physics(distanceParams);
sourceDistanceChange = norm(baseResult.image(:) - sourceDistanceResult.image(:)) / norm(baseResult.image(:));
assert(sourceDistanceChange > 1e-3, 'Changing source-to-condenser distance should change the image.');

distanceParams = params;
distanceParams.fieldToPupilMm = params.fieldToPupilMm + 20;
pupilDistanceResult = lithography_run_physics(distanceParams);
pupilDistanceChange = norm(baseResult.image(:) - pupilDistanceResult.image(:)) / norm(baseResult.image(:));
assert(pupilDistanceChange > 1e-3, 'Changing field-to-pupil distance should change the image.');

apertureParams = params;
apertureParams.condenserAperture = 0.45;
apertureResult = lithography_run_physics(apertureParams);
apertureChange = norm(baseResult.image(:) - apertureResult.image(:)) / norm(baseResult.image(:));
assert(apertureChange > 1e-3, 'Changing condenser aperture should change the image.');

largeSourceParams = params;
largeSourceParams.sourceType = 'Circular';
largeSourceParams.sourceOuter = 2.4;
largeSourceResult = lithography_run_physics(largeSourceParams);
assert(largeSourceResult.sourceExtent > 2.3, 'Large sources should expand the source panel extent.');

gratingSmall = params;
gratingSmall.maskType = '1D Grating';
gratingSmall.maskSizeUm = 2.0;
gratingSmallResult = lithography_run_physics(gratingSmall);
gratingLarge = params;
gratingLarge.maskType = '1D Grating';
gratingLarge.maskSizeUm = 6.0;
gratingLargeResult = lithography_run_physics(gratingLarge);
gratingChange = norm(gratingSmallResult.mask(:) - gratingLargeResult.mask(:)) / max(norm(gratingLargeResult.mask(:)), eps);
assert(gratingChange > 1e-3, 'Changing grating size should change the mask.');

yzData = lithography_compute_yz_intensity(params, baseResult);
assert(all(isfinite(yzData.intensity(:))), 'YZ intensity contains non-finite values.');
assert(max(yzData.intensity(:)) > 0, 'YZ intensity should not be zero.');

multiPointParams = params;
multiPointParams.yzMode = 'Multi-point';
multiPointYZ = lithography_compute_yz_intensity(multiPointParams, baseResult);
assert(all(isfinite(multiPointYZ.intensity(:))), 'Multi-point YZ intensity contains non-finite values.');
assert(max(multiPointYZ.intensity(:)) > 0, 'Multi-point YZ intensity should not be zero.');

annularSourceParams = physicsParams;
annularSourceParams.sourceType = 'Annular';
annularSourceParams.sourceOuter = 0.6;
annularSourceParams.sourceInner = 0.3;
annularSourceParams.maskType = 'Circular Aperture';
annularSourceParams.maskSizeUm = 4;
annularSourceParams.fieldSizeUm = 8;
annularSourceParams.lensType = 'Circular';
annularSourceParams.projNA = 0.75;
annularSourceParams.maxSourceSamples = 225;
annularResult = lithography_run_physics(annularSourceParams);
centerIdx = ceil(size(annularResult.pupil, 1) / 2);
ringRow = annularResult.pupil(centerIdx, :);
assert(ringRow(centerIdx) < 0.25, 'True pupil intensity for annular source should stay dark at the center.');
assert(max(ringRow) > 0.8, 'True pupil intensity for annular source should have a bright ring.');
sampledRingRow = annularResult.pupilSampled(centerIdx, :);
assert(sampledRingRow(centerIdx) < 0.25, 'Direct pupil-plane beam image for annular source should stay dark at the center.');
assert(max(annularResult.pupilSampled(:)) > 0.8, 'Direct pupil-plane beam image for annular source should have a bright ring.');
annularLowNA = annularSourceParams;
annularLowNA.projNA = 2.0;
annularLowNAResult = lithography_run_physics(annularLowNA);
assert(abs(annularLowNAResult.pupilDisplayExtent - annularResult.pupilDisplayExtent) < 1e-12, ...
    'Pupil display extent should stay fixed when only projection NA changes.');
assert(annularResult.pupilConsistencyError < 0.20, ...
    'Analytical and sampled pupil intensity should remain reasonably consistent.');
pupilPlaneZ = annularSourceParams.sourceToCondenserMm + annularSourceParams.condenserFocalMm + annularSourceParams.fieldToPupilMm;
pupilSlice = lithography_compute_xy_slice(annularSourceParams, annularResult, pupilPlaneZ);
assert(strcmp(pupilSlice.mode, 'Wave'), 'Clicked pupil-plane XY slice should stay on the wave model.');
assert(all(isfinite(pupilSlice.intensity(:))) && max(pupilSlice.intensity(:)) > 0, ...
    'Clicked pupil-plane XY slice should stay finite and non-zero.');

clippedAnnularParams = annularSourceParams;
clippedAnnularParams.maskSizeUm = 12;
clippedAnnularParams.projNA = 5;
clippedAnnularResult = lithography_run_physics(clippedAnnularParams);
clippedWarnings = lithography_artifact_warnings(clippedAnnularParams, clippedAnnularResult);
assert(contains(clippedWarnings.text, 'grid clip'), ...
    'Extreme clipped annular settings should trigger a grid-clipping warning.');

xyzNormParams = params;
xyzNormParams.intensityNorm = 'XYZ';
xyzNormResult = lithography_run_physics(xyzNormParams);
xyzYZ = lithography_compute_yz_intensity(xyzNormParams, xyzNormResult);
xyzSliceZ = xyzNormParams.xySliceZMm + 6;
xyzSlice = lithography_compute_xy_slice(xyzNormParams, xyzNormResult, xyzSliceZ, xyzYZ.normalizationPeak);
assert(abs(xyzSlice.normalizationPeak - xyzYZ.normalizationPeak) < 1e-12, ...
    'XYZ normalization should share one intensity scale between YZ and XY views.');
assert(max(xyzYZ.intensity(:)) > 0.1, 'XYZ normalization should keep the YZ view visibly non-zero.');

xySlice = lithography_compute_xy_slice(params, baseResult, 0.5 * params.projectionFocalMm + ...
    params.sourceToCondenserMm + params.condenserFocalMm + params.fieldToPupilMm);
assert(all(isfinite(xySlice.intensity(:))), 'XY slice intensity contains non-finite values.');
assert(max(xySlice.intensity(:)) > 0, 'XY slice intensity should not be zero.');

afterImageSlice = lithography_compute_xy_slice(params, baseResult, baseResult.projectionRelay.imageDistanceMm + ...
    params.sourceToCondenserMm + params.condenserFocalMm + params.fieldToPupilMm + 10);
assert(all(isfinite(afterImageSlice.intensity(:))), 'Post-image XY slice should stay finite.');
assert(max(afterImageSlice.intensity(:)) > 0, 'Post-image XY slice should not be zero.');
assert(strcmp(afterImageSlice.stageLabel, 'after image'), 'Post-image XY slice should report the after-image stage.');

circularIllumParams = params;
circularIllumParams.sourceType = 'Circular';
circularIllumParams.sourceOuter = 0.30;
circularIllumParams.condenserAperture = 1.0;
circularIllumResult = lithography_run_physics(circularIllumParams);
circularIllumSlice = lithography_compute_xy_slice(circularIllumParams, circularIllumResult, 38.3);
[xBoundary, diagBoundary] = halfMaximumBoundaries(circularIllumSlice.intensity, circularIllumSlice.axis);
assert(abs(xBoundary - diagBoundary) < 0.06, 'Circular illumination slice should stay approximately circular.');

presets = lithography_preset_library();
assert(numel(presets) >= 5, 'Preset library should contain multiple sanity presets.');
assert(any(strcmp({presets.name}, 'Dense annular 0.8/0.5')), ...
    'Expected annular literature preset is missing.');
showcases = lithography_showcase_library();
assert(any(strcmp({showcases.name}, 'Open annular source at pupil')), ...
    'Expected open annular pupil showcase is missing.');
assert(any(strcmp({showcases.name}, 'Near-field square @0.05 mm')), ...
    'Expected near-field square 0.05 mm showcase is missing.');
assert(any(strcmp({showcases.name}, 'Near-field square @0.1 mm')), ...
    'Expected near-field square showcase is missing.');
assert(any(strcmp({showcases.name}, 'Near-field grating @0.1 mm')), ...
    'Expected near-field grating showcase is missing.');

boundaryParams = params;
boundaryParams.gridSize = physicsParams.gridSize;
boundaryParams.sourceGridSize = physicsParams.sourceGridSize;
boundaryParams.maxSourceSamples = physicsParams.maxSourceSamples;
boundaryParams.sourceType = 'Point';
boundaryParams.pointSourceU = 0;
boundaryParams.pointSourceV = 0;
boundaryParams.maskType = '1D Grating';
boundaryParams.maskSizeUm = 20;
boundaryParams.gratingPitchUm = 8;
boundaryParams.gratingDuty = 0.5;
boundaryParams.fieldSizeUm = 44;
boundaryResult = lithography_run_physics(boundaryParams);
boundaryGeom = lithography_projection_geometry(boundaryParams, boundaryResult.projectionRelay);
sliceBeforeLens = lithography_compute_xy_slice(boundaryParams, boundaryResult, boundaryGeom.zProjection1 - 0.05);
sliceAfterLens = lithography_compute_xy_slice(boundaryParams, boundaryResult, boundaryGeom.zProjection1 + 0.05);
assert(strcmp(sliceBeforeLens.mode, 'Wave') && strcmp(sliceAfterLens.mode, 'Wave'), ...
    'Projection slices across the first lens boundary should stay on the same wave model.');
peakRatio = max(sliceAfterLens.rawIntensity(:)) / max(max(sliceBeforeLens.rawIntensity(:)), eps);
assert(peakRatio > 0.2 && peakRatio < 5, ...
    'Projection slices across the first lens boundary should remain reasonably continuous in raw intensity.');

dipoleXParams = params;
dipoleXParams.sourceType = 'Dipole X';
dipoleXParams.sourceOuter = 0.16;
dipoleXParams.quadSeparation = 0.70;
dipoleXResult = lithography_run_physics(dipoleXParams);
sourceCenter = ceil(size(dipoleXResult.source, 1) / 2);
assert(dipoleXResult.source(sourceCenter, sourceCenter) < 0.2, 'Dipole X source should stay dark at the center.');
assert(max(dipoleXResult.source(sourceCenter, :)) > 0.8, 'Dipole X source should have bright side lobes.');

dipoleYParams = params;
dipoleYParams.sourceType = 'Dipole Y';
dipoleYParams.sourceOuter = 0.16;
dipoleYParams.quadSeparation = 0.70;
dipoleYResult = lithography_run_physics(dipoleYParams);
assert(dipoleYResult.source(sourceCenter, sourceCenter) < 0.2, 'Dipole Y source should stay dark at the center.');
assert(max(dipoleYResult.source(:, sourceCenter)) > 0.8, 'Dipole Y source should have bright top/bottom lobes.');

pointOffsetParams = params;
pointOffsetParams.sourceType = 'Point';
pointOffsetParams.pointSourceU = 0.35;
pointOffsetParams.pointSourceV = -0.20;
pointOffsetResult = lithography_run_physics(pointOffsetParams);
[~, maxIdx] = max(pointOffsetResult.source(:));
[maxRow, maxCol] = ind2sub(size(pointOffsetResult.source), maxIdx);
assert(maxCol > ceil(size(pointOffsetResult.source, 2) / 2), 'Point source x offset should shift the source image right.');
assert(maxRow < ceil(size(pointOffsetResult.source, 1) / 2), 'Point source y offset should shift the source image downward in matrix coordinates.');

validationReport = lithography_validation_report(false);
assert(validationReport.pass, 'Validation report should pass all benchmark cases.');

app = buildGui('off');
assert(isfield(app.controls, 'infoBadge') && ishghandle(app.controls.infoBadge), ...
    'Info badge should exist.');
refreshControlLayout(app.fig);
drawnow;
controlPos = get(app.controlPanel, 'Position');
propPos = get(app.axPropagation, 'Position');
yzPos = get(app.axYZ, 'Position');
closePos = get(app.controls.closeAllFigsButton, 'Position');
topLabelPos = get(app.controls.topXYSliceLabel, 'Position');
topEditPos = get(app.controls.topXYSliceEdit, 'Position');
assert(closePos(1) > controlPos(1) + controlPos(3), 'Top bar controls should stay outside the control panel.');
assert(closePos(1) + closePos(3) <= topLabelPos(1), 'Close all figs should sit left of the XY z label.');
assert(topLabelPos(1) + topLabelPos(3) <= topEditPos(1), 'XY z label should sit left of the XY z entry.');
assert(closePos(2) >= yzPos(2) + yzPos(4), 'Top bar controls should stay above the YZ axes.');
assert(closePos(2) + closePos(4) <= propPos(2), 'Top bar controls should stay below the propagation sketch.');
assert(topEditPos(1) + topEditPos(3) <= yzPos(1) + 0.30 * yzPos(3), ...
    'Top XY z controls should stay well left of the YZ title and toolbar area.');
set(app.controls.topXYSliceEdit, 'String', '133.4');
topBarXYSliceChanged(app.fig, app.controls.topXYSliceEdit);
assert(abs(str2double(get(app.controls.xySliceZMm, 'String')) - 133.4) < 1e-9, ...
    'Top XY z entry should sync to the control-panel XY z field.');
closeSecondaryFigures(app.fig);
sliceFig1 = showXYSliceFigure(xySlice, app.fig, 'off');
sliceFig2 = showXYSliceFigure(xySlice, app.fig, 'off');
pos1 = get(sliceFig1, 'Position');
pos2 = get(sliceFig2, 'Position');
overlapX = pos1(1) < pos2(1) + pos2(3) && pos2(1) < pos1(1) + pos1(3);
overlapY = pos1(2) < pos2(2) + pos2(4) && pos2(2) < pos1(2) + pos1(4);
assert(~(overlapX && overlapY), 'New XY slice figures should not overlap the previous one.');
closeSecondaryFigures(app.fig);
remainingFigs = findobj('Type', 'figure');
remainingFigs(remainingFigs == app.fig) = [];
assert(isempty(remainingFigs), 'Close Other Figs should close all secondary figures.');
sliceFig3 = showXYSliceFigure(xySlice, app.fig, 'off');
assert(ishghandle(sliceFig3), 'Extra slice figure should open.');
closeAllFigures(app.fig);
assert(ishghandle(app.fig), 'Close all figs should keep the main GUI open.');
remainingFigs = findobj('Type', 'figure');
remainingFigs(remainingFigs == app.fig) = [];
assert(isempty(remainingFigs), 'Close all figs should close all secondary figures.');
unrelatedFig = figure('Visible', 'off', 'Name', 'Unrelated test figure');
sliceFig4 = showXYSliceFigure(xySlice, app.fig, 'off');
closeAllFigures(app.fig);
assert(ishghandle(unrelatedFig), 'Close all figs should not close unrelated MATLAB figures.');
assert(~ishghandle(sliceFig4), 'Close all figs should still close app slice figures.');
close(unrelatedFig);

setPopupValue(app.controls.sourceType, 'Point');
refreshControlLayout(app.fig);
assertControlVisibility(app, 'sourceOuter', false);
assertControlVisibility(app, 'sourceInner', false);
assertControlVisibility(app, 'quadSeparation', false);
assertControlVisibility(app, 'pointSourceU', true);
assertControlVisibility(app, 'pointSourceV', true);
assertControlVisibility(app, 'editSourceButton', false);

setPopupValue(app.controls.sourceType, 'Annular');
refreshControlLayout(app.fig);
assertControlVisibility(app, 'sourceOuter', true);
assertControlVisibility(app, 'sourceInner', true);
assertControlVisibility(app, 'pointSourceU', false);

setPopupValue(app.controls.sourceType, 'Square');
refreshControlLayout(app.fig);
assertControlVisibility(app, 'sourceOuter', true);
assertControlVisibility(app, 'sourceInner', false);

setPopupValue(app.controls.sourceType, 'Dipole X');
refreshControlLayout(app.fig);
assertControlVisibility(app, 'sourceOuter', true);
assertControlVisibility(app, 'quadSeparation', true);

setPopupValue(app.controls.sourceType, 'Freeform');
refreshControlLayout(app.fig);
assertControlVisibility(app, 'sourceOuter', false);
assertControlVisibility(app, 'editSourceButton', true);

setPopupValue(app.controls.maskType, '1D Grating');
refreshControlLayout(app.fig);
assertControlVisibility(app, 'maskSizeUm', true);
assertControlVisibility(app, 'gratingPitchUm', true);
assertControlVisibility(app, 'gratingDuty', true);
assertControlVisibility(app, 'maskInnerRatio', false);

setPopupValue(app.controls.maskType, 'Circular Aperture');
refreshControlLayout(app.fig);
assertControlVisibility(app, 'maskSizeUm', true);
assertControlVisibility(app, 'gratingPitchUm', false);

setPopupValue(app.controls.maskType, 'Annular Aperture');
refreshControlLayout(app.fig);
assertControlVisibility(app, 'maskSizeUm', true);
assertControlVisibility(app, 'maskInnerRatio', true);

setPopupValue(app.controls.lensType, 'Circular');
refreshControlLayout(app.fig);
assertControlVisibility(app, 'lensInner', false);

setPopupValue(app.controls.lensType, 'Annular');
refreshControlLayout(app.fig);
assertControlVisibility(app, 'lensInner', true);

setPopupValue(app.controls.lensType, 'Horizontal Slit');
refreshControlLayout(app.fig);
assertControlVisibility(app, 'lensInner', true);
assertControlVisibility(app, 'yzView', true);
assertControlVisibility(app, 'xySliceZMm', true);

setPopupValue(app.controls.lensType, 'Freeform');
refreshControlLayout(app.fig);
assertControlVisibility(app, 'editPupilButton', true);

drawnow;
close(app.fig);

disp('Self-test passed.');
end

function [xBoundary, diagBoundary] = halfMaximumBoundaries(intensity, axisValues)
center = ceil(size(intensity, 1) / 2);
rowProfile = intensity(center, center:end);
diagProfile = diag(intensity(center:end, center:end))';

rowIdx = find(rowProfile <= 0.5, 1, 'first');
diagIdx = find(diagProfile <= 0.5, 1, 'first');

if isempty(rowIdx)
    xBoundary = axisValues(end);
else
    xBoundary = axisValues(center + rowIdx - 1);
end

if isempty(diagIdx)
    diagBoundary = sqrt(2) * axisValues(end);
else
    diagBoundary = sqrt(2) * axisValues(center + diagIdx - 1);
end
end

function app = buildGui(figVisible)
params = lithography_default_params();
presets = lithography_preset_library();
presetNames = {presets.name};
showcases = lithography_showcase_library();
showcaseNames = {showcases.name};

app.fig = figure( ...
    'Name', 'Specular Lithography Simulator', ...
    'NumberTitle', 'off', ...
    'Tag', 'LithographyMainGUI', ...
    'Color', [0.94 0.94 0.94], ...
    'MenuBar', 'none', ...
    'ToolBar', 'figure', ...
    'Position', [40 40 1680 950], ...
    'Visible', figVisible);

app.controlPanel = uipanel( ...
    'Parent', app.fig, ...
    'Title', 'Controls', ...
    'Units', 'normalized', ...
    'Position', [0.012 0.03 0.235 0.94], ...
    'FontWeight', 'bold');

app.axPropagation = axes('Parent', app.fig, 'Units', 'normalized', 'Position', [0.255 0.73 0.705 0.20]);
app.axYZ          = axes('Parent', app.fig, 'Units', 'normalized', 'Position', [0.255 0.43 0.705 0.21]);
app.axSource      = axes('Parent', app.fig, 'Units', 'normalized', 'Position', [0.252 0.065 0.142 0.285]);
app.axMask        = axes('Parent', app.fig, 'Units', 'normalized', 'Position', [0.433 0.065 0.142 0.285]);
app.axPupil       = axes('Parent', app.fig, 'Units', 'normalized', 'Position', [0.614 0.065 0.142 0.285]);
app.axImage       = axes('Parent', app.fig, 'Units', 'normalized', 'Position', [0.795 0.065 0.142 0.285]);

app.controls = struct();
app.layout = struct();
app.nextSliceFigureIndex = 0;
app.layout.startY = 0.935;
app.layout.dy = 0.0195;
app.layout.sectionGap = 0.0035;

app.controls.closeAllFigsButton = uicontrol( ...
    'Parent', app.fig, ...
    'Style', 'pushbutton', ...
    'String', 'Close all figs', ...
    'Units', 'normalized', ...
    'FontWeight', 'bold', ...
    'TooltipString', 'Closes all extra slice windows and keeps the simulator open.', ...
    'Callback', @(~, ~) closeAllFigures(app.fig));

app.controls.topXYSliceLabel = uicontrol( ...
    'Parent', app.fig, ...
    'Style', 'text', ...
    'String', 'z (mm)', ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'left', ...
    'FontWeight', 'bold', ...
    'BackgroundColor', get(app.fig, 'Color'));

app.controls.topXYSliceEdit = uicontrol( ...
    'Parent', app.fig, ...
    'Style', 'edit', ...
    'String', num2str(params.xySliceZMm), ...
    'Units', 'normalized', ...
    'BackgroundColor', 'w', ...
    'TooltipString', 'Enter a z location here and press Enter to open the XY slice.', ...
    'Callback', @(src, ~) topBarXYSliceChanged(app.fig, src));

cb = @(src, ~) handleManualControlChange(app.fig, src);
y = app.layout.startY;
dy = app.layout.dy;
sectionGap = app.layout.sectionGap;

setappdata(app.fig, 'customPupilMask', params.customPupilMask);
setappdata(app.fig, 'customSourceMask', params.customSourceMask);

app.sectionTitles.examples = createSectionTitle(app.controlPanel, y, 'Examples');
y = y - dy;
app.controls.presetMenu = createPopup(app.controlPanel, y, 'Reference preset', ...
    presetNames, presetNames{1}, @(src, ~) presetSelectionChanged(src, app.fig));
set(app.controls.presetMenu, 'TooltipString', ...
    'Loads literature-guided or sanity-check settings for source, mask, and pupil.');
y = y - dy;
app.controls.showcaseMenu = createPopup(app.controlPanel, y, 'Lecture example', ...
    showcaseNames, showcaseNames{1}, @(src, ~) showcaseSelectionChanged(src, app.fig));
set(app.controls.showcaseMenu, 'TooltipString', ...
    'Loads example settings that match common lecture-style illumination demonstrations.');

y = y - sectionGap;
app.sectionTitles.source = createSectionTitle(app.controlPanel, y, 'Illumination Source');
y = y - dy;
app.controls.sourceType = createPopup(app.controlPanel, y, 'Source shape', ...
    {'Point', 'Circular', 'Square', 'Annular', 'Dipole X', 'Dipole Y', 'Quadrupole', 'Freeform'}, 'Circular', cb);
y = y - dy;
app.controls.sourceOuter = createEdit(app.controlPanel, y, 'Outer radius', params.sourceOuter, cb);
set(app.controls.sourceOuter, 'TooltipString', 'Normalized source size. Values above 1 are allowed.');
y = y - dy;
app.controls.sourceInner = createEdit(app.controlPanel, y, 'Inner radius', params.sourceInner, cb);
set(app.controls.sourceInner, 'TooltipString', 'Normalized inner radius for annular sources.');
y = y - dy;
app.controls.quadSeparation = createEdit(app.controlPanel, y, 'Quadrupole spacing', params.quadSeparation, cb);
y = y - dy;
app.controls.pointSourceU = createEdit(app.controlPanel, y, 'Point x', params.pointSourceU, cb);
set(app.controls.pointSourceU, 'TooltipString', 'Point-source x location in normalized source coordinates.');
y = y - dy;
app.controls.pointSourceV = createEdit(app.controlPanel, y, 'Point y', params.pointSourceV, cb);
set(app.controls.pointSourceV, 'TooltipString', 'Point-source y location in normalized source coordinates.');
y = y - dy;
app.controls.editSourceButton = createActionRowButton(app.controlPanel, 'Edit freeform source', ...
    @(~, ~) openFreeformSourceEditor(app.fig));
set(app.controls.editSourceButton.handle, 'TooltipString', ...
    'Open the freeform source editor. Paint the source weight directly in a separate window.');
y = y - dy;
app.controls.condenserAperture = createEdit(app.controlPanel, y, 'Cond aperture (1 = full)', params.condenserAperture, cb);
set(app.controls.condenserAperture, 'TooltipString', 'Condenser aperture stop. Smaller values stop down the illumination; values above 1 act like fully open in this model.');

y = y - sectionGap;
app.sectionTitles.mask = createSectionTitle(app.controlPanel, y, 'Mask / Object');
y = y - dy;
app.controls.maskType = createPopup(app.controlPanel, y, 'Mask shape', ...
    {'Circular Aperture', 'Square Aperture', 'Diamond Aperture', 'Annular Aperture', '1D Grating', '2D Grating', 'Cross'}, ...
    '1D Grating', cb);
y = y - dy;
app.controls.maskSizeUm = createEdit(app.controlPanel, y, 'Feature size (um)', params.maskSizeUm, cb);
y = y - dy;
app.controls.maskInnerRatio = createEdit(app.controlPanel, y, 'Inner ratio (0-1)', params.maskInnerRatio, cb);
y = y - dy;
app.controls.gratingPitchUm = createEdit(app.controlPanel, y, 'Grating pitch (um)', params.gratingPitchUm, cb);
y = y - dy;
app.controls.gratingDuty = createEdit(app.controlPanel, y, 'Grating duty (0-1)', params.gratingDuty, cb);

y = y - sectionGap;
app.sectionTitles.projection = createSectionTitle(app.controlPanel, y, 'Projection Lens');
y = y - dy;
app.controls.lensType = createPopup(app.controlPanel, y, 'Lens pupil', ...
    {'Circular', 'Annular', 'Square', 'Diamond', 'Horizontal Slit', 'Vertical Slit', 'Freeform'}, 'Circular', cb);
y = y - dy;
app.controls.editPupilButton = createActionRowButton(app.controlPanel, 'Edit freeform pupil', ...
    @(~, ~) openFreeformPupilEditor(app.fig));
set(app.controls.editPupilButton.handle, 'TooltipString', ...
    'Open the freeform pupil editor. Paint open or blocked regions directly in a separate window.');
y = y - dy;
app.controls.projNA = createEdit(app.controlPanel, y, 'Projection NA', params.projNA, cb);
y = y - dy;
app.controls.lensInner = createEdit(app.controlPanel, y, 'Lens inner radius', params.lensInner, cb);
y = y - dy;
app.controls.reduction = createEdit(app.controlPanel, y, 'Reduction factor', params.reduction, cb);

y = y - sectionGap;
app.sectionTitles.imaging = createSectionTitle(app.controlPanel, y, 'Imaging');
y = y - dy;
app.controls.wavelengthNm = createEdit(app.controlPanel, y, 'Wavelength (nm)', params.wavelengthNm, cb);
y = y - dy;
app.controls.fieldSizeUm = createEdit(app.controlPanel, y, 'Mask window (um)', params.fieldSizeUm, cb);
y = y - dy;
app.controls.defocusUm = createEdit(app.controlPanel, y, 'Defocus (um)', params.defocusUm, cb);

y = y - sectionGap;
app.sectionTitles.geometry = createSectionTitle(app.controlPanel, y, 'Geometry');
y = y - dy;
app.controls.condenserFocalMm = createEdit(app.controlPanel, y, 'Condenser f (mm)', params.condenserFocalMm, cb);
y = y - dy;
app.controls.projectionFocalMm = createEdit(app.controlPanel, y, 'Projection f (mm)', params.projectionFocalMm, cb);
y = y - dy;
app.controls.sourceToCondenserMm = createSlider(app.controlPanel, y, 'Source->Cond (mm)', ...
    20, 160, params.sourceToCondenserMm, cb);
y = y - dy;
app.controls.fieldToPupilMm = createSlider(app.controlPanel, y, 'Field->Pupil (mm)', ...
    20, 220, params.fieldToPupilMm, cb);

y = y - sectionGap;
app.sectionTitles.views = createSectionTitle(app.controlPanel, y, 'View Controls');
y = y - dy;
app.controls.rayDensity = createPopup(app.controlPanel, y, 'Ray density', ...
    {'Low', 'Medium', 'High', 'Ultra High'}, params.rayDensity, cb);
y = y - dy;
app.controls.yzMode = createPopup(app.controlPanel, y, 'YZ mode', ...
    {'Continuous', 'Multi-point'}, params.yzMode, cb);
set(app.controls.yzMode, 'TooltipString', 'Choose dense continuous integration or sparse multi-point rays for the YZ panel.');
y = y - dy;
app.controls.yzView = createPopup(app.controlPanel, y, 'YZ view', ...
    {'Raw', 'Transmitted'}, params.yzView, cb);
set(app.controls.yzView, 'TooltipString', 'Raw ignores the downstream pupil before the pupil plane. Transmitted shows only light accepted by the pupil.');
y = y - dy;
app.controls.intensityNorm = createPopup(app.controlPanel, y, 'Intensity norm', ...
    {'Local', 'XYZ'}, params.intensityNorm, cb);
set(app.controls.intensityNorm, 'TooltipString', 'Local normalizes each panel by itself. XYZ shares one scale between the YZ panel and approximate XY slices; exact named planes stay local so they remain visible.');
y = y - dy;
app.controls.xySliceZMm = createEdit(app.controlPanel, y, 'XY slice z (mm)', params.xySliceZMm, ...
    @(~, ~) plotXYSliceFromInput(app.fig));
set(app.controls.xySliceZMm, 'TooltipString', 'Press Enter here to open the XY slice at this z location, including a short distance beyond the image plane.');

app.controls.updateButton = uicontrol( ...
    'Parent', app.controlPanel, ...
    'Style', 'pushbutton', ...
    'String', 'Update', ...
    'Units', 'normalized', ...
    'FontWeight', 'bold', ...
    'Callback', cb);

app.controls.resetButton = uicontrol( ...
    'Parent', app.controlPanel, ...
    'Style', 'pushbutton', ...
    'String', 'Reset', ...
    'Units', 'normalized', ...
    'FontWeight', 'bold', ...
    'Callback', @(~, ~) resetControls(app.fig));

app.controls.updateYZButton = uicontrol( ...
    'Parent', app.controlPanel, ...
    'Style', 'pushbutton', ...
    'String', 'Update YZ', ...
    'Units', 'normalized', ...
    'FontWeight', 'bold', ...
    'TooltipString', 'Computes the YZ propagation panel only when pressed.', ...
    'Callback', @(~, ~) updateYZPlot(app.fig));

app.controls.autoYZButton = uicontrol( ...
    'Parent', app.controlPanel, ...
    'Style', 'togglebutton', ...
    'String', 'Auto YZ: Off', ...
    'Units', 'normalized', ...
    'FontWeight', 'bold', ...
    'TooltipString', 'When on, the YZ panel updates automatically after each control change.', ...
    'Value', double(params.autoYZ), ...
    'Callback', @(src, ~) toggleAutoYZ(src, app.fig));
updateAutoYZButtonLabel(app.controls.autoYZButton);

app.controls.infoBox = uicontrol( ...
    'Parent', app.controlPanel, ...
    'Style', 'edit', ...
    'Units', 'normalized', ...
    'Max', 16, ...
    'Min', 0, ...
    'Enable', 'inactive', ...
    'HorizontalAlignment', 'left', ...
    'BackgroundColor', [1.0 0.98 0.90], ...
    'String', '', ...
    'FontSize', 8);

app.controls.infoBadge = uicontrol( ...
    'Parent', app.controlPanel, ...
    'Style', 'text', ...
    'Units', 'normalized', ...
    'String', 'Status: OK', ...
    'HorizontalAlignment', 'center', ...
    'FontWeight', 'bold', ...
    'FontSize', 8, ...
    'BackgroundColor', [0.89 0.97 0.90]);

app.controls.actionsTitle = uicontrol( ...
    'Parent', app.controlPanel, ...
    'Style', 'text', ...
    'Units', 'normalized', ...
    'String', 'Actions', ...
    'HorizontalAlignment', 'left', ...
    'FontWeight', 'bold', ...
    'BackgroundColor', get(app.controlPanel, 'BackgroundColor'));

app.layout.sections = { ...
    struct('title', app.sectionTitles.examples, 'rows', {{ ...
        rowSpec('presetMenu', 'popup')
        rowSpec('showcaseMenu', 'popup')
    }}), ...
    struct('title', app.sectionTitles.source, 'rows', {{ ...
        rowSpec('sourceType', 'popup')
        rowSpec('sourceOuter', 'edit')
        rowSpec('sourceInner', 'edit')
        rowSpec('quadSeparation', 'edit')
        rowSpec('pointSourceU', 'edit')
        rowSpec('pointSourceV', 'edit')
        rowSpec('editSourceButton', 'button')
        rowSpec('condenserAperture', 'edit')
    }}), ...
    struct('title', app.sectionTitles.mask, 'rows', {{ ...
        rowSpec('maskType', 'popup')
        rowSpec('maskSizeUm', 'edit')
        rowSpec('maskInnerRatio', 'edit')
        rowSpec('gratingPitchUm', 'edit')
        rowSpec('gratingDuty', 'edit')
    }}), ...
    struct('title', app.sectionTitles.projection, 'rows', {{ ...
        rowSpec('lensType', 'popup')
        rowSpec('editPupilButton', 'button')
        rowSpec('projNA', 'edit')
        rowSpec('lensInner', 'edit')
        rowSpec('reduction', 'edit')
    }}), ...
    struct('title', app.sectionTitles.imaging, 'rows', {{ ...
        rowSpec('wavelengthNm', 'edit')
        rowSpec('fieldSizeUm', 'edit')
        rowSpec('defocusUm', 'edit')
    }}), ...
    struct('title', app.sectionTitles.geometry, 'rows', {{ ...
        rowSpec('condenserFocalMm', 'edit')
        rowSpec('projectionFocalMm', 'edit')
        rowSpec('sourceToCondenserMm', 'slider')
        rowSpec('fieldToPupilMm', 'slider')
    }}), ...
    struct('title', app.sectionTitles.views, 'rows', {{ ...
        rowSpec('rayDensity', 'popup')
        rowSpec('yzMode', 'popup')
        rowSpec('yzView', 'popup')
        rowSpec('intensityNorm', 'popup')
        rowSpec('xySliceZMm', 'edit')
    }}) ...
};

guidata(app.fig, app);
refreshControlLayout(app.fig);
updatePlots(app.fig);
end

function spec = rowSpec(id, rowType)
spec = struct('id', id, 'type', rowType);
end

function handle = createSectionTitle(parentHandle, y, titleText)
handle = uicontrol( ...
    'Parent', parentHandle, ...
    'Style', 'text', ...
    'String', titleText, ...
    'Units', 'normalized', ...
    'Position', [0.06 y 0.88 0.022], ...
    'HorizontalAlignment', 'left', ...
    'FontWeight', 'bold', ...
    'BackgroundColor', get(parentHandle, 'BackgroundColor'));
end

function handle = createPopup(parentHandle, y, labelText, items, defaultItem, callbackFcn)
labelHandle = uicontrol( ...
    'Parent', parentHandle, ...
    'Style', 'text', ...
    'String', labelText, ...
    'Units', 'normalized', ...
    'Position', [0.06 y 0.42 0.020], ...
    'HorizontalAlignment', 'left', ...
    'BackgroundColor', get(parentHandle, 'BackgroundColor'));

defaultIndex = find(strcmp(items, defaultItem), 1);
if isempty(defaultIndex)
    defaultIndex = 1;
end

handle = uicontrol( ...
    'Parent', parentHandle, ...
    'Style', 'popupmenu', ...
    'String', items, ...
    'Value', defaultIndex, ...
    'Units', 'normalized', ...
    'Position', [0.49 y 0.43 0.022], ...
    'FontSize', 9, ...
    'Callback', callbackFcn);

setappdata(handle, 'labelHandle', labelHandle);
end

function handle = createEdit(parentHandle, y, labelText, value, callbackFcn)
labelHandle = uicontrol( ...
    'Parent', parentHandle, ...
    'Style', 'text', ...
    'String', labelText, ...
    'Units', 'normalized', ...
    'Position', [0.06 y 0.42 0.020], ...
    'HorizontalAlignment', 'left', ...
    'BackgroundColor', get(parentHandle, 'BackgroundColor'));

handle = uicontrol( ...
    'Parent', parentHandle, ...
    'Style', 'edit', ...
    'String', num2str(value), ...
    'Units', 'normalized', ...
    'Position', [0.54 y 0.38 0.022], ...
    'BackgroundColor', [1 1 1], ...
    'FontSize', 9, ...
    'Callback', callbackFcn);

setappdata(handle, 'labelHandle', labelHandle);
end

function control = createActionRowButton(parentHandle, buttonText, callbackFcn)
control.kind = 'button';
control.handle = uicontrol( ...
    'Parent', parentHandle, ...
    'Style', 'pushbutton', ...
    'String', buttonText, ...
    'Units', 'normalized', ...
    'FontWeight', 'bold', ...
    'Callback', callbackFcn);
end

function control = createSlider(parentHandle, y, labelText, minValue, maxValue, value, callbackFcn)
control.label = uicontrol( ...
    'Parent', parentHandle, ...
    'Style', 'text', ...
    'String', labelText, ...
    'Units', 'normalized', ...
    'Position', [0.06 y 0.42 0.022], ...
    'HorizontalAlignment', 'left', ...
    'BackgroundColor', get(parentHandle, 'BackgroundColor'));

control.valueText = uicontrol( ...
    'Parent', parentHandle, ...
    'Style', 'text', ...
    'String', sprintf('%.0f', value), ...
    'Units', 'normalized', ...
    'Position', [0.84 y 0.10 0.022], ...
    'HorizontalAlignment', 'right', ...
    'BackgroundColor', get(parentHandle, 'BackgroundColor'));

sliderStepSmall = min(1 / max(1, (maxValue - minValue)), 0.1);
sliderStepLarge = min(10 / max(1, (maxValue - minValue)), 0.3);
control.slider = uicontrol( ...
    'Parent', parentHandle, ...
    'Style', 'slider', ...
    'Min', minValue, ...
    'Max', maxValue, ...
    'Value', value, ...
    'SliderStep', [sliderStepSmall sliderStepLarge], ...
    'Units', 'normalized', ...
    'Position', [0.44 y + 0.003 0.38 0.020], ...
    'Callback', @(src, evt) sliderCallback(src, evt, control.valueText, callbackFcn));
end

function sliderCallback(src, ~, valueTextHandle, callbackFcn)
set(valueTextHandle, 'String', sprintf('%.0f', get(src, 'Value')));
callbackFcn(src, []);
end

function handleManualControlChange(figHandle, srcHandle)
app = guidata(figHandle);
if isfield(app.controls, 'presetMenu')
    setPopupValue(app.controls.presetMenu, 'Custom');
end
if isfield(app.controls, 'showcaseMenu')
    setPopupValue(app.controls.showcaseMenu, 'None');
end
if nargin >= 2 && isequal(srcHandle, controlHandle(app.controls.lensType)) && ...
        strcmp(popupText(app.controls.lensType), 'Freeform')
    openFreeformPupilEditor(figHandle);
    return;
end
if nargin >= 2 && isequal(srcHandle, controlHandle(app.controls.sourceType)) && ...
        strcmp(popupText(app.controls.sourceType), 'Freeform')
    openFreeformSourceEditor(figHandle);
    return;
end
updatePlots(figHandle);
end

function presetSelectionChanged(src, figHandle)
items = get(src, 'String');
selected = items{get(src, 'Value')};
if strcmp(selected, 'Custom')
    return;
end
applyLibraryPreset(figHandle, selected, 'reference');
end

function showcaseSelectionChanged(src, figHandle)
items = get(src, 'String');
selected = items{get(src, 'Value')};
if strcmp(selected, 'None')
    return;
end
applyLibraryPreset(figHandle, selected, 'showcase');
end

function applyLibraryPreset(figHandle, presetName, libraryKind)
app = guidata(figHandle);
switch libraryKind
    case 'showcase'
        presets = lithography_showcase_library();
        menuField = 'showcaseMenu';
        otherMenuField = 'presetMenu';
        otherValue = 'Custom';
    otherwise
        presets = lithography_preset_library();
        menuField = 'presetMenu';
        otherMenuField = 'showcaseMenu';
        otherValue = 'None';
end

matchIdx = find(strcmp({presets.name}, presetName), 1);
if isempty(matchIdx) || isempty(presets(matchIdx).params)
    return;
end

setPopupValue(app.controls.(menuField), presets(matchIdx).name);
if isfield(app.controls, otherMenuField)
    setPopupValue(app.controls.(otherMenuField), otherValue);
end
applyParamsToControls(figHandle, presets(matchIdx).params);
end

function applyParamsToControls(figHandle, params)
applyParamsToControlsInternal(figHandle, params, true);
end

function applyParamsToControlsInternal(figHandle, params, doUpdate)
app = guidata(figHandle);

setPopupValue(app.controls.sourceType, params.sourceType);
setEditValue(app.controls.sourceOuter, params.sourceOuter);
setEditValue(app.controls.sourceInner, params.sourceInner);
setEditValue(app.controls.quadSeparation, params.quadSeparation);
setEditValue(app.controls.pointSourceU, params.pointSourceU);
setEditValue(app.controls.pointSourceV, params.pointSourceV);
setEditValue(app.controls.condenserAperture, params.condenserAperture);

setPopupValue(app.controls.maskType, params.maskType);
setEditValue(app.controls.maskSizeUm, params.maskSizeUm);
setEditValue(app.controls.maskInnerRatio, params.maskInnerRatio);
setEditValue(app.controls.gratingPitchUm, params.gratingPitchUm);
setEditValue(app.controls.gratingDuty, params.gratingDuty);

setPopupValue(app.controls.lensType, params.lensType);
setEditValue(app.controls.projNA, params.projNA);
setEditValue(app.controls.lensInner, params.lensInner);
setEditValue(app.controls.reduction, params.reduction);

setEditValue(app.controls.wavelengthNm, params.wavelengthNm);
setEditValue(app.controls.fieldSizeUm, params.fieldSizeUm);
setEditValue(app.controls.defocusUm, params.defocusUm);
setEditValue(app.controls.condenserFocalMm, params.condenserFocalMm);
setEditValue(app.controls.projectionFocalMm, params.projectionFocalMm);
setSliderValue(app.controls.sourceToCondenserMm, params.sourceToCondenserMm);
setSliderValue(app.controls.fieldToPupilMm, params.fieldToPupilMm);
setEditValue(app.controls.xySliceZMm, params.xySliceZMm);
setEditValue(app.controls.topXYSliceEdit, params.xySliceZMm);
setPopupValue(app.controls.rayDensity, params.rayDensity);
setPopupValue(app.controls.yzMode, params.yzMode);
setPopupValue(app.controls.yzView, params.yzView);
if isfield(params, 'intensityNorm') && ~isempty(params.intensityNorm)
    setPopupValue(app.controls.intensityNorm, params.intensityNorm);
else
    setPopupValue(app.controls.intensityNorm, 'Local');
end

if isfield(params, 'customPupilMask') && ~isempty(params.customPupilMask)
    setappdata(figHandle, 'customPupilMask', params.customPupilMask);
end
if isfield(params, 'customSourceMask') && ~isempty(params.customSourceMask)
    setappdata(figHandle, 'customSourceMask', params.customSourceMask);
end

refreshControlLayout(figHandle);
if nargin < 3 || doUpdate
    updatePlots(figHandle);
end
end

function openFreeformSourceEditor(figHandle)
app = guidata(figHandle);
if isappdata(figHandle, 'customSourceMask')
    initialMask = getappdata(figHandle, 'customSourceMask');
else
    initialMask = lithography_default_custom_source();
end
set(figHandle, 'Pointer', 'watch');
drawnow;
[newMask, accepted] = lithography_edit_freeform_source(initialMask);
set(figHandle, 'Pointer', 'arrow');
if accepted
    setappdata(figHandle, 'customSourceMask', newMask);
end
if isfield(app.controls, 'presetMenu')
    setPopupValue(app.controls.presetMenu, 'Custom');
end
if isfield(app.controls, 'showcaseMenu')
    setPopupValue(app.controls.showcaseMenu, 'None');
end
updatePlots(figHandle);
end

function openFreeformPupilEditor(figHandle)
app = guidata(figHandle);
if isappdata(figHandle, 'customPupilMask')
    initialMask = getappdata(figHandle, 'customPupilMask');
else
    initialMask = lithography_default_custom_pupil();
end
set(figHandle, 'Pointer', 'watch');
drawnow;
[newMask, accepted] = lithography_edit_freeform_pupil(initialMask);
set(figHandle, 'Pointer', 'arrow');
if accepted
    setappdata(figHandle, 'customPupilMask', newMask);
end
if isfield(app.controls, 'presetMenu')
    setPopupValue(app.controls.presetMenu, 'Custom');
end
if isfield(app.controls, 'showcaseMenu')
    setPopupValue(app.controls.showcaseMenu, 'None');
end
updatePlots(figHandle);
end

function resetControls(figHandle)
app = guidata(figHandle);
params = lithography_default_params();

setPopupValue(app.controls.presetMenu, 'Custom');
setPopupValue(app.controls.showcaseMenu, 'None');
applyParamsToControlsInternal(figHandle, params, false);
set(app.controls.autoYZButton, 'Value', double(params.autoYZ));
updateAutoYZButtonLabel(app.controls.autoYZButton);
setappdata(figHandle, 'customSourceMask', params.customSourceMask);
setappdata(figHandle, 'customPupilMask', params.customPupilMask);
refreshControlLayout(figHandle);
updatePlots(figHandle);
end

function setEditValue(handle, value)
set(handle, 'String', num2str(value));
end

function setPopupValue(handle, targetText)
items = get(handle, 'String');
idx = find(strcmp(items, targetText), 1);
if isempty(idx)
    idx = 1;
end
set(handle, 'Value', idx);
end

function setSliderValue(control, value)
set(control.slider, 'Value', value);
set(control.valueText, 'String', sprintf('%.0f', value));
end

function updatePlots(figHandle)
refreshControlLayout(figHandle);
app = guidata(figHandle);
params = lithography_collect_input(app);
setEditValue(app.controls.xySliceZMm, params.xySliceZMm);
setEditValue(app.controls.topXYSliceEdit, params.xySliceZMm);
result = lithography_run_physics(params);
if ~isfield(app, 'lastYZParams') || isempty(app.lastYZParams) || ~isequaln(app.lastYZParams, params)
    app.lastYZ = [];
    app.lastYZParams = [];
end
app.lastResult = result;
app.lastParams = params;
guidata(figHandle, app);

lithography_render_panels(app, params, result);
updateInfoBox(figHandle, params, result);
yzIsCurrent = isfield(app, 'lastYZ') && ~isempty(app.lastYZ) && ...
    isfield(app, 'lastYZParams') && isequaln(app.lastYZParams, params);
if autoYZEnabled(app)
    if yzIsCurrent
        lithography_render_yz_panel(app.axYZ, app.lastYZ);
    else
        app = computeAndRenderYZ(figHandle, app, params, result);
    end
elseif yzIsCurrent
    lithography_render_yz_panel(app.axYZ, app.lastYZ);
else
    lithography_render_yz_panel(app.axYZ, []);
end
armYZInteraction(figHandle);
drawnow;
end

function updateYZPlot(figHandle)
app = guidata(figHandle);
params = lithography_collect_input(app);

if isfield(app, 'lastResult') && isfield(app, 'lastParams') && isequaln(app.lastParams, params)
    result = app.lastResult;
else
    result = lithography_run_physics(params);
    app.lastResult = result;
    app.lastParams = params;
end

set(figHandle, 'Pointer', 'watch');
drawnow;
try
    app = computeAndRenderYZ(figHandle, app, params, result);
    armYZInteraction(figHandle);
    drawnow;
catch err
    set(figHandle, 'Pointer', 'arrow');
    rethrow(err);
end
set(figHandle, 'Pointer', 'arrow');
end

function app = computeAndRenderYZ(figHandle, app, params, result)
yzData = lithography_compute_yz_intensity(params, result);
app.lastYZ = yzData;
app.lastYZParams = params;
guidata(figHandle, app);
lithography_render_yz_panel(app.axYZ, yzData);
end

function toggleAutoYZ(toggleHandle, figHandle)
updateAutoYZButtonLabel(toggleHandle);
updatePlots(figHandle);
end

function updateAutoYZButtonLabel(toggleHandle)
if get(toggleHandle, 'Value') > 0
    set(toggleHandle, 'String', 'Auto YZ: On');
else
    set(toggleHandle, 'String', 'Auto YZ: Off');
end
end

function enabled = autoYZEnabled(app)
enabled = isfield(app.controls, 'autoYZButton') && get(app.controls.autoYZButton, 'Value') > 0;
end

function armYZInteraction(figHandle)
app = guidata(figHandle);
if ~isfield(app, 'axYZ') || ~ishandle(app.axYZ)
    return;
end

if isprop(app.axYZ, 'PickableParts')
    set(app.axYZ, 'PickableParts', 'all');
end
if isprop(app.axYZ, 'HitTest')
    set(app.axYZ, 'HitTest', 'on');
end
set(app.axYZ, 'ButtonDownFcn', @(~, ~) handleYZClick(figHandle));
children = findall(app.axYZ);
for k = 1:numel(children)
    if children(k) == app.axYZ
        continue;
    end
    if isprop(children(k), 'HitTest')
        set(children(k), 'HitTest', 'off');
    end
    if isprop(children(k), 'PickableParts')
        set(children(k), 'PickableParts', 'none');
    end
end
end

function handleYZClick(figHandle)
app = guidata(figHandle);
if ~isfield(app, 'lastYZ') || isempty(app.lastYZ)
    return;
end

point = get(app.axYZ, 'CurrentPoint');
zSelected = point(1, 1);
ySelected = point(1, 2);
xLimits = xlim(app.axYZ);
yLimits = ylim(app.axYZ);
if zSelected < xLimits(1) || zSelected > xLimits(2) || ySelected < yLimits(1) || ySelected > yLimits(2)
    return;
end
if zSelected < app.lastYZ.planes.source
    return;
end

zSelected = snapYZClickToPlane(zSelected, app.lastYZ.planes);

params = app.lastYZParams;
if isfield(app, 'lastResult') && isfield(app, 'lastParams') && isequaln(app.lastParams, params)
    result = app.lastResult;
else
    result = lithography_run_physics(params);
    app.lastResult = result;
    app.lastParams = params;
    guidata(figHandle, app);
end

sharedPeak = sharedIntensityPeakForXY(figHandle, params, result);
slice = lithography_compute_xy_slice(params, result, zSelected, sharedPeak);
showXYSliceFigure(slice, figHandle);
end

function zSelected = snapYZClickToPlane(zSelected, planes)
planeValues = [planes.source, planes.field, planes.pupil, planes.image];
snapToleranceMm = 0.2;
[minDistance, idx] = min(abs(planeValues - zSelected));
if minDistance <= snapToleranceMm
    zSelected = planeValues(idx);
end
end

function plotXYSliceFromInput(figHandle)
app = guidata(figHandle);
params = lithography_collect_input(app);
zSelected = params.xySliceZMm;
setEditValue(app.controls.xySliceZMm, zSelected);
setEditValue(app.controls.topXYSliceEdit, zSelected);

if isfield(app, 'lastResult') && isfield(app, 'lastParams') && isequaln(app.lastParams, params)
    result = app.lastResult;
else
    result = lithography_run_physics(params);
    app.lastResult = result;
    app.lastParams = params;
    guidata(figHandle, app);
end

sharedPeak = sharedIntensityPeakForXY(figHandle, params, result);
slice = lithography_compute_xy_slice(params, result, zSelected, sharedPeak);
showXYSliceFigure(slice, figHandle);
end

function topBarXYSliceChanged(figHandle, editHandle)
app = guidata(figHandle);
rawValue = str2double(get(editHandle, 'String'));
if ~isfinite(rawValue)
    params = lithography_collect_input(app);
    rawValue = params.xySliceZMm;
end
setEditValue(app.controls.xySliceZMm, rawValue);
setEditValue(app.controls.topXYSliceEdit, rawValue);
plotXYSliceFromInput(figHandle);
end

function sharedPeak = sharedIntensityPeakForXY(figHandle, params, result)
sharedPeak = [];
if ~isfield(params, 'intensityNorm') || ~strcmp(params.intensityNorm, 'XYZ')
    return;
end

app = guidata(figHandle);
if isfield(app, 'lastYZ') && ~isempty(app.lastYZ) && ...
        isfield(app, 'lastYZParams') && isequaln(app.lastYZParams, params) && ...
        isfield(app.lastYZ, 'normalizationPeak') && isfinite(app.lastYZ.normalizationPeak)
    sharedPeak = app.lastYZ.normalizationPeak;
    return;
end

yzData = lithography_compute_yz_intensity(params, result);
sharedPeak = yzData.normalizationPeak;
if isstruct(app)
    app.lastYZ = yzData;
    app.lastYZParams = params;
    guidata(figHandle, app);
end
end

function fig = showXYSliceFigure(slice, mainFigHandle, varargin)
visibleState = 'on';
if nargin >= 3 && ~isempty(varargin{1})
    visibleState = varargin{1};
end

figPosition = nextSliceFigurePosition(mainFigHandle);
fig = figure( ...
    'Name', sprintf('XY slice at z = %.3f mm', slice.zMm), ...
    'NumberTitle', 'off', ...
    'Color', 'w', ...
    'Tag', 'LithographyXYSlice', ...
    'Position', figPosition, ...
    'Visible', visibleState);
ax = axes('Parent', fig);
axisValues = slice.axis(:)';
imagesc(ax, [axisValues(1) axisValues(end)], [axisValues(1) axisValues(end)], slice.intensity);
axis(ax, 'image');
set(ax, 'YDir', 'normal');
colormap(ax, turbo(256));
caxis(ax, [0 1]);
if isfield(slice, 'titleText') && ~isempty(slice.titleText)
    normLabel = 'Local norm';
    if isfield(slice, 'normalizationMode') && strcmp(slice.normalizationMode, 'XYZ')
        normLabel = 'XYZ norm';
    end
    title(ax, sprintf('%s (exact, %s)', slice.titleText, normLabel), 'FontSize', 11);
else
    exactLabel = 'approx';
    if isfield(slice, 'isExact') && slice.isExact
        exactLabel = 'exact';
    end
    normLabel = 'Local norm';
    if isfield(slice, 'normalizationMode') && strcmp(slice.normalizationMode, 'XYZ')
        normLabel = 'XYZ norm';
    end
    title(ax, sprintf('XY intensity at z = %.3f mm (%s, %s, %s, %s)', ...
        slice.zMm, slice.stageLabel, slice.mode, exactLabel, normLabel), 'FontSize', 11);
end
if isfield(slice, 'xlabelText') && ~isempty(slice.xlabelText)
    xlabel(ax, slice.xlabelText, 'FontSize', 10);
else
    xlabel(ax, 'normalized x', 'FontSize', 10);
end
if isfield(slice, 'ylabelText') && ~isempty(slice.ylabelText)
    ylabel(ax, slice.ylabelText, 'FontSize', 10);
else
    ylabel(ax, 'normalized y', 'FontSize', 10);
end
set(ax, 'FontSize', 9);
cb = colorbar(ax, 'eastoutside');
if isfield(slice, 'normalizationMode') && strcmp(slice.normalizationMode, 'XYZ')
    cb.Label.String = 'Normalized intensity (XYZ)';
else
    cb.Label.String = 'Normalized intensity';
end
cb.Ticks = [0 0.5 1];
cb.FontSize = 8;
cb.Label.FontSize = 8;
end

function figPosition = nextSliceFigurePosition(mainFigHandle)
defaultSize = [560 500];
gap = 24;

screenSize = get(groot, 'ScreenSize');
gridLeft = screenSize(1) + 20;
gridTop = screenSize(2) + screenSize(4) - 80;
numCols = max(1, floor((screenSize(3) - 40 + gap) / (defaultSize(1) + gap)));
numRows = max(1, floor((screenSize(4) - 140 + gap) / (defaultSize(2) + gap)));
slotCount = max(1, numCols * numRows);

windowIndex = 0;
if nargin >= 1 && ishghandle(mainFigHandle)
    app = guidata(mainFigHandle);
    if isfield(app, 'nextSliceFigureIndex')
        windowIndex = app.nextSliceFigureIndex;
        app.nextSliceFigureIndex = app.nextSliceFigureIndex + 1;
        guidata(mainFigHandle, app);
    end
end

slotIndex = mod(windowIndex, slotCount);
row = floor(slotIndex / numCols);
col = mod(slotIndex, numCols);

left = gridLeft + col * (defaultSize(1) + gap);
bottom = gridTop - defaultSize(2) - row * (defaultSize(2) + gap);
figPosition = [left, bottom, defaultSize(1), defaultSize(2)];
end

function closeSecondaryFigures(mainFigHandle)
sliceFigs = findall(groot, 'Type', 'figure', 'Tag', 'LithographyXYSlice');
editorFigs = findall(groot, 'Type', 'figure', 'Tag', 'LithographyFreeformEditor');
figs = [sliceFigs(:); editorFigs(:)];
for k = 1:numel(figs)
    if nargin >= 1 && figs(k) == mainFigHandle
        continue;
    end
    if ishghandle(figs(k))
        close(figs(k));
    end
end

if nargin >= 1 && ishghandle(mainFigHandle)
    app = guidata(mainFigHandle);
    if isstruct(app)
        app.nextSliceFigureIndex = 0;
        guidata(mainFigHandle, app);
    end
end
end

function closeAllFigures(mainFigHandle)
closeSecondaryFigures(mainFigHandle);
end

function refreshControlLayout(figHandle)
app = guidata(figHandle);
updateDynamicLabels(app);
vis = controlVisibility(app);

y = app.layout.startY;
dy = app.layout.dy;
sectionGap = app.layout.sectionGap;

for s = 1:numel(app.layout.sections)
    section = app.layout.sections{s};
    rows = section.rows;
    visibleRows = false(1, numel(rows));
    for r = 1:numel(rows)
        visibleRows(r) = vis.(rows{r}.id);
        setRowVisible(app.controls.(rows{r}.id), visibleRows(r));
    end

    titleVisible = any(visibleRows);
    set(section.title, 'Visible', onOff(titleVisible));
    if ~titleVisible
        continue;
    end

    set(section.title, 'Position', [0.06 y 0.88 0.022]);
    y = y - dy;

    for r = 1:numel(rows)
        if ~visibleRows(r)
            continue;
        end
        applyRowPosition(app.controls.(rows{r}.id), rows{r}.type, y);
        y = y - dy;
    end

    y = y - sectionGap;
end

infoBoxY = 0.010;
infoBadgeHeight = 0.024;
infoGap = 0.004;
infoBoxHeight = 0.170;
set(app.controls.infoBadge, 'Position', [0.06 infoBoxY + infoBoxHeight + infoGap 0.88 infoBadgeHeight]);
set(app.controls.infoBox, 'Position', [0.06 infoBoxY 0.88 infoBoxHeight]);

buttonHeight = 0.035;
buttonGap = 0.007;
actionBlockGap = 0.020;
actionBottomMin = infoBoxY + infoBoxHeight + infoBadgeHeight + infoGap + 0.012;
actionBlockHeight = 2 * buttonHeight + buttonGap;
actionRowBottom = max(actionBottomMin, y - (actionBlockHeight + actionBlockGap));
actionRowTop = actionRowBottom + buttonHeight + buttonGap;
set(app.controls.actionsTitle, 'Visible', 'off');
set(app.controls.updateButton, 'Position', [0.08 actionRowTop 0.38 buttonHeight], 'FontSize', 9);
set(app.controls.resetButton, 'Position', [0.54 actionRowTop 0.38 buttonHeight], 'FontSize', 9);
set(app.controls.updateYZButton, 'Position', [0.08 actionRowBottom 0.38 buttonHeight], 'FontSize', 9);
set(app.controls.autoYZButton, 'Position', [0.54 actionRowBottom 0.38 buttonHeight], 'FontSize', 9);

yzPos = get(app.axYZ, 'Position');
topBarY = yzPos(2) + yzPos(4) + 0.004;
closeButtonWidth = 0.090;
closeButtonHeight = 0.026;
closeButtonX = yzPos(1) + 0.012;
topSliceLabelWidth = 0.034;
topSliceEditWidth = 0.050;
topSliceGap = 0.004;
topSliceLabelX = closeButtonX + closeButtonWidth + 0.014;
topSliceEditX = topSliceLabelX + topSliceLabelWidth + topSliceGap;
set(app.controls.closeAllFigsButton, ...
    'Position', [closeButtonX topBarY closeButtonWidth closeButtonHeight], ...
    'FontSize', 9, ...
    'Visible', 'on');
set(app.controls.topXYSliceLabel, ...
    'Position', [topSliceLabelX topBarY + 0.001 topSliceLabelWidth 0.022], ...
    'FontSize', 9, ...
    'Visible', 'on');
set(app.controls.topXYSliceEdit, ...
    'Position', [topSliceEditX topBarY topSliceEditWidth closeButtonHeight], ...
    'FontSize', 9, ...
    'Visible', 'on');
end

function vis = controlVisibility(app)
sourceType = popupText(app.controls.sourceType);
maskType = popupText(app.controls.maskType);
lensType = popupText(app.controls.lensType);

vis = struct();
vis.presetMenu = true;
vis.showcaseMenu = true;
vis.sourceType = true;
vis.sourceOuter = any(strcmp(sourceType, {'Circular', 'Square', 'Annular', 'Dipole X', 'Dipole Y'}));
vis.sourceInner = strcmp(sourceType, 'Annular');
vis.quadSeparation = any(strcmp(sourceType, {'Dipole X', 'Dipole Y', 'Quadrupole'}));
vis.pointSourceU = strcmp(sourceType, 'Point');
vis.pointSourceV = strcmp(sourceType, 'Point');
vis.editSourceButton = strcmp(sourceType, 'Freeform');
vis.condenserAperture = true;

vis.maskType = true;
vis.maskSizeUm = any(strcmp(maskType, {'Circular Aperture', 'Square Aperture', 'Diamond Aperture', 'Annular Aperture', '1D Grating', '2D Grating', 'Cross'}));
vis.maskInnerRatio = strcmp(maskType, 'Annular Aperture');
vis.gratingPitchUm = any(strcmp(maskType, {'1D Grating', '2D Grating'}));
vis.gratingDuty = any(strcmp(maskType, {'1D Grating', '2D Grating'}));

vis.lensType = true;
vis.editPupilButton = strcmp(lensType, 'Freeform');
vis.projNA = true;
vis.lensInner = any(strcmp(lensType, {'Annular', 'Horizontal Slit', 'Vertical Slit'}));
vis.reduction = true;

vis.wavelengthNm = true;
vis.fieldSizeUm = true;
vis.defocusUm = true;

vis.condenserFocalMm = true;
vis.projectionFocalMm = true;
vis.sourceToCondenserMm = true;
vis.fieldToPupilMm = true;
vis.xySliceZMm = true;
vis.rayDensity = true;
vis.yzMode = true;
vis.yzView = true;
vis.intensityNorm = true;
end

function applyRowPosition(control, rowType, y)
switch rowType
    case {'edit', 'popup'}
        labelHandle = getappdata(control, 'labelHandle');
        set(labelHandle, 'Position', [0.06 y 0.42 0.020]);
        set(control, 'Position', [0.49 y 0.43 0.022]);

    case 'slider'
        set(control.label, 'Position', [0.06 y 0.42 0.022]);
        set(control.slider, 'Position', [0.44 y + 0.003 0.38 0.020]);
        set(control.valueText, 'Position', [0.84 y 0.10 0.022]);

    case 'button'
        set(control.handle, 'Position', [0.08 y 0.84 0.024]);
end
end

function setRowVisible(control, isVisible)
state = onOff(isVisible);
if isstruct(control)
    if isfield(control, 'kind') && strcmp(control.kind, 'button')
        set(control.handle, 'Visible', state);
    else
        set(control.label, 'Visible', state);
        set(control.slider, 'Visible', state);
        set(control.valueText, 'Visible', state);
    end
else
    labelHandle = getappdata(control, 'labelHandle');
    if ~isempty(labelHandle)
        set(labelHandle, 'Visible', state);
    end
    set(control, 'Visible', state);
end
end

function handle = controlHandle(control)
if isstruct(control)
    if isfield(control, 'handle')
        handle = control.handle;
    else
        handle = control.slider;
    end
else
    handle = control;
end
end

function updateDynamicLabels(app)
sourceType = popupText(app.controls.sourceType);
maskType = popupText(app.controls.maskType);
lensType = popupText(app.controls.lensType);

switch sourceType
    case 'Square'
        setControlLabel(app.controls.sourceOuter, 'Half width');
    case {'Dipole X', 'Dipole Y'}
        setControlLabel(app.controls.sourceOuter, 'Lobe radius');
    otherwise
        setControlLabel(app.controls.sourceOuter, 'Outer radius');
end

setControlLabel(app.controls.sourceInner, 'Inner radius');
setControlLabel(app.controls.pointSourceU, 'Point x');
setControlLabel(app.controls.pointSourceV, 'Point y');
switch sourceType
    case {'Dipole X', 'Dipole Y'}
        setControlLabel(app.controls.quadSeparation, 'Dipole spacing');
    otherwise
        setControlLabel(app.controls.quadSeparation, 'Quadrupole spacing');
end

switch maskType
    case 'Annular Aperture'
        setControlLabel(app.controls.maskSizeUm, 'Outer diameter (um)');
    case {'1D Grating', '2D Grating'}
        setControlLabel(app.controls.maskSizeUm, 'Grating size (um)');
    otherwise
        setControlLabel(app.controls.maskSizeUm, 'Feature size (um)');
end

switch lensType
    case 'Annular'
        setControlLabel(app.controls.lensInner, 'Lens inner radius');
    case {'Horizontal Slit', 'Vertical Slit'}
        setControlLabel(app.controls.lensInner, 'Slit half-width');
    otherwise
        setControlLabel(app.controls.lensInner, 'Lens inner radius');
end
end

function setControlLabel(control, textValue)
if isstruct(control)
    set(control.label, 'String', textValue);
else
    labelHandle = getappdata(control, 'labelHandle');
    set(labelHandle, 'String', textValue);
end
end

function updateInfoBox(figHandle, params, result)
app = guidata(figHandle);
if ~isfield(app.controls, 'infoBox')
    return;
end

info = lithography_artifact_warnings(params, result);
lines = {};

if isfield(app.controls, 'presetMenu')
    presetName = popupText(app.controls.presetMenu);
    if ~strcmp(presetName, 'Custom')
        lines{end + 1} = sprintf('Preset: %s', presetName);
    end
end

if isfield(app.controls, 'showcaseMenu')
    showcaseName = popupText(app.controls.showcaseMenu);
    if ~strcmp(showcaseName, 'None')
        lines{end + 1} = sprintf('Example: %s', showcaseName);
    end
end

if isfield(result, 'sourceUsedCount') && isfield(result, 'sourceActiveCount')
    lines{end + 1} = sprintf('Sampling: %d / %d source pixels', ...
        result.sourceUsedCount, result.sourceActiveCount);
end
if isfield(result, 'pupilConsistencyError')
    lines{end + 1} = sprintf('Pupil error: %.3f', result.pupilConsistencyError);
end
if isfield(params, 'intensityNorm')
    if strcmp(params.intensityNorm, 'XYZ')
        lines{end + 1} = 'Norm: XYZ (YZ + beam-path XY)';
    else
        lines{end + 1} = sprintf('Norm: %s', params.intensityNorm);
    end
end

if ~isempty(info.messages)
    lines{end + 1} = ' ';
    lines = [lines, info.messages]; %#ok<AGROW>
end

lines{end + 1} = ' ';
lines{end + 1} = 'Most physical: main image + XY beam path';
lines{end + 1} = 'Approx: top sketch and YZ';

set(app.controls.infoBox, 'String', strjoin(lines, sprintf('\n')));
set(app.controls.infoBox, 'BackgroundColor', info.boxColor);
set(app.controls.infoBadge, 'String', info.statusText, 'BackgroundColor', info.badgeColor);
end

function textValue = popupText(handle)
items = get(handle, 'String');
textValue = items{get(handle, 'Value')};
end

function assertControlVisibility(app, controlName, expectedVisible)
control = app.controls.(controlName);
visible = strcmp(get(controlHandle(control), 'Visible'), 'on');
assert(visible == expectedVisible, 'Visibility check failed for %s.', controlName);
end

function state = onOff(isVisible)
if isVisible
    state = 'on';
else
    state = 'off';
end
end
