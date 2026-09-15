function pupilMask = lithography_default_custom_pupil(gridSize)
if nargin < 1 || ~isfinite(gridSize) || gridSize < 17
    gridSize = 129;
end

axisValues = linspace(-1, 1, round(gridSize));
[U, V] = meshgrid(axisValues, axisValues);
pupilMask = double(U.^2 + V.^2 <= 1);
end
