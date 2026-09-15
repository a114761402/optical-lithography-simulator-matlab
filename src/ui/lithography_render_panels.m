function lithography_render_panels(app, params, result)
showPropagation(app.axPropagation, params, result);
showSource(app.axSource, result);
showMask(app.axMask, result);
showPupil(app.axPupil, result);
showImage(app.axImage, result);
if isfield(app,'axElements'),lithography_render_plane_sizes(app.axElements,params,result);end
end

function showSource(axHandle, result)
clearPanel(axHandle);
imagesc(axHandle, [-result.sourceExtent result.sourceExtent], ...
    [-result.sourceExtent result.sourceExtent], result.source);
axis(axHandle, 'image');
set(axHandle, 'YDir', 'normal');
colormap(axHandle, hot(256));
caxis(axHandle, [0 1]);
title(axHandle, sprintf('Source (%d samples)', result.sourceCount), 'FontSize', 10);
xlabel(axHandle, 'u / NA', 'FontSize', 9);
ylabel(axHandle, 'v / NA', 'FontSize', 9);
if isfield(result,'maskIllumination')
    title(axHandle,'Source weights','FontSize',10);
    xlabel(axHandle,'x / source unit','FontSize',9);
    ylabel(axHandle,'y / source unit','FontSize',9);
end
set(axHandle, 'FontSize', 9);
end

function showMask(axHandle, result)
clearPanel(axHandle);
imagesc(axHandle, [-result.maskExtentUm result.maskExtentUm], ...
    [-result.maskExtentUm result.maskExtentUm], result.mask);
axis(axHandle, 'image');
set(axHandle, 'YDir', 'normal');
colormap(axHandle, gray(256));
caxis(axHandle, [0 1]);
title(axHandle, 'Mask patch (amplitude)', 'FontSize', 10);
xlabel(axHandle, 'x (um)', 'FontSize', 9);
ylabel(axHandle, 'y (um)', 'FontSize', 9);
set(axHandle, 'FontSize', 9);
end

function showPupil(axHandle, result)
clearPanel(axHandle);
axisValues=result.pupilAxisM*1e3;
imagesc(axHandle,axisValues,axisValues,result.pupilSampled);
axis(axHandle, 'image');
radius=max(axisValues)/result.pupilNativeExtent;
xlim(axHandle,[-1.1,1.1]*radius);ylim(axHandle,[-1.1,1.1]*radius);
set(axHandle, 'YDir', 'normal');
colormap(axHandle, turbo(256));
caxis(axHandle, [0 1]);
title(axHandle, 'Pupil (local scale)', 'FontSize', 10);
xlabel(axHandle, 'x (mm)', 'FontSize', 9);
ylabel(axHandle, 'y (mm)', 'FontSize', 9);
set(axHandle, 'FontSize', 9);
end

function showImage(axHandle, result)
clearPanel(axHandle);
imagesc(axHandle, result.imageAxisM*1e6, result.imageAxisM*1e6, result.image);
axis(axHandle, 'image');
half=result.maskExtentUm*result.projectionRelay.absMagnification;
xlim(axHandle,[-half,half]);ylim(axHandle,[-half,half]);
set(axHandle, 'YDir', 'normal');
colormap(axHandle, parula(256));
caxis(axHandle, [0 1]);
title(axHandle, 'Image (local scale)', 'FontSize', 10);
xlabel(axHandle, 'x (um)', 'FontSize', 9);
ylabel(axHandle, 'y (um)', 'FontSize', 9);
set(axHandle, 'FontSize', 9);
end

function clearPanel(axHandle)
if isappdata(axHandle,'colorbarHandle')
    previous=getappdata(axHandle,'colorbarHandle');
    if isgraphics(previous),delete(previous);end
    rmappdata(axHandle,'colorbarHandle');
end
colorbar(axHandle,'off');cla(axHandle);
end

function showPropagation(axHandle, params, result)
geom = propagationGeometry(params, result.projectionRelay);

cla(axHandle);
hold(axHandle, 'on');
set(axHandle, 'Color', 'w');
axis(axHandle, [geom.xMin geom.zSliceMax -1.15 1.15]);
set(axHandle,'Visible','on','Box','off','YTick',[],'FontSize',9,'TickDir','out');
axHandle.YAxis.Visible='off';

