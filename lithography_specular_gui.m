 function lithography_specular_gui(varargin)
% LITHOGRAPHY_SPECULAR_GUI
% GUI for a simplified specular lithography illumination simulation.
%
% Usage:
%   lithography_specular_gui
%   lithography_specular_gui('selftest')

if nargin >= 1 && ischar(varargin{1})
    switch lower(varargin{1})
        case 'uitest'
            runUITest();
            return;
        case 'layouttest'
            runLayoutTest();
            return;
        case 'snapshotstest'
            runSnapshotTest();
            return;
        case 'previewuitest'
            runPreviewUITest();
            return;
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
report=lithography_regression_tests(true);
assert(report.pass,'Independent physics regression failed.');
app=buildGui('off');
app=guidata(app.fig);
cleanup=onCleanup(@() delete(app.fig));
assert(isfield(app.controls,'xzButton'),'Missing wave diffraction view.');
assert(all(isfinite(app.lastResult.image(:))),'Nonfinite GUI image.');
fprintf('GUI construction and independent physics selftest passed.\n');
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
    'Color', [0.97 0.98 0.99], ...
    'MenuBar', 'none', ...
    'ToolBar', 'none', ...
    'Position', initialWindowPosition(), ...
    'Visible', figVisible);
if isprop(app.fig,'Theme'),set(app.fig,'Theme','light');end

app.controlPanel = uipanel( ...
    'Parent', app.fig, ...
    'Title', '', ...
    'Units', 'normalized', ...
    'Position', [0.012 0.03 0.235 0.94], ...
    'BackgroundColor',[1 1 1], 'BorderType','none', 'FontWeight', 'bold');

app.axPropagation = axes('Parent', app.fig, 'Units', 'normalized', 'Position', [0.255 0.73 0.705 0.20]);
app.axYZ          = axes('Parent', app.fig, 'Units', 'normalized', 'Position', [0.255 0.43 0.705 0.21]);
app.axSource      = axes('Parent', app.fig, 'Units', 'normalized', 'Position', [0.252 0.065 0.142 0.285]);
app.axMask        = axes('Parent', app.fig, 'Units', 'normalized', 'Position', [0.433 0.065 0.142 0.285]);
app.axPupil       = axes('Parent', app.fig, 'Units', 'normalized', 'Position', [0.614 0.065 0.142 0.285]);
app.axImage       = axes('Parent', app.fig, 'Units', 'normalized', 'Position', [0.795 0.065 0.142 0.285]);
app.axElements=gobjects(1,6);
for j=1:6,app.axElements(j)=axes('Parent',app.fig,'Units','pixels','Position',[400 250 60 36]);end
setappdata(app.axYZ,'previewScale','Local / z');

app.controls = struct();
app.layout = struct();
app.layout.page = 1;
app.nextSliceFigureIndex = 0;
app.calculationCount = 0;
app.layout.startY = 0.935;
app.layout.dy = 0.0195;
app.layout.sectionGap = 0.0035;

app.controls.closeAllFigsButton = uicontrol( ...
    'Parent', app.fig, ...
    'Style', 'pushbutton', ...
    'String', 'Hide extra views', ...
    'Units', 'normalized', ...
    'FontWeight', 'bold', ...
    'TooltipString', 'Hides reusable views without destroying native plot windows.', ...
    'Callback', @(~, ~) closeAllFigures(app.fig));

