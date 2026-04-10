function report = lithography_intermediate_xy_physicality_test(displayReport)
if nargin < 1
    displayReport = true;
end

cases = testCases();
reports = repmat(struct( ...
    'name', '', ...
    'zMm', [], ...
    'symmetryError', [], ...
    'squareError', [], ...
    'pass', false), numel(cases), 1);

for k = 1:numel(cases)
    params = cases(k).params;
    result = lithography_run_physics(params);
    geom = geometryForTest(params, result.projectionRelay);
    zValues = linspace(geom.zField + 6, geom.zProjection1 - 6, 3);
    errors = zeros(size(zValues));
    squareErrors = zeros(size(zValues));
    for n = 1:numel(zValues)
        slice = lithography_compute_xy_slice(params, result, zValues(n));
        errors(n) = rotationalSymmetryError(slice.intensity);
        squareErrors(n) = squareArtifactError(slice.intensity);
    end

    reports(k).name = cases(k).name;
    reports(k).zMm = zValues;
    reports(k).symmetryError = errors;
    reports(k).squareError = squareErrors;
    reports(k).pass = all(errors < 0.02);
end

report = struct();
report.cases = reports;
report.pass = all([reports.pass]);

if displayReport
    if report.pass
        fprintf('Intermediate XY physicality test passed.\n');
    else
        fprintf('Intermediate XY physicality test failed.\n');
    end
    for k = 1:numel(reports)
        status = 'PASS';
        if ~reports(k).pass
            status = 'FAIL';
        end
        fprintf('  [%s] %s | symmetry: %s | square-metric: %s\n', status, reports(k).name, ...
            sprintf('%.3f ', reports(k).symmetryError), ...
            sprintf('%.3f ', reports(k).squareError));
    end
end
end

function cases = testCases()
defaults = lithography_default_params();
cases = struct('name', {}, 'params', {});

p = defaults;
p.sourceType = 'Circular';
p.sourceOuter = 0.30;
p.maskType = 'Circular Aperture';
p.maskSizeUm = 2.0;
p.lensType = 'Circular';
cases(end + 1) = struct('name', 'Circular aperture pre-lens symmetry', 'params', p); %#ok<AGROW>

p = defaults;
p.sourceType = 'Circular';
p.sourceOuter = 0.30;
p.maskType = 'Annular Aperture';
p.maskSizeUm = 2.0;
p.maskInnerRatio = 0.45;
p.lensType = 'Circular';
cases(end + 1) = struct('name', 'Annular aperture pre-lens symmetry', 'params', p); %#ok<AGROW>
end

function geom = geometryForTest(params, projectionRelay)
geom = struct();
geom.zField = params.sourceToCondenserMm + params.condenserFocalMm;
geom.zPupil = geom.zField + params.fieldToPupilMm;
geom.projectionLensSeparation = min(max(0.22 * params.projectionFocalMm, 10), 24);
geom.zProjection1 = geom.zPupil - 0.5 * geom.projectionLensSeparation;
geom.zImage = geom.zPupil + projectionRelay.imageDistanceMm;
end

function err = rotationalSymmetryError(imageData)
N = size(imageData, 1);
center = (N + 1) / 2;
[X, Y] = meshgrid(1:N, 1:N);
R = sqrt((X - center).^2 + (Y - center).^2);
bin = round(R) + 1;
radialMean = accumarray(bin(:), imageData(:), [], @mean, 0);
radialImage = radialMean(bin);
err = norm(imageData(:) - radialImage(:)) / max(norm(radialImage(:)), eps);
end

function err = squareArtifactError(imageData)
N = size(imageData, 1);
center = ceil((N + 1) / 2);
rowProfile = imageData(center, center:end);
diagProfile = diag(imageData(center:end, center:end))';
threshold = 0.25;
rowIdx = find(rowProfile <= threshold, 1, 'first');
diagIdx = find(diagProfile <= threshold, 1, 'first');
if isempty(rowIdx)
    rowIdx = numel(rowProfile);
end
if isempty(diagIdx)
    diagIdx = numel(diagProfile);
end
err = abs(rowIdx - diagIdx) / max([rowIdx, diagIdx, 1]);
end