plot(axHandle, [geom.xMin + 2 geom.xMax - 4], [0 0], 'k-', 'LineWidth', 1.1);
quiver(axHandle, geom.xMax - 8, 0, 4, 0, 0, 'k', 'LineWidth', 1.1, 'MaxHeadSize', 0.45);

drawIlluminationRays(axHandle, geom, params);
drawImagingRays(axHandle, geom, params);

drawVerticalPlane(axHandle, geom.zSourcePlane, '--', [0.45 0.45 0.45], 1.0);
drawSourceGlyph(axHandle, geom.zSourcePlane, geom.sourceHeights, false, geom.circleRadiusX, geom.circleRadiusY, params.sourceType);
drawLens(axHandle, geom.zCondenser, geom.condenserHalf, [0.15 0.15 0.15]);
drawCondenserApertureMarker(axHandle, geom, params);
drawMaskPlane(axHandle, geom.zField, geom.maskHalf, params);
drawLens(axHandle, geom.zProjection1, geom.projectionHalf, [0.76 0.76 0.76]);
drawVerticalPlane(axHandle, geom.zPupil, '--', [0.15 0.15 0.15], 1.0);
drawPupilTransmissionMarker(axHandle, geom, params);
drawLens(axHandle, geom.zProjection2, geom.projectionHalf, [0.76 0.76 0.76]);
drawImagePlane(axHandle, geom.zImage, geom.imageHalf);

% Label lane is outside the clipped ray area. Evenly spaced names have
% leaders to the actual z planes, including closely spaced high-reduction lenses.
names={'Source','Condenser','Mask','Lens 1','Pupil','Lens 2','Image'};
planes=[0 geom.zCondenser geom.zField geom.zProjection1 geom.zPupil geom.zProjection2 geom.zImage];
limits=xlim(axHandle);labelX=linspace(.045,.955,numel(names));
for j=1:numel(names)
    xLabel=limits(1)+labelX(j)*diff(limits);
    plot(axHandle,[planes(j) xLabel],[1.16 1.64],'-','Color',[.55 .61 .66],...
        'LineWidth',.65,'Clipping','off','Tag','GeometryLeader');
    text(axHandle,labelX(j),1.34,names{j},'Units','normalized','Clipping','off',...
        'HorizontalAlignment','center','FontSize',9,'FontWeight','bold','Tag','GeometryLabel');
end
set(findall(axHandle,'Type','patch'),'Clipping','on');
hold(axHandle, 'off');
t=title(axHandle,'Geometry sketch | shared z axis | transverse sizes not to scale','FontSize',10);
set(t,'Units','normalized','Position',[.5 1.90 0]);
end

function geom = propagationGeometry(params, projectionRelay)
geom = lithography_projection_geometry(params, projectionRelay);
geom.sourceHeights = sourceHeightsForSketch(params);
sourceHalf = max(abs(geom.sourceHeights));
if sourceHalf < 0.08
    sourceHalf = 0.08;
end

geom.condenserHalf = clampValue(max([0.82, sourceHalf + 0.16, geom.maskHalf + 0.12]), 0.82, 1.05);
geom.circleRadiusX = max(2.3, 0.012 * geom.totalLength);
geom.circleRadiusY = 0.11;
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
        sep = clampValue(0.72 * params.quadSeparation, 0.18, 0.72);
        heights = [-sep  sep];
    case 'Quadrupole'
        sep = clampValue(0.72 * params.quadSeparation, 0.22, 0.72);
        spread = linspace(-0.07, 0.07, rayDensityCount(params, 2, 3, 4));
        heights = sort([sep + spread, -sep + spread]);
    case 'Freeform'
        if isfield(params, 'customSourceMask') && ~isempty(params.customSourceMask)
            sourceHalf = lithography_custom_source_half(params);
            denseY = linspace(-sourceHalf, sourceHalf, size(params.customSourceMask, 1));
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

function drawIlluminationRays(axHandle, geom, params)
sourceHeights = geom.sourceHeights;
rayColor = [0.92 0.55 0.12];
sourceDistance = max(geom.zCondenser - geom.zSourcePlane, eps);
propagationDistance = geom.zField - geom.zCondenser;
focalLength = max(params.condenserFocalMm, eps);
lensHeights = illuminationRayHeights(params, geom);