app.controls.topXYSliceLabel = uicontrol( ...
    'Parent', app.fig, ...
    'Style', 'text', ...
    'String', 'Absolute z (mm)', ...
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
app.controls.sourcePageButton=uicontrol(app.controlPanel,'Style','togglebutton','String','Source & mask',...
    'Value',1,'Callback',@(~,~) selectSettingsPage(app.fig,1));
app.controls.systemPageButton=uicontrol(app.controlPanel,'Style','togglebutton','String','Optics & view',...
    'Value',0,'Callback',@(~,~) selectSettingsPage(app.fig,2));
app.controls.slicePlane=uicontrol(app.fig,'Style','popupmenu',...
    'String',{'Custom z','Source','Condenser exit','Mask exit','Mask + 1 um','Pupil','Image'},...
    'Value',7,'TooltipString','Jump to a named physical plane. z is always measured from the source.',...
    'Callback',@(~,~) selectSlicePlane(app.fig));
app.controls.showXYButton=uicontrol(app.fig,'Style','pushbutton','String','Show XY',...
    'FontWeight','bold','Callback',@(~,~) topBarXYSliceChanged(app.fig,app.controls.topXYSliceEdit));
app.controls.sliceHint=uicontrol(app.fig,'Style','text','HorizontalAlignment','left',...
    'BackgroundColor',get(app.fig,'Color'),'String','Choose a plane or enter an absolute z position.');
app.controls.detailsButton=uicontrol(app.controlPanel,'Style','pushbutton','String','Model details',...
    'Callback',@(~,~) showModelDetails(app.fig));
app.controls.previewScale=uicontrol(app.fig,'Style','popupmenu',...
    'String',{'Local / z','XYZ linear','XYZ log (dB)'},'Value',1,...
    'TooltipString','Wave preview only. Local reveals shape at each z; XYZ preserves relative brightness. Each XY window has its own colour-scale selector.',...
    'Callback',@(~,~) changePreviewScale(app.fig));
app.controls.previewScaleLabel=uicontrol(app.fig,'Style','text','String','Preview scale',...
    'HorizontalAlignment','left','BackgroundColor',get(app.fig,'Color'));

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
app.controls.sourceEmissionNA = createEdit(app.controlPanel, y, 'Emitter divergence', params.sourceEmissionNA, cb);
set(app.controls.sourceEmissionNA, 'TooltipString', 'Gaussian paraxial half-divergence 0.02..0.15 rad; waist = wavelength/(pi*divergence). Emitters are mutually incoherent.');
y = y - dy;
app.controls.sourceOuter = createEdit(app.controlPanel, y, 'Outer radius', params.sourceOuter, cb);
set(app.controls.sourceOuter, 'TooltipString', 'Emitter-position radius 0.08..1. One unit = condenser focal length * image NA / reduction. Not a measured source size.');
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
app.controls.condenserAperture = createEdit(app.controlPanel, y, 'Cond Gaussian radius', params.condenserAperture, cb);
set(app.controls.condenserAperture, 'TooltipString', 'Gaussian intensity 1/e^2 radius; one unit = f_cond*NA/reduction. Amplitude exp(-r^2/a^2), NOT a hard circular aperture. Zero blocks all light after this lens.');

y = y - sectionGap;
app.sectionTitles.mask = createSectionTitle(app.controlPanel, y, 'Mask / local pattern');
y = y - dy;
app.controls.maskType = createPopup(app.controlPanel, y, 'Pattern shape', ...
    {'Circular Aperture', 'Square Aperture', 'Diamond Aperture', 'Annular Aperture', '1D Grating', '2D Grating', 'Cross'}, ...
    '1D Grating', cb);
y = y - dy;
app.controls.maskSizeUm = createEdit(app.controlPanel, y, 'Feature size (um)', params.maskSizeUm, cb);
app.controls.maskPlateSizeMm=createEdit(app.controlPanel,y,'Plate side (mm)',params.maskPlateSizeMm,cb);
set(app.controls.maskPlateSizeMm,'TooltipString','Mechanical plate outline only. Waves are calculated within the local ROI, not across this entire plate.');
app.controls.maskScaleButton=createActionRowButton(app.controlPanel,'Plate vs local pattern',...
    @(~,~) safeUI(app.fig,@() showMaskScale(app.fig)));
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
app.controls.projNA = createEdit(app.controlPanel, y, 'Image NA (0.05-0.30)', params.projNA, cb);
y = y - dy;
app.controls.lensInner = createEdit(app.controlPanel, y, 'Lens inner radius', params.lensInner, cb);
y = y - dy;
app.controls.reduction = createEdit(app.controlPanel, y, 'Reduction factor', params.reduction, cb);

y = y - sectionGap;
app.sectionTitles.imaging = createSectionTitle(app.controlPanel, y, 'Imaging');
y = y - dy;
app.controls.wavelengthNm = createEdit(app.controlPanel, y, 'Wavelength (nm)', params.wavelengthNm, cb);
y = y - dy;
app.controls.fieldSizeUm = createEdit(app.controlPanel, y, 'Local window (um)', params.fieldSizeUm, cb);
y = y - dy;
app.controls.defocusUm = createEdit(app.controlPanel, y, 'Defocus (um)', params.defocusUm, cb);

y = y - sectionGap;
app.sectionTitles.geometry = createSectionTitle(app.controlPanel, y, 'Geometry');
y = y - dy;
app.controls.condenserFocalMm = createEdit(app.controlPanel, y, 'Condenser f (mm)', params.condenserFocalMm, cb);
y = y - dy;
app.controls.projectionFocalMm = createEdit(app.controlPanel, y, 'Lens 1 f (mm)', params.projectionFocalMm/2, cb);
set(app.controls.projectionFocalMm,'TooltipString','Ideal 4f relay: f2=f1/reduction. Mask-to-L1=f1; L1-to-L2=f1+f2; L2-to-image=f2. Distances are between ideal principal planes.');
y = y - dy;
app.controls.sourceToCondenserMm = createSlider(app.controlPanel, y, 'Source->Cond (mm)', ...
    20, 160, params.sourceToCondenserMm, cb);
y = y - dy;
app.controls.fieldToPupilMm = createSlider(app.controlPanel, y, 'Field->Pupil (mm)', ...
    20, 220, params.fieldToPupilMm, cb);

y = y - sectionGap;
app.sectionTitles.views = createSectionTitle(app.controlPanel, y, 'View Controls');
y = y - dy;
app.controls.xzButton=createActionRowButton(app.controlPanel,'XZ diffraction near mask',...
    @(~,~) safeUI(app.fig,@() lithography_open_xz(lithography_collect_input(guidata(app.fig)),app.fig)));
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
set(app.controls.intensityNorm, 'TooltipString', 'Computational normalization: XYZ uses a shared reference. The XY window has an independent display scale and defaults to Local linear to reveal shape.');
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
set([app.controls.updateYZButton,app.controls.autoYZButton],'Parent',app.fig);

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
        rowSpec('sourceEmissionNA', 'edit')
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
        rowSpec('maskPlateSizeMm', 'edit')
        rowSpec('maskSizeUm', 'edit')
        rowSpec('maskInnerRatio', 'edit')
        rowSpec('gratingPitchUm', 'edit')
        rowSpec('gratingDuty', 'edit')
        rowSpec('maskScaleButton', 'button')
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
        rowSpec('xzButton', 'button')
        rowSpec('rayDensity', 'popup')
        rowSpec('yzMode', 'popup')
        rowSpec('yzView', 'popup')
        rowSpec('intensityNorm', 'popup')
        rowSpec('xySliceZMm', 'edit')
    }}) ...
};

guidata(app.fig, app);
set(app.fig,'SizeChangedFcn',@(~,~) refreshControlLayout(app.fig));
refreshControlLayout(app.fig);
updatePlots(app.fig);
end

function pos=initialWindowPosition()
screen=get(groot,'ScreenSize');
width=min(1360,screen(3)-40);height=min(880,screen(4)-100);
pos=[screen(1)+(screen(3)-width)/2,screen(2)+(screen(4)-height)/2,width,height];
end

function selectSettingsPage(fig,page)
app=guidata(fig);app.layout.page=page;guidata(fig,app);
refreshControlLayout(fig);
end

function selectSlicePlane(fig)
safeUI(fig,@() selectSlicePlaneImpl(fig));
end

function selectSlicePlaneImpl(fig)
app=guidata(fig);choice=get(app.controls.slicePlane,'Value');
if choice==1,return;end
oldZ=get(app.controls.xySliceZMm,'String');set(app.controls.xySliceZMm,'String','0');
restore=onCleanup(@()set(app.controls.xySliceZMm,'String',oldZ));
p=lithography_collect_input(app);
clear restore;
g=lithography_projection_geometry(p,struct('imageDistanceMm',p.projectionFocalMm/p.reduction,'absMagnification',1/p.reduction));
planes=[0,g.zCondenser,g.zField,g.zField+.001,g.zPupil,g.zImage];
setEditValue(app.controls.topXYSliceEdit,planes(choice-1));
setEditValue(app.controls.xySliceZMm,planes(choice-1));
refreshSliceHint(app,p,planes(choice-1));
end

function refreshSliceHint(app,p,z)
maskZ=p.sourceToCondenserMm+p.condenserFocalMm;
set(app.controls.sliceHint,'String',sprintf('Mask at %.6g mm  |  Selected plane: %+.6g um from mask',maskZ,(z-maskZ)*1000));
planes=[0,p.sourceToCondenserMm,maskZ,maskZ+.001,maskZ+p.fieldToPupilMm,...
    maskZ+p.fieldToPupilMm+p.projectionFocalMm/p.reduction+p.defocusUm*.001];
