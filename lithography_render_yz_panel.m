function lithography_render_yz_panel(axHandle, yzData)
% A manually positioned MATLAB colorbar can survive cla and become orphaned.
if isappdata(axHandle,'colorbarHandle')
    previous=getappdata(axHandle,'colorbarHandle');
    if isgraphics(previous),delete(previous);end
    rmappdata(axHandle,'colorbarHandle');
end
colorbar(axHandle,'off');
cla(axHandle);
set(axHandle, 'Color', 'w');

if nargin < 2 || isempty(yzData)
    colorbar(axHandle,'off');
    axis(axHandle, [0 1 0 1]);
    axis(axHandle, 'off');
    text(axHandle, 0.5, 0.60, 'Sampled full-path wave preview', ...
        'Units','normalized','HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
    text(axHandle, 0.5, 0.42, 'Turn on Auto YZ or press "Update YZ". Then click a z plane.', ...
        'Units','normalized','HorizontalAlignment', 'center', 'FontSize', 10, 'Color', [0.25 0.25 0.25]);
    return;
end

axis(axHandle,'on');
wave=isfield(yzData,'axisHalfWidthMm');
if wave
    set(axHandle,'Color',[.90 .93 .96]);
    scale='Local / z';
    if isappdata(axHandle,'previewScale'),scale=getappdata(axHandle,'previewScale');end
    display=lithography_preview_display(yzData,scale);
    [Z,Y]=meshgrid(yzData.zMm,yzData.yNorm);
    if isfield(yzData,'yPhysicalMm'),Y=yzData.yPhysicalMm;end
    surface(axHandle,Z,Y,zeros(size(Z)),display.values,'FaceColor','interp','EdgeColor','none','Tag','WavePreview');
    view(axHandle,2);
else
    imagesc(axHandle, yzData.zMm, yzData.yNorm, yzData.intensity);
end
set(axHandle, 'YDir', 'normal');
axis(axHandle, 'tight');
colormap(axHandle, hot(256));
caxis(axHandle, [0 1]);
if wave,caxis(axHandle,display.limits);end
if isfield(yzData,'axisLimitsMm'),xlim(axHandle,yzData.axisLimitsMm);end
set(axHandle, 'FontSize', 9);
axPosition = get(axHandle, 'Position');
if wave
    title(axHandle,{sprintf('Wave preview: x = 0 | %d modes | %d calculated z planes',yzData.sourceSampleCount,numel(yzData.zMm)),...
        display.note,'Physical y scale; fine focus needs XY | grey = outside sampled window'},'FontSize',9);
elseif isfield(yzData, 'mode') && isfield(yzData, 'view') && isfield(yzData, 'normalizationMode')
    title(axHandle, 'YZ ray-density schematic (NOT a diffraction calculation)', 'FontSize', 11);
elseif isfield(yzData, 'mode') && isfield(yzData, 'view')
    title(axHandle, sprintf('YZ intensity (%s, %s)', yzData.mode, yzData.view), 'FontSize', 11);
elseif isfield(yzData, 'mode')
    title(axHandle, sprintf('YZ intensity (%s)', yzData.mode), 'FontSize', 11);
else
    title(axHandle, 'YZ intensity', 'FontSize', 11);
end
xlabel(axHandle, 'z along system (mm)', 'FontSize', 9);
ylabel(axHandle, 'normalized y', 'FontSize', 9);
if wave
    ylabel(axHandle,'y / half-width','FontSize',9);
    if isfield(yzData,'yPhysicalMm'),ylabel(axHandle,'y (mm)','FontSize',9);end
end

hold(axHandle, 'on');
drawPlaneMarker(axHandle, yzData.planes.condenser,'C');
drawPlaneMarker(axHandle, yzData.planes.projection1,'L1');
drawPlaneMarker(axHandle, yzData.planes.source, 'Source');
drawPlaneMarker(axHandle, yzData.planes.field, 'Mask');
drawPlaneMarker(axHandle, yzData.planes.pupil, 'Pupil');
drawPlaneMarker(axHandle, yzData.planes.projection2,'L2');
drawPlaneMarker(axHandle, yzData.planes.image, 'Image');
if isfield(yzData, 'labels')
    drawElementLabel(axHandle, yzData.planes.condenser, yzData.labels.condenser);
    drawElementLabel(axHandle, yzData.planes.field, yzData.labels.fieldElement);
    drawElementLabel(axHandle, 0.5 * (yzData.planes.projection1 + yzData.planes.projection2), yzData.labels.projection);
end
hold(axHandle, 'off');

cb = colorbar(axHandle, 'eastoutside');
setappdata(axHandle,'colorbarHandle',cb);
if wave
    cb.Label.String=display.label;
elseif isfield(yzData, 'normalizationMode') && strcmp(yzData.normalizationMode, 'XYZ')
    cb.Label.String = 'XYZ scale';
elseif wave
    cb.Label.String = 'Local / z';
else
    cb.Label.String = 'Relative ray density (schematic only)';
end
cb.Ticks = [0 0.5 1];
if wave,cb.Ticks=display.ticks;end
cb.FontSize = 8;
cb.Label.FontSize = 8;
set(axHandle, 'Position', axPosition);
gap = 0.008;
cbWidth = 0.012;
set(cb,'Units',get(axHandle,'Units'));
if strcmp(get(axHandle,'Units'),'pixels'),gap=12;cbWidth=12;end
cbPos = [axPosition(1) + axPosition(3) + gap, axPosition(2), cbWidth, axPosition(4)];
set(cb, 'Position', cbPos);
end

function drawPlaneMarker(axHandle, zValue, labelText)
yLimits = ylim(axHandle);
xLimits = xlim(axHandle);
offset = 0.02 * (xLimits(2) - xLimits(1));
textX = zValue;
alignment = 'center';
if zValue <= xLimits(1) + offset
    textX = zValue + offset;
    alignment = 'left';
elseif zValue >= xLimits(2) - offset
    textX = zValue - offset;
    alignment = 'right';
end
plot(axHandle, [zValue zValue], yLimits, '--', 'Color', [0.90 0.90 0.90], 'LineWidth', 0.9);
labelHeight=.08;
if strcmp(labelText,'L2'),labelHeight=.35;end
if strcmp(labelText,'Image'),labelHeight=.62;end
text(axHandle, textX, yLimits(2) - labelHeight * (yLimits(2) - yLimits(1)), labelText, ...
    'HorizontalAlignment', alignment, 'VerticalAlignment', 'top', ...
    'Color', [1 1 1], 'BackgroundColor',[.10 .13 .16],'Margin',1,...
    'FontSize', 9, 'FontWeight', 'bold');
end

function drawElementMarker(axHandle, zValue)
yLimits = ylim(axHandle);
plot(axHandle, [zValue zValue], yLimits, '-', 'Color', [0.60 0.60 0.60], 'LineWidth', 0.8);
end

function drawElementLabel(axHandle, zValue, labelText)
yLimits = ylim(axHandle);
xLimits = xlim(axHandle);
offset = 0.02 * (xLimits(2) - xLimits(1));
textX = min(max(zValue, xLimits(1) + offset), xLimits(2) - offset);
text(axHandle, textX, yLimits(1) + 0.06 * (yLimits(2) - yLimits(1)), labelText, ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
    'Color', [0.88 0.88 0.88], 'FontSize', 8, 'FontWeight', 'bold');
end
