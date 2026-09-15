function [u,v,w] = lithography_wave_source_samples(~,result)
% Identical source quadrature at every plane, including dark cases.
u=result.sourceSamplesU; v=result.sourceSamplesV; w=result.sourceWeights;
end