match=find(abs(planes-z)<1e-9,1);choice=1;if ~isempty(match),choice=match+1;end
set(app.controls.slicePlane,'Value',choice);
end

function showModelDetails(fig)
if ~isappdata(fig,'modelDetails'),return;end
detail=lithography_plot_figure(fig,'LithographyDetails',...
    'Name','Model details and checks','Position',initialWindowPosition(),'Visible',get(fig,'Visible'));
setappdata(fig,'detailsFigure',detail);
uicontrol(detail,'Style','edit','Units','normalized','Position',[.03 .03 .94 .94],...
    'Max',100,'Min',0,'Enable','inactive','HorizontalAlignment','left','BackgroundColor','w',...
    'FontSize',11,'String',getappdata(fig,'modelDetails'));
if isprop(detail,'Theme'),set(detail,'Theme','light');end
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
setEditValue(app.controls.sourceEmissionNA, params.sourceEmissionNA);
setEditValue(app.controls.sourceOuter, params.sourceOuter);
setEditValue(app.controls.sourceInner, params.sourceInner);
setEditValue(app.controls.quadSeparation, params.quadSeparation);
setEditValue(app.controls.pointSourceU, params.pointSourceU);
setEditValue(app.controls.pointSourceV, params.pointSourceV);
setEditValue(app.controls.condenserAperture, params.condenserAperture);

setPopupValue(app.controls.maskType, params.maskType);
setEditValue(app.controls.maskSizeUm, params.maskSizeUm);
setEditValue(app.controls.maskPlateSizeMm, params.maskPlateSizeMm);
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
setEditValue(app.controls.projectionFocalMm, params.projectionFocalMm/2);
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

refreshSliceHint(app,params,params.xySliceZMm);
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
set(handle, 'String', sprintf('%.12g',value));
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
safeUI(figHandle,@() updatePlotsImpl(figHandle));
end

function updatePlotsImpl(figHandle)
refreshControlLayout(figHandle);
app = guidata(figHandle);
params = lithography_collect_input(app);
setEditValue(app.controls.xySliceZMm, params.xySliceZMm);
setEditValue(app.controls.topXYSliceEdit, params.xySliceZMm);
if isfield(app,'lastResult') && ~isempty(app.lastResult) && samePhysicsSettings(app.lastParams,params)
    result=app.lastResult;
else
    result=lithography_run_physics(params);app.calculationCount=app.calculationCount+1;
end
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
refreshControlLayout(figHandle);
refreshSliceHint(app,params,params.xySliceZMm);
drawnow;
end

function updateYZPlot(figHandle)
safeUI(figHandle,@() updateYZPlotImpl(figHandle));
end

function updateYZPlotImpl(figHandle)
app = guidata(figHandle);
params = lithography_collect_input(app);

if isfield(app, 'lastResult') && ~isempty(app.lastResult) && isfield(app, 'lastParams') && samePhysicsSettings(app.lastParams, params)
    result = app.lastResult;
else
    result = lithography_run_physics(params);
    app.calculationCount=app.calculationCount+1;
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
yzData = lithography_compute_yz_intensity(params, result,@(done,total) previewProgress(figHandle,done,total));
yzData.xyzReferencePeak=result.xyzReferencePeak;
yzData.axisLimitsMm=[result.geometry.xMin,result.geometry.zSliceMax];
app.lastYZ = yzData;
app.lastYZParams = params;
guidata(figHandle, app);
lithography_render_yz_panel(app.axYZ, yzData);
refreshControlLayout(figHandle);
end

function previewProgress(fig,done,total)
if ~isgraphics(fig),return;end
app=guidata(fig);
set(app.controls.infoBadge,'String',sprintf('Wave preview: %d / %d',done,total));
drawnow limitrate;
if done==total,set(app.controls.infoBadge,'String','Working...');end
end

function changePreviewScale(fig)
app=guidata(fig);
setappdata(app.axYZ,'previewScale',popupText(app.controls.previewScale));
if isfield(app,'lastYZ') && ~isempty(app.lastYZ)
    lithography_render_yz_panel(app.axYZ,app.lastYZ);
    armYZInteraction(fig);
end
refreshControlLayout(fig);
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
safeUI(figHandle,@() handleYZClickImpl(figHandle));
end

function handleYZClickImpl(figHandle)
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
if isfield(app, 'lastResult') && ~isempty(app.lastResult) && isfield(app, 'lastParams') && samePhysicsSettings(app.lastParams, params)
    result = app.lastResult;
else
    result = lithography_run_physics(params);
    app.calculationCount=app.calculationCount+1;
    app.lastResult = result;
    app.lastParams = params;
    guidata(figHandle, app);
end

sharedPeak = sharedIntensityPeakForXY(figHandle, params, result);
slice = lithography_compute_xy_slice(params, result, zSelected, sharedPeak);
showXYSliceFigure(slice, figHandle);
setEditValue(app.controls.topXYSliceEdit,zSelected);
setEditValue(app.controls.xySliceZMm,zSelected);
refreshSliceHint(app,params,zSelected);
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
safeUI(figHandle,@() plotXYSliceFromInputImpl(figHandle));
end

function plotXYSliceFromInputImpl(figHandle)
app = guidata(figHandle);
params = lithography_collect_input(app);
zSelected = params.xySliceZMm;
setEditValue(app.controls.xySliceZMm, zSelected);
setEditValue(app.controls.topXYSliceEdit, zSelected);

if isfield(app, 'lastResult') && ~isempty(app.lastResult) && isfield(app, 'lastParams') && samePhysicsSettings(app.lastParams, params)
    result = app.lastResult;
else
    result = lithography_run_physics(params);
    app.calculationCount=app.calculationCount+1;
    app.lastResult = result;
    app.lastParams = params;
    guidata(figHandle, app);
end

sharedPeak = sharedIntensityPeakForXY(figHandle, params, result);
slice = lithography_compute_xy_slice(params, result, zSelected, sharedPeak);
showXYSliceFigure(slice, figHandle);
refreshSliceHint(app,params,zSelected);
end

function topBarXYSliceChanged(figHandle, editHandle)
safeUI(figHandle,@() topBarSliceImpl(figHandle,editHandle));
end

function topBarSliceImpl(figHandle, editHandle)
app = guidata(figHandle);
rawValue = str2double(get(editHandle, 'String'));
if ~isfinite(rawValue)
    error('Lithography:Settings','z must be a finite number.');
end
setEditValue(app.controls.xySliceZMm, rawValue);
setEditValue(app.controls.topXYSliceEdit, rawValue);
set(app.controls.slicePlane,'Value',1);
if isfield(app,'lastParams') && ~isempty(app.lastParams),refreshSliceHint(app,app.lastParams,rawValue);end
plotXYSliceFromInputImpl(figHandle);
end

