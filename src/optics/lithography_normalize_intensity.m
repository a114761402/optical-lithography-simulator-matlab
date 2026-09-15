function [normalizedData, normalizationPeak] = lithography_normalize_intensity(rawData, params, result, sharedPeak)
if nargin < 4
    sharedPeak = [];
end

localPeak = max(rawData(:));

normMode = 'Local';
if nargin >= 2 && isstruct(params) && isfield(params, 'intensityNorm') && ~isempty(params.intensityNorm)
    normMode = params.intensityNorm;
end

if ~isempty(sharedPeak) && isfinite(sharedPeak) && sharedPeak > 0
    normalizationPeak = sharedPeak;
else
    if strcmp(normMode,'XYZ') && nargin>=3 && isfield(result,'xyzReferencePeak')
        normalizationPeak=result.xyzReferencePeak;
    else
        normalizationPeak = localPeak;
    end
end

normalizedData = rawData;
if normalizationPeak > 0
    normalizedData = rawData / normalizationPeak;
end
end
