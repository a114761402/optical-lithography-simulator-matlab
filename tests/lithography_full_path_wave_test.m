function report=lithography_full_path_wave_test(displayReport)
% Separate full illumination validation from the legacy angular-input references.
if nargin<1,displayReport=true;end
a=lithography_regression_tests(displayReport);
b=lithography_illumination_tests(displayReport);
report=struct('pass',a.pass && b.pass,'passCount',a.passCount+b.passCount,...
    'totalCount',a.totalCount+b.totalCount,'relay',a,'illumination',b);
end
