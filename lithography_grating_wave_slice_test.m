function report = lithography_grating_wave_slice_test(displayReport)
if nargin < 1
    displayReport = true;
end

base = lithography_default_params();
base.sourceType = 'Circular';
base.sourceOuter = 0.7;
base.condenserAperture = 1;
base.maskType = '1D Grating';
base.gratingSizeUm = 2;
base.gratingPitchUm = 0.8;
base.gratingDuty = 0.5;
base.lensType = 'Circular';
base.projNA = 0.75;
base.reduction = 4;
base.wavelengthNm = 193;
base.fieldSizeUm = 8;
base.defocusUm = 0;
base.sourceToCondenserMm = 60;
base.condenserFocalMm = 60;
base.fieldToPupilMm = 85;
base.projectionFocalMm = 85;

coarse = base;
coarse.gridSize = 256;

dense = base;
dense.gridSize = 384;

zValues = [120.2, 122.0, 130.0];
cases = repmat(struct( ...
    'zMm', 0, ...
    'relativeError', 0, ...
    'pass', false), numel(zValues), 1);

for k = 1:numel(zValues)
    zMm = zValues(k);
    coarseResult = lithography_run_physics(coarse);
    denseResult = lithography_run_physics(dense);
    coarseSlice = lithography_compute_xy_slice(coarse, coarseResult, zMm);
    denseSlice = lithography_compute_xy_slice(dense, denseResult, zMm);

    [Xq, Yq] = meshgrid(coarseSlice.axis, coarseSlice.axis);
    [Xd, Yd] = meshgrid(denseSlice.axis, denseSlice.axis);
    denseOnCoarse = interp2(Xd, Yd, denseSlice.intensity, Xq, Yq, 'linear', 0);
    relativeError = norm(coarseSlice.intensity(:) - denseOnCoarse(:)) / max(norm(denseOnCoarse(:)), eps);

    cases(k).zMm = zMm;
    cases(k).relativeError = relativeError;
    cases(k).pass = relativeError < 0.03;
end

report = struct();
report.pass = all([cases.pass]);
report.cases = cases;
report.summary = '1D grating pre-lens slices should stay stable when recomputed on a denser grid.';

if displayReport
    if report.pass
        fprintf('Grating wave-slice test passed.\n');
    else
        fprintf('Grating wave-slice test failed.\n');
    end
    fprintf('  %s\n', report.summary);
    for k = 1:numel(cases)
        status = 'PASS';
        if ~cases(k).pass
            status = 'FAIL';
        end
        fprintf('  [%s] z = %.1f mm | relative error %.4f\n', ...
            status, cases(k).zMm, cases(k).relativeError);
    end
end
end