for k = 1:numel(sourceHeights)
    ySource = sourceHeights(k);
    for n = 1:numel(lensHeights)
        yLens = lensHeights(n);
        slopeIn = (yLens - ySource) / sourceDistance;
        slopeOut = slopeIn - (yLens / focalLength);
        yField = yLens + slopeOut * propagationDistance;
        plot(axHandle, [geom.zSourcePlane geom.zCondenser geom.zField], ...
            [ySource yLens yField], '-', 'Color', rayColor, 'LineWidth', 1.4);
    end
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

function drawImagingRays(axHandle, geom, params)
rayColor = [0.92 0.55 0.12];
objectHeights = linspace(-0.80 * geom.maskHalf, 0.80 * geom.maskHalf, rayDensityCount(params, 3, 5, 7));
pupilHeights = projectionRayHeights(params, geom);

for k = 1:numel(objectHeights)
    yField = objectHeights(k);
    for n = 1:numel(pupilHeights)
        path = lithography_projection_ray_path(params, geom, yField, pupilHeights(n));
        plot(axHandle, path.zNodes, path.yNodes, '-', 'Color', rayColor, 'LineWidth', 1.2);
    end
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
    otherwise
        lensHeights = linspace(-0.70 * geom.projectionHalf, 0.70 * geom.projectionHalf, densityCount);
end
end

function drawSourceGlyph(axHandle, zCenter, heights, ghostMode, radiusX, radiusY, sourceType)
if ghostMode
    edgeColor = [0 0 0];
    faceColor = [1 1 1];
    lineStyle = ':';
    alphaValue = 0.18;
else
    edgeColor = [0 0 0];
    faceColor = [1.0 0.83 0.40];
    lineStyle = '-';
    alphaValue = 0.95;
end

for k = 1:numel(heights)
    xOffset = sourceGlyphOffset(k, heights, radiusX, sourceType);
    if strcmp(sourceType, 'Square')
        rectangle(axHandle, ...
            'Position', [zCenter + xOffset - 0.88 * radiusX, heights(k) - 0.88 * radiusY, 1.76 * radiusX, 1.76 * radiusY], ...
            'Curvature', [0 0], 'EdgeColor', edgeColor, 'LineStyle', lineStyle, ...
            'LineWidth', 1.1, 'FaceColor', [faceColor alphaValue]);
    else
        rectangle(axHandle, ...
            'Position', [zCenter + xOffset - radiusX, heights(k) - radiusY, 2 * radiusX, 2 * radiusY], ...
            'Curvature', [1 1], 'EdgeColor', edgeColor, 'LineStyle', lineStyle, ...
            'LineWidth', 1.1, 'FaceColor', [faceColor alphaValue]);
    end
end
end

function xOffset = sourceGlyphOffset(index, heights, radiusX, sourceType)
xOffset = 0;
if strcmp(sourceType, 'Dipole X')
    if numel(heights) >= 2
        dipoleOffsets = [-0.95 * radiusX, 0.95 * radiusX];
        xOffset = dipoleOffsets(min(index, 2));
    end
elseif numel(heights) == 4 && abs(heights(index)) > 0.12
    xOffset = 0.35 * radiusX * sign(heights(index));
end
end

function drawLens(axHandle, zCenter, halfHeight, faceColor)
t = linspace(0, 2 * pi, 300);
lensHalfWidth = max(2.0, 2.4 * halfHeight);
x = zCenter + lensHalfWidth * cos(t);
y = halfHeight * sin(t);
patch(axHandle, x, y, faceColor, 'FaceAlpha', 0.45, 'EdgeColor', 'k', 'LineWidth', 1.2);
end

function drawCondenserApertureMarker(axHandle, geom, params)
markerColor = [0 0 0];
apertureHalf = clampValue(params.condenserAperture, 0.05, 1.0) * geom.condenserHalf;
z = geom.zCondenser;
plot(axHandle, [z z], [-apertureHalf apertureHalf], '-', 'Color', markerColor, 'LineWidth', 4);
if apertureHalf < 0.98 * geom.condenserHalf
    plot(axHandle, [z z], [-geom.condenserHalf -apertureHalf], ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0);
    plot(axHandle, [z z], [apertureHalf geom.condenserHalf], ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0);
end
end

function drawPupilTransmissionMarker(axHandle, geom, params)
markerColor = [0.10 0.42 0.85];
z = geom.zPupil;

