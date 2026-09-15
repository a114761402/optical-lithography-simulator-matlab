function p=lithography_benchmark_params()
% Internal mathematical regression only; NOT an accepted GUI configuration.
p=lithography_reference_params();p.enforceLimits=false;
p.illuminationModel='Legacy angular benchmark';
p.projNA=.75;p.propagationPadding=2;p.sourceGridSize=101;
end