function tf=samePhysicsSettings(a,b)
if ~isstruct(a)||isempty(a)||~isstruct(b)||isempty(b),tf=false;return;end
viewFields={'xySliceZMm','intensityNorm','rayDensity','yzMode','yzView','autoYZ','maskPlateSizeMm'};
tf=isequaln(rmfield(a,intersect(fieldnames(a),viewFields)),rmfield(b,intersect(fieldnames(b),viewFields)));
end

function sharedPeak = sharedIntensityPeakForXY(~, params, result)
sharedPeak=[];
if strcmp(params.intensityNorm,'XYZ'), sharedPeak=result.xyzReferencePeak; end
end

function fig = showXYSliceFigure(slice, mainFigHandle, varargin)
visibleState = 'on';
if ishghandle(mainFigHandle) && strcmp(get(mainFigHandle,'Visible'),'off'),visibleState='off';end
if nargin >= 3 && ~isempty(varargin{1})
    visibleState = varargin{1};
end

figPosition = nextSliceFigurePosition(mainFigHandle);
mode='Local linear';
if ishghandle(mainFigHandle) && isappdata(mainFigHandle,'reusableXYFigure')
    candidate=getappdata(mainFigHandle,'reusableXYFigure');
    if isgraphics(candidate,'figure') && isappdata(candidate,'xyScaleMode')
        mode=getappdata(candidate,'xyScaleMode');
    end
end
fig = lithography_plot_figure(mainFigHandle,'LithographyXYSlice', ...
    'Name', sprintf('XY slice at z = %.6f mm', slice.zMm), ...
    'NumberTitle', 'off', ...
    'Color', 'w', ...
    'Tag', 'LithographyXYSlice', ...
    'Position', figPosition, ...
    'Visible', visibleState);
if ishghandle(mainFigHandle),setappdata(mainFigHandle,'reusableXYFigure',fig);end
if isprop(fig,'Theme'),set(fig,'Theme','light');end
lithography_render_xy_slice(fig,slice,mode);
end

function showMaskScale(mainFig)
app=guidata(mainFig);p=lithography_collect_input(app);
if isempty(app.lastResult)||~samePhysicsSettings(p,app.lastParams)
    updatePlots(mainFig);app=guidata(mainFig);
end
if isempty(app.lastResult),return;end
position=nextSliceFigurePosition(mainFig);position(3:4)=[850 470];
f=lithography_plot_figure(mainFig,'LithographyMaskScale',...
    'Name','Mask plate and local calculation region','Position',position,...
    'Visible',get(mainFig,'Visible'));
setappdata(mainFig,'maskScaleFigure',f);
lithography_render_mask_scale(f,p,app.lastResult);
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
xzFigs=findall(groot,'Type','figure','Tag','LithographyXZPreview');
detailFigs=findall(groot,'Type','figure','Tag','LithographyDetails');
scaleFigs=findall(groot,'Type','figure','Tag','LithographyMaskScale');
figs = [sliceFigs(:); editorFigs(:);xzFigs(:);detailFigs(:);scaleFigs(:)];
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
if ~isgraphics(figHandle),return;end
app=guidata(figHandle);
if isempty(app)||~isfield(app.layout,'sections'),return;end
position=get(figHandle,'Position');W=position(3);H=position(4);
screen=get(groot,'ScreenSize');
minW=min(1100,screen(3)-40);minH=min(780,screen(4)-100);
if W<minW||H<minH
    position(3:4)=max(position(3:4),[minW,minH]);set(figHandle,'Position',position);
    W=position(3);H=position(4);
end
panelW=320;if W<1280,panelW=302;end
panelH=H-32;
set(app.controlPanel,'Units','pixels','Position',[16 16 panelW panelH]);
set(app.controls.sourcePageButton,'Units','pixels','Position',[12 panelH-45 (panelW-28)/2 32]);
set(app.controls.systemPageButton,'Units','pixels','Position',[16+(panelW-28)/2 panelH-45 (panelW-28)/2 32]);
buttons=[app.controls.sourcePageButton,app.controls.systemPageButton];
for j=1:2
    selected=app.layout.page==j;
    color=[.95 .96 .97];if selected,color=[.84 .91 .98];end
    set(buttons(j),'FontSize',10,'FontWeight','bold','Value',double(selected),'BackgroundColor',color);
end
updateDynamicLabels(app);vis=controlVisibility(app);
y=panelH-76;rowHeight=28;
for s=1:numel(app.layout.sections)
    section=app.layout.sections{s};rows=section.rows;
    onPage=(app.layout.page==1 && s<=3)||(app.layout.page==2 && s>=4);
    visibleRows=false(1,numel(rows));
    for r=1:numel(rows)
        visibleRows(r)=onPage&&vis.(rows{r}.id);
        setRowVisible(app.controls.(rows{r}.id),visibleRows(r));
    end
    set(section.title,'Visible',onOff(any(visibleRows)));
    if ~any(visibleRows),continue;end
    set(section.title,'Units','pixels','Position',[16 y panelW-32 22],...
        'FontSize',11,'ForegroundColor',[.12 .26 .42]);
    y=y-25;
    for r=1:numel(rows)
        if ~visibleRows(r),continue;end
        applyRowPosition(app.controls.(rows{r}.id),rows{r}.type,y,panelW,rowHeight);
        y=y-rowHeight;
    end
    y=y-8;
end
set(app.controls.actionsTitle,'Visible','off');
set(app.controls.updateButton,'Units','pixels','Position',[16 123 (panelW-40)/2 32],...
    'String','Update results','FontSize',10,'BackgroundColor',[.84 .91 .98]);
set(app.controls.resetButton,'Units','pixels','Position',[24+(panelW-40)/2 123 (panelW-40)/2 32],'FontSize',10);
set(app.controls.infoBadge,'Units','pixels','Position',[16 94 panelW-32 24],'FontSize',10);
set(app.controls.infoBox,'Units','pixels','Position',[16 35 panelW-32 56],'FontSize',10);
set(app.controls.detailsButton,'Units','pixels','Position',[16 5 panelW-32 26],'FontSize',10);

