function lithography_render_yz_panel(axHandle, yzData)
cla(axHandle);
set(axHandle, 'Color', 'w');

if nargin < 2 || isempty(yzData)
    axis(axHandle, [0 1 0 1]);
    axis(axHandle, 'off');
    text(axHandle, 0.5, 0.60, 'YZ intensity', ...
        'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
    text(axHandle, 0.5, 0.42, 'Turn on Auto YZ or press "Update YZ". Then click a z plane.', ...
        'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', [0.25 0.25 0.25]);
    return;
end

imagesc(axHandle, yzData.zMm, yzData.yNorm, yzData.intensity);
set(axHandle, 'YDir', 'normal');
axis(axHandle, 'tight');
colormap(axHandle, hot(256));
caxis(axHandle, [0 1]);
set(axHandle, 'FontSize', 9);
axPosition = get(axHandle, 'Position');
if isfield(yzData, 'mode') && isfield(yzData, 'view') && isfield(yzData, 'normalizationMode')
    title(axHandle, sprintf('YZ intensity (%s, %s, %s norm)', yzData.mode, yzData.view, yzData.normalizationMode), 'FontSize', 11);
elseif isfield(yzData, 'mode') && isfield(yzData, 'view')
    title(axHandle, sprintf('YZ intensity (%s, %s)', yzData.mode, yzData.view), 'FontSize', 11);
elseif isfield(yzData, 'mode')
    title(axHandle, sprintf('YZ intensity (%s)', yzData.mode), 'FontSize', 11);
else
    title(axHandle, 'YZ intensity', 'FontSize', 11);
end
xlabel(axHandle, 'z along system (mm)', 'FontSize', 9);
ylabel(axHandle, 'normalized y', 'FontSize', 9);

hold(axHandle, 'on');
drawElementMarker(axHandle, yzData.planes.condenser);
drawElementMarker(axHandle, yzData.planes.projection1);
drawPlaneMarker(axHandle, yzData.planes.source, 'Source');
drawPlaneMarker(axHandle, yzData.planes.field, 'Field');
drawPlaneMarker(axHandle, yzData.planes.pupil, 'Pupil');
drawElementMarker(axHandle, yzData.planes.projection2);
drawPlaneMarker(axHandle, yzData.planes.image, 'Image');
if isfield(yzData, 'labels')
    drawElementLabel(axHandle, yzData.planes.condenser, yzData.labels.condenser);
    drawElementLabel(axHandle, yzData.planes.field, yzData.labels.fieldElement);
    drawElementLabel(axHandle, 0.5 * (yzData.planes.projection1 + yzData.planes.projection2), yzData.labels.projection);
end
hold(axHandle, 'off');

cb = colorbar(axHandle, 'eastoutside');
if isfield(yzData, 'normalizationMode') && strcmp(yzData.normalizationMode, 'XYZ')
    cb.Label.String = 'Normalized intensity (XYZ)';
else
    cb.Label.String = 'Normalized intensity';
end
cb.Ticks = [0 0.5 1];
cb.FontSize = 8;
cb.Label.FontSize = 8;
set(axHandle, 'Position', axPosition);
gap = 0.008;
cbWidth = 0.012;
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
text(axHandle, textX, yLimits(2) - 0.08 * (yLimits(2) - yLimits(1)), labelText, ...
    'HorizontalAlignment', alignment, 'VerticalAlignment', 'top', ...
    'Color', [1 1 1], 'FontSize', 9, 'FontWeight', 'bold');
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
