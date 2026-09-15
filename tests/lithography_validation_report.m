function report=lithography_validation_report(displayReport)
% Independent analytic and adversarial regressions replace visual plausibility checks.
if nargin<1,displayReport=true;end
report=lithography_regression_tests(displayReport);
end