left=panelW+64;right=W-left-44;
pathWidth=right-40;
set(app.axPropagation,'Units','pixels','Position',[left H-174 pathWidth 72]);
barY=H-235;
set(app.controls.slicePlane,'Units','pixels','Position',[left-20 barY 144 28],'FontSize',10);
set(app.controls.topXYSliceLabel,'Units','pixels','Position',[left+136 barY+2 121 23],'FontSize',10);
set(app.controls.topXYSliceEdit,'Units','pixels','Position',[left+256 barY 98 28],'FontSize',10);
set(app.controls.showXYButton,'Units','pixels','Position',[left+366 barY 84 28],'FontSize',10,'BackgroundColor',[.84 .91 .98]);
set(app.controls.closeAllFigsButton,'Units','pixels','Position',[left+462 barY 109 28],'FontSize',9);
set(app.controls.sliceHint,'Units','pixels','Position',[left-20 barY-25 right+20 21],...
    'FontSize',9,'ForegroundColor',[.30 .37 .44]);
set(app.controls.updateYZButton,'Units','pixels','Position',[left-20 H-305 106 28],'FontSize',10);
set(app.controls.autoYZButton,'Units','pixels','Position',[left+94 H-305 110 28],'FontSize',10);
set(app.controls.previewScaleLabel,'Units','pixels','Position',[left+224 H-302 100 23],'FontSize',10);
set(app.controls.previewScale,'Units','pixels','Position',[left+326 H-305 146 28],'FontSize',10);
slot=(right+40)/4;side=min(160,slot-62);plotY=54;
elementBase=plotY+side+38;
previewY=elementBase+140;previewH=max(54,H-350-previewY);
set(app.axYZ,'Units','pixels','Position',[left previewY pathWidth previewH]);
if isfield(app,'lastResult') && ~isempty(app.lastResult)
    g=app.lastResult.geometry;limits=[g.xMin g.zSliceMax];
    set([app.axPropagation app.axYZ],'XLim',limits,'XLimMode','manual');
    set(app.axPropagation,'XTick',get(app.axYZ,'XTick'));
end
if isappdata(app.axYZ,'colorbarHandle')
    bar=getappdata(app.axYZ,'colorbarHandle');
    if isgraphics(bar),set(bar,'Units','pixels','Position',[left+right-28 previewY 12 previewH]);end
end
plotAxes=[app.axSource,app.axMask,app.axPupil,app.axImage];
for j=1:4
    set(plotAxes(j),'Units','pixels','Position',[left+(j-1)*slot plotY slot-62 side]);
end
elementSlot=pathWidth/6;
for j=1:6
    set(app.axElements(j),'Units','pixels','Position',...
        [left+(j-1)*elementSlot+8 elementBase+44 elementSlot-16 34]);
end
% Colorbars have their own positions; reflow them after axes move or resize.
for j=1:4
    if ~isappdata(plotAxes(j),'colorbarHandle'),continue;end
    bar=getappdata(plotAxes(j),'colorbarHandle');
    if isgraphics(bar),set(bar,'Units','pixels','Position',[left+(j-1)*slot+slot-54 plotY 10 side]);end
end
end

function vis = controlVisibility(app)
sourceType = popupText(app.controls.sourceType);
maskType = popupText(app.controls.maskType);
lensType = popupText(app.controls.lensType);

vis = struct();
vis.presetMenu = true;
vis.showcaseMenu = true;
vis.sourceType = true;
vis.sourceEmissionNA = true;
vis.sourceOuter = any(strcmp(sourceType, {'Circular', 'Square', 'Annular', 'Dipole X', 'Dipole Y'}));
vis.sourceInner = strcmp(sourceType, 'Annular');
vis.quadSeparation = any(strcmp(sourceType, {'Dipole X', 'Dipole Y', 'Quadrupole'}));
vis.pointSourceU = strcmp(sourceType, 'Point');
vis.pointSourceV = strcmp(sourceType, 'Point');
vis.editSourceButton = strcmp(sourceType, 'Freeform');
vis.condenserAperture = true;

vis.maskType = true;
vis.maskPlateSizeMm=true;vis.maskScaleButton=true;
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
vis.sourceToCondenserMm = false; % Locked conjugate distances remain available in model details.
vis.fieldToPupilMm = false;
vis.xySliceZMm = false; % One visible z editor in the workspace toolbar.
vis.rayDensity = true;
vis.yzMode = false; % Old geometrical-ray options do not apply to wave propagation.
vis.yzView = false;
vis.intensityNorm = true;
vis.xzButton = true;
end

function applyRowPosition(control, rowType, y, width, height)
switch rowType
    case {'edit', 'popup'}
        labelHandle = getappdata(control, 'labelHandle');
        set(labelHandle,'Units','pixels','Position',[16 y+3 139 height-5],'FontSize',10);
        set(control,'Units','pixels','Position',[157 y+1 width-173 height-3],'FontSize',10);

    case 'slider'
        set(control.label, 'Position', [0.06 y 0.42 0.022]);
        set(control.slider, 'Position', [0.44 y + 0.003 0.38 0.020]);
        set(control.valueText, 'Position', [0.84 y 0.10 0.022]);

    case 'button'
        set(control.handle,'Units','pixels','Position',[16 y+1 width-32 height-3],'FontSize',10);
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
        setControlLabel(app.controls.maskSizeUm, 'Pattern box (um)');
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
lines{end+1}=sprintf('Guarded scalar model: %d pixels, %dx padding',params.gridSize,params.propagationPadding);
lines{end+1}='Conjugate distances follow focal lengths; NA <= 0.30';
g=result.geometry;
lines{end+1}=sprintf('Plate outline %.3g mm; computed local window %.3g um; patterned patch %.3g um. Other transmitted features excluded.',params.maskPlateSizeMm,params.fieldSizeUm,params.maskSizeUm);
lines{end+1}=sprintf('Ideal principal-plane distances: mask-L1 %.3g mm; L1-L2 %.3g mm; L2-image %.3g mm.',g.fieldToLens1Mm,g.projectionLensSeparation,g.lens2ToImageMm);
if isfield(result,'maskIllumination')
    b=result.maskIllumination;
    lines{end+1}=sprintf('Source coordinate unit: %.4g mm; emitter waist: %.3g um',b.sourceScaleM*1e3,b.waistM*1e6);
    lines{end+1}=sprintf('Gaussian condenser radius: %.4g mm; power passed: %.3g%%',b.apertureRadiusM*1e3,100*result.condenserTransmission);
    lines{end+1}='Full-path scalar waves; Gaussian condenser is NOT a hard stop';
    lines{end+1}=sprintf('Incident-source integration check: %.3g%% discrepancy (limit 2%%)',100*result.illuminationQuadratureError);
end
if isfield(params, 'intensityNorm')
    if strcmp(params.intensityNorm, 'XYZ')
        lines{end + 1} = 'XYZ: shared physical intensity reference; Local: shape only';
    else
        lines{end + 1} = sprintf('Norm: %s', params.intensityNorm);
    end
