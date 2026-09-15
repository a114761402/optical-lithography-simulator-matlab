function report=lithography_intermediate_xy_physicality_test(displayReport)
% Analytic Gaussian tests replace the old forced radial-symmetry test.
if nargin<1,displayReport=true;end
report=lithography_regression_tests(displayReport);
end
