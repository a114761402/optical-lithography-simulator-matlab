function [shapeMask, accepted] = lithography_edit_freeform_shape(initialMask, windowName, titleText)
if nargin < 1 || isempty(initialMask)
    initialMask = lithography_default_custom_pupil();
end
if nargin < 2 || isempty(windowName)
    windowName = 'Freeform Shape Editor';
end
if nargin < 3 || isempty(titleText)
    titleText = 'Freeform transmission / weight';
end

shapeMask = double(initialMask);
shapeMask = min(max(shapeMask, 0), 1);
accepted = false;

editor = struct();
editor.isPainting = false;
editor.fig = figure( ...
    'Name', windowName, ...
    'NumberTitle', 'off', ...
    'Tag', 'LithographyFreeformEditor', ...
    'Color', [0.96 0.96 0.96], ...
    'MenuBar', 'none', ...
    'ToolBar', 'none', ...
    'Position', [220 160 760 560], ...
    'CloseRequestFcn', @cancelAndClose);

editor.ax = axes('Parent', editor.fig, 'Units', 'normalized', 'Position', [0.08 0.18 0.52 0.74]);
editor.image = imagesc(editor.ax, [-1 1], [-1 1], shapeMask);
axis(editor.ax, 'image');
set(editor.ax, 'YDir', 'normal', 'FontSize', 10, 'ButtonDownFcn', @startPaint);
set(editor.image, 'ButtonDownFcn', @startPaint);
if isprop(editor.image, 'PickableParts')
    set(editor.image, 'PickableParts', 'all');
end
colormap(editor.ax, gray(256));
caxis(editor.ax, [0 1]);
title(editor.ax, titleText);
xlabel(editor.ax, 'normalized x');
ylabel(editor.ax, 'normalized y');
hold(editor.ax, 'on');
guideHandle = plot(editor.ax, cos(linspace(0, 2 * pi, 240)), sin(linspace(0, 2 * pi, 240)), ...
    'c--', 'LineWidth', 1.0);
set(guideHandle, 'HitTest', 'off');
if isprop(guideHandle, 'PickableParts')
    set(guideHandle, 'PickableParts', 'none');
end
hold(editor.ax, 'off');

editor.modeLabel = uicontrol(editor.fig, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [0.66 0.85 0.24 0.04], 'String', 'Brush mode', ...
    'HorizontalAlignment', 'left', 'BackgroundColor', get(editor.fig, 'Color'), 'FontWeight', 'bold');
editor.modePopup = uicontrol(editor.fig, 'Style', 'popupmenu', 'Units', 'normalized', ...
    'Position', [0.66 0.80 0.24 0.05], 'String', {'Paint open', 'Paint block'}, 'Value', 1);

editor.brushLabel = uicontrol(editor.fig, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [0.66 0.72 0.24 0.04], 'String', 'Brush radius', ...
    'HorizontalAlignment', 'left', 'BackgroundColor', get(editor.fig, 'Color'), 'FontWeight', 'bold');
editor.brushValue = uicontrol(editor.fig, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [0.87 0.68 0.08 0.04], 'String', '0.10', ...
    'HorizontalAlignment', 'right', 'BackgroundColor', get(editor.fig, 'Color'));
editor.brushSlider = uicontrol(editor.fig, 'Style', 'slider', 'Units', 'normalized', ...
    'Position', [0.66 0.68 0.19 0.04], 'Min', 0.03, 'Max', 0.30, 'Value', 0.10, ...
    'Callback', @updateBrushValue);

editor.helpText = uicontrol(editor.fig, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [0.62 0.48 0.32 0.15], ...
    'String', sprintf(['Left-drag inside the plot to paint.\n' ...
                       'Paint open adds transmission / source weight.\n' ...
                       'Paint block removes it.\n' ...
                       'Use the shape buttons for quick setup.']), ...
    'HorizontalAlignment', 'left', 'BackgroundColor', get(editor.fig, 'Color'));

buttonWidth = 0.14;
buttonHeight = 0.06;
leftX = 0.64;
rightX = 0.80;
row1 = 0.38;
row2 = 0.30;
row3 = 0.22;