end

if ~isempty(info.messages)
    lines{end + 1} = ' ';
    lines = [lines, info.messages]; %#ok<AGROW>
end

lines{end + 1} = ' ';
lines{end + 1} = 'Mask near field: RS diffraction; relay: scalar paraxial';
lines{end + 1} = 'Top: geometry only. YZ: sampled x=0 waves on physical y (mm); grey is outside sampled windows';

setappdata(figHandle,'modelDetails',strjoin(lines,sprintf('\n')));
summary=sprintf('Plate %.3g mm; local pattern box %.3g um; image box nominally %.3g um. Ideal 4f model, not an industrial lens.',params.maskPlateSizeMm,params.maskSizeUm,params.maskSizeUm/params.reduction);
important=find(startsWith(info.messages,'Warning:'),1);
if isempty(important),important=find(contains(info.messages,'unresolved'),1);end
if ~isempty(important),summary=strrep(strrep(info.messages{important},'Note: ',''),'Warning: ','');end
set(app.controls.infoBox, 'String', summary);
set(app.controls.infoBox, 'BackgroundColor', info.boxColor);
status='Ready';if info.hasWarning,status='Ready — check warning';elseif info.hasNote,status='Ready — model notes';end
set(app.controls.infoBadge, 'String', status, 'BackgroundColor', info.badgeColor);
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

function safeUI(fig,action)
if ~isgraphics(fig),return;end
if isappdata(fig,'calculating') && getappdata(fig,'calculating'),return;end
setappdata(fig,'calculating',true);
set(fig,'Pointer','watch');
app=guidata(fig);if isfield(app,'controls'),set(app.controls.infoBadge,'String','Working...');end
drawnow;
cleanup=onCleanup(@() releaseUI(fig));
try
    action();
catch err
    if ~isgraphics(fig),return;end
    app=guidata(fig);app.lastResult=[];app.lastParams=[];app.lastYZ=[];guidata(fig,app);
    for name={'axSource','axMask','axPupil','axImage','axYZ'}
        ax=app.(name{1});cla(ax);title(ax,'Not calculated: check settings');
    end
    for ax=app.axElements,cla(ax);title(ax,'');end
    % Independent snapshot windows retain their previously valid data.
    set(app.controls.infoBadge,'String','Settings rejected','BackgroundColor',[1,.8,.75]);
    set(app.controls.infoBox,'String',err.message,'BackgroundColor',[1,.9,.85]);
    setappdata(fig,'modelDetails',err.message);
    warning('Lithography:InputRejected','%s',err.message);
end
end
function releaseUI(fig)
if isgraphics(fig)
    setappdata(fig,'calculating',false);set(fig,'Pointer','arrow');
    app=guidata(fig);
    if strcmp(get(app.controls.infoBadge,'String'),'Working...'),set(app.controls.infoBadge,'String','Ready');end
end
end

function runSnapshotTest()
app=buildGui('off');cleanup=onCleanup(@()cleanupSnapshotTest(app.fig));
app=guidata(app.fig);p=app.lastParams;r=app.lastResult;
assert(isempty(findall(app.fig,'Type','ColorBar')));
assert(numel(findall(app.fig,'Tag','LensIcon'))==2);
s=lithography_compute_xy_slice(p,r,r.geometry.zField);
first=showXYSliceFigure(s,app.fig,'on');before=getappdata(first,'xySliceData');
im=findall(first,'Type','image');pixels=get(im,'CData');name=get(first,'Name');
second=showXYSliceFigure(lithography_compute_xy_slice(p,r,r.geometry.zImage),app.fig,'off');
assert(first~=second && isgraphics(first) && isequal(getappdata(first,'xySliceData'),before));
assert(strcmp(get(first,'Visible'),'on'),'New XY request hid the earlier snapshot.');
set(first,'Visible','off'); % Test-hidden is not explicitly closed or reusable.
assert(isequal(get(im,'CData'),pixels) && strcmp(get(first,'Name'),name));
popup=findall(second,'Tag','XYScale');set(popup,'Value',4);cb=get(popup,'Callback');cb(popup,[]);
assert(strcmp(getappdata(first,'xyScaleMode'),'Local linear'),'Snapshots share colour controls.');
third=showXYSliceFigure(s,app.fig,'off');assert(third~=first && third~=second);
assert(strcmp(getappdata(third,'xyScaleMode'),'XYZ log (dB)'));
showMaskScale(app.fig);a=getappdata(app.fig,'maskScaleFigure');
showMaskScale(app.fig);b=getappdata(app.fig,'maskScaleFigure');assert(a~=b && isgraphics(a));
showModelDetails(app.fig);a=getappdata(app.fig,'detailsFigure');
showModelDetails(app.fig);b=getappdata(app.fig,'detailsFigure');assert(a~=b && isgraphics(a));
% Test actual XZ generation twice (one emitter for a bounded test runtime).
q=p;q.sourceType='Point';a=lithography_open_xz(q,app.fig);
im=findall(a,'Type','image');pixels=get(im,'CData');
b=lithography_open_xz(q,app.fig);assert(a~=b && isequal(get(im,'CData'),pixels));
% Rejected input must not hide an existing valid snapshot.
set(first,'Visible','on');set(app.controls.projNA,'String','0.9');updatePlots(app.fig);
assert(strcmp(get(first,'Visible'),'on') && isequal(getappdata(first,'xySliceData'),before));
set(first,'Visible','off');
set(app.controls.projNA,'String',num2str(p.projNA));updatePlots(app.fig);
assert(isempty(get(get(app.axYZ,'Title'),'String')),'Stale error title survived recovery.');
cb=get(second,'CloseRequestFcn');cb(second,[]);
reused=showXYSliceFigure(s,app.fig,'off');assert(reused==second && isgraphics(first));
exportapp(app.fig,fullfile(tempdir,'lithography_ui_cleanup.png'));
fprintf('UI snapshots: no overview bars, two lens icons, independent XY/XZ/plate/details windows, per-window scales, error preservation and closed-only reuse passed.\n');
end

function cleanupSnapshotTest(owner)
figs=findall(groot,'Type','figure');
for k=1:numel(figs)
    if isequal(getappdata(figs(k),'plotOwner'),owner),delete(figs(k));end
end
if isgraphics(owner),delete(owner);end
end

