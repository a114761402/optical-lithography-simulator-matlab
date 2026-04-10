function [sampleU, sampleV, sampleW] = lithography_wave_source_samples(params, result)
if strcmp(params.sourceType, 'Point')
    if hypot(params.pointSourceU, params.pointSourceV) <= params.condenserAperture + 1e-12
        sampleU = params.pointSourceU;
        sampleV = params.pointSourceV;
        sampleW = 1;
    else
        sampleU = 0;
        sampleV = 0;
        sampleW = 1;
    end
    return;
end

switch params.sourceType
    case 'Circular'
        outerRadius = min(params.sourceOuter, params.condenserAperture);
        [sampleU, sampleV, sampleW] = polarDiskSamples(0, outerRadius, 19);
    case 'Annular'
        outerRadius = min(params.sourceOuter, params.condenserAperture);
        innerRadius = min(params.sourceInner, outerRadius);
        [sampleU, sampleV, sampleW] = polarDiskSamples(innerRadius, outerRadius, 19);
    otherwise
        sampleU = result.sourceSamplesU(:);
        sampleV = result.sourceSamplesV(:);
        if isfield(result, 'sourceWeights')
            sampleW = result.sourceWeights(:);
        else
            sampleW = ones(size(sampleU));
        end
        sampleW = sampleW / max(sum(sampleW), eps);
end
end

function [sampleU, sampleV, sampleW] = polarDiskSamples(innerRadius, outerRadius, radialCount)
sampleU = [];
sampleV = [];
sampleW = [];

radialEdges = linspace(innerRadius, outerRadius, radialCount + 1);
for ir = 1:radialCount
    r0 = radialEdges(ir);
    r1 = radialEdges(ir + 1);
    rMid = 0.5 * (r0 + r1);
    shellArea = pi * (r1^2 - r0^2);
    azCount = max(8, ceil(2 * pi * max(rMid, outerRadius / radialCount) / max(outerRadius, eps) * 18));
    theta = linspace(0, 2 * pi, azCount + 1);
    theta(end) = [];
    sampleU = [sampleU; rMid * cos(theta(:))]; %#ok<AGROW>
    sampleV = [sampleV; rMid * sin(theta(:))]; %#ok<AGROW>
    sampleW = [sampleW; repmat(shellArea / azCount, azCount, 1)]; %#ok<AGROW>
end

sampleW = sampleW / max(sum(sampleW), eps);
end