uicontrol(editor.fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [leftX row1 buttonWidth buttonHeight], 'String', 'Clear', 'Callback', @clearMask);
uicontrol(editor.fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [rightX row1 buttonWidth buttonHeight], 'String', 'Fill', 'Callback', @fillMask);
uicontrol(editor.fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [leftX row2 buttonWidth buttonHeight], 'String', 'Disk', 'Callback', @diskMask);
uicontrol(editor.fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [rightX row2 buttonWidth buttonHeight], 'String', 'Square', 'Callback', @squareMask);
uicontrol(editor.fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [leftX row3 buttonWidth buttonHeight], 'String', 'Annulus', 'Callback', @annulusMask);
uicontrol(editor.fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [rightX row3 buttonWidth buttonHeight], 'String', 'Invert', 'Callback', @invertMask);
uicontrol(editor.fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [0.64 0.12 0.14 buttonHeight], 'String', 'Done', 'Callback', @acceptAndClose);
uicontrol(editor.fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [0.80 0.12 0.14 buttonHeight], 'String', 'Cancel', 'Callback', @cancelAndClose);

set(editor.fig, 'WindowButtonUpFcn', @stopPaint);
guidata(editor.fig, editor);
uiwait(editor.fig);

    function updateBrushValue(src, ~)
        set(editor.brushValue, 'String', sprintf('%.2f', get(src, 'Value')));
    end

    function clearMask(~, ~)
        shapeMask = zeros(size(shapeMask));
        refreshMask();
    end

    function fillMask(~, ~)
        shapeMask = ones(size(shapeMask));
        refreshMask();
    end

    function diskMask(~, ~)
        shapeMask = lithography_default_custom_pupil(size(shapeMask, 1));
        refreshMask();
    end

    function squareMask(~, ~)
        shapeMask = ones(size(shapeMask));
        refreshMask();
    end

    function annulusMask(~, ~)
        axisValues = linspace(-1, 1, size(shapeMask, 1));
        [U, V] = meshgrid(axisValues, axisValues);
        radius = sqrt(U.^2 + V.^2);
        shapeMask = double(radius <= 0.80 & radius >= 0.45);
        refreshMask();
    end

    function invertMask(~, ~)
        shapeMask = 1 - shapeMask;
        refreshMask();
    end

    function startPaint(src, ~)
        figHandle = ancestor(src, 'figure');
        editorLocal = guidata(figHandle);
        editorLocal.isPainting = true;
        guidata(editorLocal.fig, editorLocal);
        applyBrushAtCurrentPoint(editorLocal.fig);
        set(editorLocal.fig, 'WindowButtonMotionFcn', @paintMotion);
    end

    function paintMotion(src, ~)
        editorLocal = guidata(src);
        if editorLocal.isPainting
            applyBrushAtCurrentPoint(src);
        end
    end

    function stopPaint(src, ~)
        if ~ishghandle(src)
            return;
        end
        editorLocal = guidata(src);
        editorLocal.isPainting = false;
        guidata(src, editorLocal);
        set(src, 'WindowButtonMotionFcn', '');
    end

    function applyBrushAtCurrentPoint(figHandle)
        editorLocal = guidata(figHandle);
        point = get(editorLocal.ax, 'CurrentPoint');
        u = point(1, 1);
        v = point(1, 2);
        if u < -1 || u > 1 || v < -1 || v > 1
            return;
        end

        brushRadius = get(editorLocal.brushSlider, 'Value');
        axisValues = linspace(-1, 1, size(shapeMask, 1));
        [U, V] = meshgrid(axisValues, axisValues);
        brushMask = (U - u).^2 + (V - v).^2 <= brushRadius^2;

        if get(editorLocal.modePopup, 'Value') == 1
            shapeMask(brushMask) = 1;
        else
            shapeMask(brushMask) = 0;
        end
        refreshMask();
    end

    function refreshMask()
        if ~ishandle(editor.image)
            return;
        end
        set(editor.image, 'CData', shapeMask);
        drawnow;
    end

    function acceptAndClose(~, ~)
        accepted = true;
        if ishghandle(editor.fig)
            uiresume(editor.fig);
            delete(editor.fig);
        end
    end

    function cancelAndClose(~, ~)
        accepted = false;
        if ishghandle(editor.fig)
            uiresume(editor.fig);
            delete(editor.fig);
        end
    end
end