function runUITest()
app=buildGui('off');cleanup=onCleanup(@() cleanupSnapshotTest(app.fig));
app=guidata(app.fig);assert(~isempty(app.lastResult),'Default settings rejected');
p=app.lastParams;r=app.lastResult;
assert(p.xySliceZMm==r.geometry.zImage && get(app.controls.slicePlane,'Value')==7,'GUI startup must select the image plane.');
set(app.controls.slicePlane,'Value',7);
set(app.controls.projectionFocalMm,'String','80');
changed=lithography_collect_input(app);
assert(changed.projectionFocalMm==160 && changed.xySliceZMm==400,'Image selection did not follow focal-length change.');
set(app.controls.projectionFocalMm,'String',sprintf('%.12g',p.projectionFocalMm/2));
set(app.controls.slicePlane,'Value',1);set(app.controls.xySliceZMm,'String','400.123456789');
changed=lithography_collect_input(app);assert(abs(changed.xySliceZMm-400.123456789)<1e-10);
set(app.controls.slicePlane,'Value',7);setEditValue(app.controls.xySliceZMm,p.xySliceZMm);
assertControlVisibility(app,'sourceEmissionNA',true);
assertControlVisibility(app,'yzMode',false);
set(app.controls.sourceEmissionNA,'String','0.12');collected=lithography_collect_input(app);
assert(collected.sourceEmissionNA==.12,'Emitter divergence was not read from the GUI.');
set(app.controls.sourceEmissionNA,'String',num2str(p.sourceEmissionNA));
s=lithography_compute_xy_slice(p,r,r.geometry.zField);
for k=1:20
    f=showXYSliceFigure(s,app.fig,'off');
    popup=findall(f,'Tag','XYScale');
    if k==1
        assert(strcmp(getappdata(f,'xyScaleMode'),'Local linear'));
        set(popup,'Value',4);change=get(popup,'Callback');change(popup,[]);
    else
        assert(strcmp(getappdata(f,'xyScaleMode'),'XYZ log (dB)'),'XY scale was not retained.');
    end
    assert(numel(findall(f,'Type','image'))==1 && numel(findall(f,'Type','colorbar'))==1);
    callback=get(f,'CloseRequestFcn');callback(f,[]);
    assert(isgraphics(f) && strcmp(get(f,'Visible'),'off'));
end
figs=findall(groot,'Tag','LithographyXYSlice');owned=0;
for j=1:numel(figs),owned=owned+isequal(getappdata(figs(j),'plotOwner'),app.fig);end
assert(owned==1,'Explicitly closed test windows were not reused.');
delete(f);
set(app.controls.projNA,'String','0.9');updatePlots(app.fig);
state=guidata(app.fig);assert(isempty(state.lastResult),'Stale result survived invalid input');
set(app.controls.projNA,'String',num2str(p.projNA));updatePlots(app.fig);
state=guidata(app.fig);assert(~isempty(state.lastResult),'Failed to recover');
fprintf('GUI guards, recovery and 20 hide/reuse cycles passed. Native OS close-button crash not reproduced by this test.\n');
end

function runLayoutTest()
app=buildGui('off');cleanup=onCleanup(@()cleanupSnapshotTest(app.fig));
app=guidata(app.fig);assert(~isempty(app.lastResult),'Default UI calculation failed.');
original=app.lastParams;baseline=app.lastResult;count=0;
assert(str2double(get(app.controls.projectionFocalMm,'String'))==original.projectionFocalMm/2);
showMaskScale(app.fig);
scale=getappdata(app.fig,'maskScaleFigure');assert(isgraphics(scale));delete(scale);
sources={'Point','Circular','Square','Annular','Dipole X','Dipole Y','Quadrupole','Freeform'};
masks={'Circular Aperture','Square Aperture','Diamond Aperture','Annular Aperture','1D Grating','2D Grating','Cross'};
pupils={'Circular','Annular','Square','Diamond','Horizontal Slit','Vertical Slit','Freeform'};
fixtures=repmat(original,1,numel(sources)+numel(masks)+numel(pupils));
for j=1:numel(sources),fixtures(j).sourceType=sources{j};end
for j=1:numel(masks),fixtures(numel(sources)+j).maskType=masks{j};end
for j=1:numel(pupils),fixtures(numel(sources)+numel(masks)+j).lensType=pupils{j};fixtures(numel(sources)+numel(masks)+j).sourceType='Point';end
for size=[1100 1280 1360;720 800 880]
    set(app.fig,'Position',[20 30 size(1) size(2)]);
    for j=1:numel(fixtures)
        applyParamsToControlsInternal(app.fig,fixtures(j),false);
        for page=1:2
            selectSettingsPage(app.fig,page);
            assertLayoutBounds(app.fig);count=count+1;
        end
    end
end
applyParamsToControlsInternal(app.fig,original,false);selectSettingsPage(app.fig,1);
app=guidata(app.fig);assertControlVisibility(app,'xySliceZMm',false);
assertControlVisibility(app,'sourceToCondenserMm',false);
assertControlVisibility(app,'fieldToPupilMm',false);
assertControlVisibility(app,'sourceEmissionNA',true);
calls=app.calculationCount;
setPopupValue(app.controls.intensityNorm,'Local');updatePlots(app.fig);
app=guidata(app.fig);assert(app.calculationCount==calls,'Display normalization repeated the solver.');
assert(isequal(app.lastResult.imageRaw,baseline.imageRaw),'UI change altered raw physics.');
assert(isempty(findall(app.fig,'Type','ColorBar')),'Overview colorbars should be absent.');
assert(numel(findall(app.fig,'Tag','LensIcon'))==2,'Missing lens-shaped icons.');
for choice=2:7
    set(app.controls.slicePlane,'Value',choice);selectSlicePlane(app.fig);
    p=lithography_collect_input(guidata(app.fig));
    assert(p.xySliceZMm==str2double(get(app.controls.topXYSliceEdit,'String')));
    assert(~isempty(get(app.controls.sliceHint,'String')));
end
set(app.controls.slicePlane,'Value',4);selectSlicePlane(app.fig);
plotXYSliceFromInput(app.fig);
app=guidata(app.fig);assert(app.calculationCount==calls,'New z repeated the solver.');
xy=getappdata(app.fig,'reusableXYFigure');assert(isgraphics(xy));delete(xy);
assert(isequal(app.lastResult.maskExitRaw,baseline.maskExitRaw));
point=original;point.sourceType='Point';applyParamsToControlsInternal(app.fig,point,true);
updateYZPlot(app.fig);app=guidata(app.fig);
assert(~isempty(app.lastYZ) && strcmp(get(app.axYZ,'Visible'),'on'),'YZ preview or axes disappeared.');
for dims=[1100 1360;720 880]
    set(app.fig,'Position',[20 30 dims(1) dims(2)]);refreshControlLayout(app.fig);
    assertLayoutBounds(app.fig);
    bar=getappdata(app.axYZ,'colorbarHandle');rect=getpixelposition(bar);
    assert(rect(1)>0 && rect(2)>0 && rect(1)+rect(3)<=dims(1)-50,...
        'YZ colorbar lacks space for its tick labels and scale caption.');