switch params.lensType
    case 'Annular'
        innerHalf = clampValue(params.lensInner * geom.projectionHalf, 0.08, 0.92 * geom.projectionHalf);
        plot(axHandle, [z z], [-geom.projectionHalf -innerHalf], '-', 'Color', markerColor, 'LineWidth', 4);
        plot(axHandle, [z z], [innerHalf geom.projectionHalf], '-', 'Color', markerColor, 'LineWidth', 4);
        plot(axHandle, [z z], [-innerHalf innerHalf], ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0);
    case 'Square'
        plot(axHandle, [z z], [-geom.projectionHalf geom.projectionHalf], '-', 'Color', markerColor, 'LineWidth', 4);
        plot(axHandle, [z-1.2 z+1.2], [-geom.projectionHalf -geom.projectionHalf], '-', 'Color', markerColor, 'LineWidth', 1.0);
        plot(axHandle, [z-1.2 z+1.2], [geom.projectionHalf geom.projectionHalf], '-', 'Color', markerColor, 'LineWidth', 1.0);
    case 'Diamond'
        plot(axHandle, [z z], [-geom.projectionHalf geom.projectionHalf], '-', 'Color', markerColor, 'LineWidth', 3.2);
        plot(axHandle, [z-0.9 z z+0.9], [0 geom.projectionHalf 0], '-', 'Color', markerColor, 'LineWidth', 1.0);
        plot(axHandle, [z-0.9 z z+0.9], [0 -geom.projectionHalf 0], '-', 'Color', markerColor, 'LineWidth', 1.0);
    case 'Horizontal Slit'
        slitHalf = clampValue(params.lensInner, 0.03, 0.90) * geom.projectionHalf;
        plot(axHandle, [z z], [-slitHalf slitHalf], '-', 'Color', markerColor, 'LineWidth', 4);
        plot(axHandle, [z z], [-geom.projectionHalf -slitHalf], ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0);
        plot(axHandle, [z z], [slitHalf geom.projectionHalf], ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0);
    case 'Vertical Slit'
        plot(axHandle, [z z], [-geom.projectionHalf geom.projectionHalf], '-', 'Color', markerColor, 'LineWidth', 4);
        plot(axHandle, [z-0.9 z+0.9], [0 0], '-', 'Color', markerColor, 'LineWidth', 1.2);
    case 'Freeform'
        plot(axHandle, [z z], [-geom.projectionHalf geom.projectionHalf], '-', 'Color', markerColor, 'LineWidth', 3.2);
        if isfield(params, 'customPupilMask') && ~isempty(params.customPupilMask)
            rowWeights = sum(double(params.customPupilMask), 2);
            denseY = linspace(-geom.projectionHalf, geom.projectionHalf, numel(rowWeights));
            active = rowWeights > 0.12 * max(rowWeights(:));
            activeY = denseY(active);
            if ~isempty(activeY)
                sampleIdx = round(linspace(1, numel(activeY), min(numel(activeY), 9)));
                activeY = activeY(sampleIdx);
            end
            for idx = 1:numel(activeY)
                plot(axHandle, [z - 0.75 z + 0.75], [activeY(idx) activeY(idx)], '-', ...
                    'Color', markerColor, 'LineWidth', 1.0);
            end
        end
    otherwise
        plot(axHandle, [z z], [-geom.projectionHalf geom.projectionHalf], '-', 'Color', markerColor, 'LineWidth', 4);
end
end

function drawMaskPlane(axHandle, zCenter, maskHalf, params)
maskType = params.maskType;
featureMarkHalfWidth = 1.4;
plot(axHandle, [zCenter zCenter], [-1.05 -maskHalf], 'k-', 'LineWidth', 5);
plot(axHandle, [zCenter zCenter], [maskHalf 1.05], 'k-', 'LineWidth', 5);
if strcmp(maskType, 'Annular Aperture')
    innerHalf = clampValue(params.maskInnerRatio, 0.05, 0.95) * maskHalf;
    plot(axHandle, [zCenter zCenter], [-maskHalf -innerHalf], '-', 'Color', [0.10 0.58 0.22], 'LineWidth', 7);
    plot(axHandle, [zCenter zCenter], [innerHalf maskHalf], '-', 'Color', [0.10 0.58 0.22], 'LineWidth', 7);
    plot(axHandle, [zCenter zCenter], [-innerHalf innerHalf], ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0);
else
    plot(axHandle, [zCenter zCenter], [-maskHalf maskHalf], '-', 'Color', [0.10 0.58 0.22], 'LineWidth', 7);
end

