function report = lithography_validation_report(displayReport)
if nargin < 1
    displayReport = true;
end

cases = validationCases();
caseReports = repmat(struct( ...
    'name', '', ...
    'kind', '', ...
    'pass', false, ...
    'pupilError', nan, ...
    'imageContrast', nan, ...
    'messages', {{}}, ...
    'summary', ''), numel(cases), 1);

for k = 1:numel(cases)
    params = cases(k).params;
    result = lithography_run_physics(params);
    info = lithography_artifact_warnings(params, result);
    [pass, summary, contrast] = evaluateCase(cases(k), result, info);

    caseReports(k).name = cases(k).name;
    caseReports(k).kind = cases(k).kind;
    caseReports(k).pass = pass;
    caseReports(k).pupilError = result.pupilConsistencyError;
    caseReports(k).imageContrast = contrast;
    caseReports(k).messages = info.messages;
    caseReports(k).summary = summary;
end

report = struct();
report.cases = caseReports;
report.pass = all([caseReports.pass]);
report.passCount = nnz([caseReports.pass]);
report.totalCount = numel(caseReports);

if displayReport
    if report.pass
        fprintf('Validation passed: %d/%d benchmark cases.\n', report.passCount, report.totalCount);
    else
        fprintf('Validation failed: %d/%d benchmark cases.\n', report.passCount, report.totalCount);
    end
    for k = 1:numel(caseReports)
        status = 'PASS';
        if ~caseReports(k).pass
            status = 'FAIL';
        end
        fprintf('  [%s] %s | pupil err %.4f | contrast %.3f | %s\n', ...
            status, caseReports(k).name, caseReports(k).pupilError, ...
            caseReports(k).imageContrast, caseReports(k).summary);
    end
end
end

function cases = validationCases()
defaults = lithography_default_params();
presets = lithography_preset_library();
cases = struct('name', {}, 'kind', {}, 'params', {});

for k = 1:numel(presets)
    if isempty(presets(k).params)
        continue;
    end
    cases(end + 1) = struct( ... %#ok<AGROW>
        'name', presets(k).name, ...
        'kind', presetKind(presets(k).name), ...
        'params', presets(k).params);
end

p = defaults;
p.sourceType = 'Annular';
p.sourceOuter = 0.80;
p.sourceInner = 0.50;
p.maskType = 'Circular Aperture';
p.maskSizeUm = 6.0;
p.lensType = 'Circular';
p.projNA = 0.75;
cases(end + 1) = struct( ...
    'name', 'Open annular pupil image', ...
    'kind', 'annular-pupil', ...
    'params', p);

p = defaults;
p.sourceType = 'Circular';
p.sourceOuter = 0.30;
p.maskType = 'Circular Aperture';
p.maskSizeUm = 6.0;
p.lensType = 'Circular';
p.projNA = 0.75;
cases(end + 1) = struct( ...
    'name', 'Open circular pupil image', ...
    'kind', 'disk-pupil', ...
    'params', p);

p = defaults;
p.sourceType = 'Dipole Y';
p.sourceOuter = 0.12;
p.quadSeparation = 0.62;
p.maskType = '1D Grating';
p.maskSizeUm = 2.0;
p.gratingPitchUm = 0.30;
p.gratingDuty = 0.50;
p.lensType = 'Circular';
p.projNA = 0.75;
cases(end + 1) = struct( ...
    'name', 'Dipole Y lines', ...
    'kind', 'dipole-y', ...
    'params', p);
end

function kind = presetKind(name)
switch name
    case 'Conv sigma 0.30'
        kind = 'disk-pupil';
    case {'Dense conv sigma 0.85', 'Dense annular 0.8/0.5', 'Dense annular NA 0.63'}
        kind = 'dense-lines';
    case 'Dipole X lines'
        kind = 'dipole-x';
    case 'Quadrupole 2D'
        kind = 'quadrupole';
    otherwise
        kind = 'generic';
end
end

function [pass, summary, contrast] = evaluateCase(caseSpec, result, info)
checks = {};
passFlags = [];
contrast = lineContrast(result.image);

passFlags(end + 1) = all(isfinite(result.image(:))) && max(result.image(:)) > 0; %#ok<AGROW>
checks{end + 1} = 'finite image'; %#ok<AGROW>

passFlags(end + 1) = all(isfinite(result.pupil(:))) && max(result.pupil(:)) > 0; %#ok<AGROW>
checks{end + 1} = 'finite pupil'; %#ok<AGROW>

errorLimit = 0.18;
if contains(lower(caseSpec.name), 'annular') || contains(lower(caseSpec.name), 'conv sigma') || contains(lower(caseSpec.name), 'dense')
    errorLimit = 0.12;