end
fprintf('UI layout: %d size/shape/page checks passed; named planes, control visibility and display-only cache passed.\n',count);
end

function runPreviewUITest()
app=buildGui('off');cleanup=onCleanup(@() delete(app.fig));
updateYZPlot(app.fig);app=guidata(app.fig);
assert(~isempty(app.lastYZ),'Wave preview calculation failed.');
baseline=app.lastYZ.rawIntensity;calls=app.calculationCount;
g=app.lastResult.geometry;
between=app.lastYZ.zMm>g.zField+.2 & app.lastYZ.zMm<g.zImage-.2;
assert(all(max(baseline(:,between),[],1)>0),'Default relay contains an unexpected zero column.');
for mode={'Local / z','XYZ linear','XYZ log (dB)'}
    setPopupValue(app.controls.previewScale,mode{1});changePreviewScale(app.fig);
    state=guidata(app.fig);assert(state.calculationCount==calls,'Preview scale repeated optics.');
    assert(numel(findall(app.fig,'Type','ColorBar'))==1,'Only the YZ scale bar should remain.');
    assert(isequal(state.lastYZ.rawIntensity,baseline),'Display transform changed physical intensity.');
    surfaceHandle=findobj(app.axYZ,'Tag','WavePreview');values=get(surfaceHandle,'CData');
    assert(all(isfinite(values(:))),'Nonfinite preview display.');
    if strcmp(mode{1},'Local / z')
        assert(all(abs(max(values(:,between),[],1)-1)<1e-12),'Relay light is not visible in shape view.');
    elseif strcmp(mode{1},'XYZ linear')
        assert(norm(values-baseline/app.lastResult.xyzReferencePeak,'fro')<1e-12);
    end
end
dark=app.lastYZ;dark.rawIntensity(:)=0;
local=lithography_preview_display(dark,'Local / z');assert(all(local.values(:)==0));
logView=lithography_preview_display(dark,'XYZ log (dB)');assert(all(logView.values(:)==-120));
items=lithography_plane_sizes(app.lastParams,app.lastResult);
assert(all(isinf(items(3).widthXY)) && all(isinf(items(5).widthXY)),'Invented finite lens diameter.');
assert(abs(items(4).widthXY(1)-2*g.relayFocal2Mm*app.lastParams.projNA)<1e-12);
assert(all(items(6).widthXY==app.lastParams.fieldSizeUm/app.lastParams.reduction));
assert(max(items(2).thumbnail(:))==max(app.lastResult.mask(:)));
for shape={'Circular','Annular','Square','Diamond','Horizontal Slit','Vertical Slit','Freeform'}
    p=app.lastParams;p.lensType=shape{1};it=lithography_plane_sizes(p,app.lastResult);
    assert(all(isfinite(it(4).widthXY)) && all(it(4).widthXY>0));
    assert(any(it(4).thumbnail(:)>0),'Missing pupil shape thumbnail.');
    if strcmp(shape{1},'Horizontal Slit'),assert(it(4).widthXY(1)>it(4).widthXY(2));end
    if strcmp(shape{1},'Vertical Slit'),assert(it(4).widthXY(1)<it(4).widthXY(2));end
end
for dims=[1100 1280 1360;720 800 880]
    set(app.fig,'Position',[20 30 dims(1) dims(2)]);drawnow;
    refreshControlLayout(app.fig);drawnow;
    % Native window sizing can settle after the first SizeChanged event.
    refreshControlLayout(app.fig);
    a=getpixelposition(app.axPropagation);b=getpixelposition(app.axYZ);
    assert(max(abs(a([1 3])-b([1 3])))<.1,'Path panels do not share pixel bounds.');
    assert(isequal(xlim(app.axPropagation),xlim(app.axYZ)),'Path z limits differ.');
    assert(isequal(get(app.axPropagation,'XTick'),get(app.axYZ,'XTick')),'Path ticks differ.');
    labels=findobj(app.axPropagation,'Tag','GeometryLabel');
    for label=labels'
        extent=get(label,'Extent');assert(extent(2)>1,'Geometry label overlaps ray area.');
    end
    assertLayoutBounds(app.fig);
    for ax=app.axElements
        rect=getpixelposition(ax);assert(rect(2)>0 && rect(2)+rect(4)<b(2),'Size strip overlaps preview.');
        caption=findobj(ax,'Tag','PlaneSizeCaption');assert(~isempty(caption));
    end
end
fprintf('Preview UI: shared z bounds/ticks at 3 sizes; %d nonzero relay columns; 3 scales preserve raw data; dark views, aperture dimensions and 7 pupil shapes passed.\n',sum(between));
end

function assertLayoutBounds(fig)
position=get(fig,'Position');
handles=findall(fig,'Type','uicontrol','Visible','on');
rects=zeros(numel(handles),4);
for j=1:numel(handles)
    rects(j,:)=getpixelposition(handles(j),true);r=rects(j,:);
    assert(r(1)>=0 && r(2)>=0 && r(3)>0 && r(4)>0 && r(1)+r(3)<=position(3)+2 && r(2)+r(4)<=position(4)+2,...
        'Control outside figure: %s; control [%s], figure [%s]',...
        string(get(handles(j),'String')),num2str(r),num2str(position));
    parent=get(handles(j),'Parent');
    if ~isequal(parent,fig)
        local=getpixelposition(handles(j));box=getpixelposition(parent);
        assert(local(1)>=0 && local(2)>=0 && local(1)+local(3)<=box(3)+2 && local(2)+local(4)<=box(4)+2,...
            'Control clipped by parent: %s',string(get(handles(j),'String')));
    end
    if strcmp(get(handles(j),'Style'),'text')
        extent=get(handles(j),'Extent');
        assert(extent(4)<=r(4)+3,'Text label is vertically clipped: %s',string(get(handles(j),'String')));
    end
end
for j=1:numel(handles)
    for k=j+1:numel(handles)
        a=rects(j,:);b=rects(k,:);
        overlap=min(a(1:2)+a(3:4),b(1:2)+b(3:4))-max(a(1:2),b(1:2));
        assert(~all(overlap>2),'Overlapping controls: %s / %s',string(get(handles(j),'String')),string(get(handles(k),'String')));
    end
end
end