if strcmp(maskType, '1D Grating')
    for y0 = linspace(-0.75 * maskHalf, 0.75 * maskHalf, 5)
        plot(axHandle, [zCenter - featureMarkHalfWidth zCenter + featureMarkHalfWidth], [y0 y0], ...
            'Color', [0 0 0], 'LineWidth', 1.0);
    end
elseif strcmp(maskType, '2D Grating')
    for y0 = linspace(-0.75 * maskHalf, 0.75 * maskHalf, 5)
        plot(axHandle, [zCenter - featureMarkHalfWidth zCenter + featureMarkHalfWidth], [y0 y0], ...
            'Color', [0 0 0], 'LineWidth', 1.0);
    end
    plot(axHandle, [zCenter - featureMarkHalfWidth zCenter + featureMarkHalfWidth], [0 0], ...
        'Color', [0 0 0], 'LineWidth', 1.2);
elseif strcmp(maskType, 'Cross')
    plot(axHandle, [zCenter - featureMarkHalfWidth zCenter + featureMarkHalfWidth], [0 0], ...
        'Color', [0 0 0], 'LineWidth', 1.2);
elseif strcmp(maskType, 'Diamond Aperture')
    plot(axHandle, [zCenter - featureMarkHalfWidth zCenter zCenter + featureMarkHalfWidth], [0 0.55 * maskHalf 0], ...
        'Color', [0 0 0], 'LineWidth', 1.0);
    plot(axHandle, [zCenter - featureMarkHalfWidth zCenter zCenter + featureMarkHalfWidth], [0 -0.55 * maskHalf 0], ...
        'Color', [0 0 0], 'LineWidth', 1.0);
end
end

function drawImagePlane(axHandle, zCenter, imageHalf)
plot(axHandle, [zCenter zCenter], [-1.0 1.0], 'k-', 'LineWidth', 1.2);
plot(axHandle, [zCenter zCenter], [-imageHalf imageHalf], '-', 'Color', [0.10 0.58 0.22], 'LineWidth', 5);
end

function drawVerticalPlane(axHandle, zCenter, lineStyle, colorValue, lineWidth)
plot(axHandle, [zCenter zCenter], [-1.02 1.02], lineStyle, 'Color', colorValue, 'LineWidth', lineWidth);
end

function drawDoubleArrow(axHandle, x1, x2, y, labelText, colorValue)
plot(axHandle, [x1 x2], [y y], '-', 'Color', colorValue, 'LineWidth', 1.1);
plot(axHandle, [x1 x1], [-0.02 y], '-', 'Color', colorValue, 'LineWidth', 0.9);
plot(axHandle, [x2 x2], [-0.02 y], '-', 'Color', colorValue, 'LineWidth', 0.9);
span = abs(x2 - x1);
headDx = max(2.0, 0.06 * span);
headDy = 0.045;
plot(axHandle, [x1 x1 + headDx], [y y + headDy], '-', 'Color', colorValue, 'LineWidth', 1.1);
plot(axHandle, [x1 x1 + headDx], [y y - headDy], '-', 'Color', colorValue, 'LineWidth', 1.1);
plot(axHandle, [x2 x2 - headDx], [y y + headDy], '-', 'Color', colorValue, 'LineWidth', 1.1);
plot(axHandle, [x2 x2 - headDx], [y y - headDy], '-', 'Color', colorValue, 'LineWidth', 1.1);
text(axHandle, 0.5 * (x1 + x2), y + 0.07, labelText, ...
    'HorizontalAlignment', 'center', 'Color', colorValue, 'FontSize', 9, 'FontWeight', 'bold');
end

function value = clampValue(value, lowValue, highValue)
value = min(max(value, lowValue), highValue);
end

function count = rayDensityCount(params, lowCount, mediumCount, highCount, varargin)
if isempty(varargin)
    ultraHighCount = highCount + max(2, ceil(0.4 * highCount));
else
    ultraHighCount = varargin{1};
end
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

function tf = isNearPointSource(params)
tf = strcmp(params.sourceType, 'Point') || ...
    (strcmp(params.sourceType, 'Circular') && params.sourceOuter <= 0.05) || ...
    (strcmp(params.sourceType, 'Square') && params.sourceOuter <= 0.05) || ...
    (strcmp(params.sourceType, 'Annular') && params.sourceOuter <= 0.05) || ...
    (any(strcmp(params.sourceType, {'Dipole X', 'Dipole Y'})) && ...
        params.sourceOuter <= 0.03 && params.quadSeparation <= 0.06);
end
