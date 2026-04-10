function report = lithography_physicality_report(displayReport)
if nargin < 1
    displayReport = true;
end

benchmarkReport = lithography_validation_report(false);
convergence = convergenceChecks();
intermediateXY = lithography_intermediate_xy_physicality_test(false);
fullPath = lithography_full_path_wave_test(false);

report = struct();
report.benchmarks = benchmarkReport;
report.convergence = convergence;
report.intermediateXY = intermediateXY;
report.fullPath = fullPath;
report.pass = benchmarkReport.pass && all([convergence.pass]) && intermediateXY.pass && fullPath.pass;

if displayReport
    fprintf('Physicality report\n');
    fprintf('  Benchmarks: %d/%d passed\n', benchmarkReport.passCount, benchmarkReport.totalCount);
    fprintf('  Convergence: %d/%d passed\n', nnz([convergence.pass]), numel(convergence));
    fprintf('  Pre-lens XY symmetry: %s\n', ternary(intermediateXY.pass, 'passed', 'failed'));
    fprintf('  Full projection path continuity: %s\n', ternary(fullPath.pass, 'passed', 'failed'));
    for k = 1:numel(convergence)
        status = 'PASS';
        if ~convergence(k).pass
            status = 'FAIL';
        end
        fprintf('    [%s] %s | image %.4f | pupil %.4f | %s\n', ...
            status, convergence(k).name, convergence(k).imageError, ...
            convergence(k).pupilError, convergence(k).summary);
    end
    fprintf('  Most physical: main image, pupil/image slices, full XY beam path\n');
    fprintf('  Approx: top sketch and YZ\n');
end
end

function out = ternary(condition, trueText, falseText)
if condition
    out = trueText;
else
    out = falseText;
end
end

function checks = convergenceChecks()
cases = representativeCases();
checks = repmat(struct( ...
    'name', '', ...
    'pass', false, ...
    'imageError', nan, ...
    'pupilError', nan, ...
    'summary', ''), numel(cases), 1);

for k = 1:numel(cases)
    coarseParams = cases(k).params;
    fineParams = cases(k).params;
    fineParams.gridSize = 384;
    fineParams.sourceGridSize = 141;
    fineParams.maxSourceSamples = max(1225, coarseParams.maxSourceSamples);

    coarse = lithography_run_physics(coarseParams);
    fine = lithography_run_physics(fineParams);

    imageError = resizedDifference(coarse.imageRaw, fine.imageRaw);
    pupilError = resizedDifference(coarse.pupilRaw, fine.pupilRaw);

    pass = imageError <= 0.08 && pupilError <= 0.08;
    summary = 'grid/source convergence within 8%';
    if ~pass
        summary = 'grid/source convergence worse than 8%';
    end

    checks(k).name = cases(k).name;
    checks(k).pass = pass;
    checks(k).imageError = imageError;
    checks(k).pupilError = pupilError;
    checks(k).summary = summary;
end
end

function cases = representativeCases()
defaults = lithography_default_params();
cases = struct('name', {}, 'params', {});

p = defaults;
p.sourceType = 'Circular';
p.sourceOuter = 0.30;
p.maskType = '1D Grating';
p.maskSizeUm = 2.0;
p.gratingPitchUm = 0.80;
p.gratingDuty = 0.50;
p.lensType = 'Circular';
p.projNA = 0.75;
cases(end + 1) = struct('name', 'Conventional dense lines', 'params', p); %#ok<AGROW>

p = defaults;
p.sourceType = 'Annular';
p.sourceOuter = 0.80;
p.sourceInner = 0.50;
p.maskType = '1D Grating';
p.maskSizeUm = 2.0;
p.gratingPitchUm = 0.80;
p.gratingDuty = 0.50;
p.lensType = 'Circular';
p.projNA = 0.75;
cases(end + 1) = struct('name', 'Annular dense lines', 'params', p); %#ok<AGROW>

p = defaults;
p.sourceType = 'Annular';
p.sourceOuter = 0.80;
p.sourceInner = 0.50;
p.maskType = 'Circular Aperture';
p.maskSizeUm = 6.0;
p.lensType = 'Circular';
p.projNA = 0.75;
cases(end + 1) = struct('name', 'Open annular pupil image', 'params', p); %#ok<AGROW>
end

function err = resizedDifference(dataA, dataB)
normA = dataA / max(max(dataA(:)), eps);
normB = dataB / max(max(dataB(:)), eps);
normB = resizeLike(normB, size(normA));
err = norm(normA(:) - normB(:)) / max(norm(normA(:)), eps);
end

function dataOut = resizeLike(dataIn, targetSize)
if isequal(size(dataIn), targetSize)
    dataOut = dataIn;
    return;
end

sourceAxisX = linspace(-1, 1, size(dataIn, 2));
sourceAxisY = linspace(-1, 1, size(dataIn, 1));
targetAxisX = linspace(-1, 1, targetSize(2));
targetAxisY = linspace(-1, 1, targetSize(1));
[Xq, Yq] = meshgrid(targetAxisX, targetAxisY);
dataOut = interp2(sourceAxisX, sourceAxisY, dataIn, Xq, Yq, 'linear', 0);
end
