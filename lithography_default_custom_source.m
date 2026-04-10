function sourceMask = lithography_default_custom_source(gridSize)
if nargin < 1 || ~isfinite(gridSize) || gridSize < 17
    gridSize = 129;
end

axisValues = linspace(-1, 1, round(gridSize));
[U, V] = meshgrid(axisValues, axisValues);
sourceMask = double(U.^2 + V.^2 <= 0.70^2);
end
