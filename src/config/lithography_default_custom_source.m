function sourceMask = lithography_default_custom_source(gridSize,radius)
if nargin<2,radius=.70;end
if nargin < 1 || ~isfinite(gridSize) || gridSize < 17
    gridSize = 129;
end

axisValues = linspace(-1, 1, round(gridSize));
[U, V] = meshgrid(axisValues, axisValues);
sourceMask = double(U.^2 + V.^2 <= radius^2);
end
