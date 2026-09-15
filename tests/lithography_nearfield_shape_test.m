function report = lithography_nearfield_shape_test(displayReport)
if nargin < 1
    displayReport = true;
end

showcases = lithography_showcase_library();
targetNames = {'Near-field square @0.05 mm', 'Near-field square @0.1 mm', 'Near-field grating @0.1 mm'};
reports = repmat(struct('name', '', 'correlation', 0, 'pass', false), 1, numel(targetNames));

for k = 1:numel(targetNames)
    idx = find(strcmp({showcases.name}, targetNames{k}), 1);
    assert(~isempty(idx), 'Missing expected near-field showcase: %s', targetNames{k});
    params = showcases(idx).params;
    params=lithography_check_settings(params);
    result = lithography_run_physics(params);
    fieldSlice = lithography_compute_xy_slice(params, result, params.sourceToCondenserMm + params.condenserFocalMm);
    nearSlice = lithography_compute_xy_slice(params, result, params.xySliceZMm);
    % Base-MATLAB correlation; no Statistics Toolbox needed for this check.
    correlation = corrcoef(fieldSlice.intensity(:), nearSlice.intensity(:));
    corrValue = correlation(1,2);

    reports(k).name = targetNames{k};
    reports(k).correlation = corrValue;
    if contains(targetNames{k}, '@0.05 mm')
        reports(k).pass = corrValue > 0.88;
    else
        reports(k).pass = corrValue > 0.75;
    end
end

report = struct();
report.pass = all([reports.pass]);
report.cases = reports;

if displayReport
    if report.pass
        fprintf('Near-field shape test passed.\n');
    else
        fprintf('Near-field shape test failed.\n');
    end
    for k = 1:numel(reports)
        status = 'PASS';
        if ~reports(k).pass
            status = 'FAIL';
        end
        fprintf('  [%s] %s | correlation %.4f\n', status, reports(k).name, reports(k).correlation);
    end
end
end
