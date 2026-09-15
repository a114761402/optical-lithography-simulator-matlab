function halfWidth = lithography_custom_source_half(params)
halfWidth = 0.70;

if ~isfield(params, 'customSourceMask') || isempty(params.customSourceMask)
    return;
end

mask = double(params.customSourceMask);
if isempty(mask)
    return;
end

mask(~isfinite(mask)) = 0;
rowWeights = sum(mask, 2);
colWeights = sum(mask, 1);
peakWeight = max([rowWeights(:); colWeights(:); 0]);
if peakWeight <= 0
    return;
end

axisValues = linspace(-1, 1, size(mask, 1));
activeRows = abs(axisValues(rowWeights > 0.05 * peakWeight));
activeCols = abs(axisValues(colWeights > 0.05 * peakWeight));
if isempty(activeRows) && isempty(activeCols)
    return;
end

halfWidth = max([0.08; activeRows(:); activeCols(:)]);
halfWidth = min(max(halfWidth, 0.08), 1.0);
end