end
passFlags(end + 1) = result.pupilConsistencyError <= errorLimit; %#ok<AGROW>
checks{end + 1} = sprintf('pupil err <= %.2f', errorLimit); %#ok<AGROW>

hasGridClip = any(contains(info.messages, 'grid clip'));
passFlags(end + 1) = ~hasGridClip; %#ok<AGROW>
checks{end + 1} = 'no grid clip'; %#ok<AGROW>

switch caseSpec.kind
    case 'disk-pupil'
        passFlags(end + 1) = centerIntensity(result.pupil) > 0.60; %#ok<AGROW>
        checks{end + 1} = 'bright pupil center'; %#ok<AGROW>
        passFlags(end + 1) = axialCircularityError(result.pupil) < 0.08; %#ok<AGROW>
        checks{end + 1} = 'pupil roundness'; %#ok<AGROW>

    case 'annular-pupil'
        passFlags(end + 1) = centerIntensity(result.pupil) < 0.25; %#ok<AGROW>
        checks{end + 1} = 'dark pupil center'; %#ok<AGROW>
        passFlags(end + 1) = ringPeak(result.pupil) > 0.75; %#ok<AGROW>
        checks{end + 1} = 'bright annular ring'; %#ok<AGROW>

    case 'dense-lines'
        passFlags(end + 1) = contrast > 0.10; %#ok<AGROW>
        checks{end + 1} = 'line contrast'; %#ok<AGROW>

    case 'dipole-x'
        [xPeak, yPeak, ctr] = directionalSourceMetrics(result.source);
        passFlags(end + 1) = ctr < 0.25; %#ok<AGROW>
        checks{end + 1} = 'dark source center'; %#ok<AGROW>
        passFlags(end + 1) = xPeak > 0.55 && xPeak > 1.20 * yPeak; %#ok<AGROW>
        checks{end + 1} = 'x dipole orientation'; %#ok<AGROW>

    case 'dipole-y'
        [xPeak, yPeak, ctr] = directionalSourceMetrics(result.source);
        passFlags(end + 1) = ctr < 0.25; %#ok<AGROW>
        checks{end + 1} = 'dark source center'; %#ok<AGROW>
        passFlags(end + 1) = yPeak > 0.55 && yPeak > 1.20 * xPeak; %#ok<AGROW>
        checks{end + 1} = 'y dipole orientation'; %#ok<AGROW>

    case 'quadrupole'
        passFlags(end + 1) = centerIntensity(result.source) < 0.25; %#ok<AGROW>
        checks{end + 1} = 'dark source center'; %#ok<AGROW>
        passFlags(end + 1) = rotationDifference(result.source) < 0.12; %#ok<AGROW>
        checks{end + 1} = 'four-fold source symmetry'; %#ok<AGROW>
end

pass = all(passFlags);
summary = shortSummary(checks, passFlags);
end

function diffValue = rotationDifference(data)
rot90Data = rot90(data, 1);
rot180Data = rot90(data, 2);
rot90Diff = norm(data(:) - rot90Data(:)) / max(norm(data(:)), eps);
rot180Diff = norm(data(:) - rot180Data(:)) / max(norm(data(:)), eps);
diffValue = max(rot90Diff, rot180Diff);
end

function value = centerIntensity(data)
center = ceil(size(data, 1) / 2);
value = data(center, center);
end

function value = ringPeak(data)
center = ceil(size(data, 1) / 2);
row = data(center, :);
value = max(row);
end

function contrast = lineContrast(imageData)
center = ceil(size(imageData, 1) / 2);
profile = imageData(center, :);
contrast = (max(profile) - min(profile)) / max(max(profile) + min(profile), eps);
end

function [xPeak, yPeak, ctr] = directionalSourceMetrics(source)
center = ceil(size(source, 1) / 2);
xPeak = max(source(center, :));
yPeak = max(source(:, center));
ctr = source(center, center);
end

function err = axialCircularityError(data)
center = ceil(size(data, 1) / 2);
rowProfile = data(center, center:end);
colProfile = data(center:end, center);
rowIdx = find(rowProfile <= 0.5, 1, 'first');
colIdx = find(colProfile <= 0.5, 1, 'first');
if isempty(rowIdx)
    rowIdx = numel(rowProfile);
end
if isempty(colIdx)
    colIdx = numel(colProfile);
end
err = abs(rowIdx - colIdx) / max([rowIdx, colIdx, 1]);
end

function summary = shortSummary(labels, passFlags)
failed = labels(~passFlags);
if isempty(failed)
    summary = 'all checks passed';
else
    summary = strjoin(failed, ', ');
end
end
