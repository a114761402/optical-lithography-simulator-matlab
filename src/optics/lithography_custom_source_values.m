function values = lithography_custom_source_values(U, V, params)
if ~isfield(params, 'customSourceMask') || isempty(params.customSourceMask)
    mask = lithography_default_custom_source();
else
    mask = double(params.customSourceMask);
end

if size(mask, 1) ~= size(mask, 2)
    side = min(size(mask, 1), size(mask, 2));
    mask = mask(1:side, 1:side);
end

mask(~isfinite(mask)) = 0;
mask = min(max(mask, 0), 1);
if isscalar(mask)
    values = mask .* double(abs(U)<=1 & abs(V)<=1);
    return;
end

axisValues = linspace(-1, 1, size(mask, 1));
values = interp2(axisValues, axisValues, mask, U, V, 'linear', 0);
values(~isfinite(values)) = 0;
values = min(max(values, 0), 1);
end
