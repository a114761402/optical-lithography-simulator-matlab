function report = lithography_full_path_wave_test(displayReport)
if nargin < 1
    displayReport = true;
end

showcases = lithography_showcase_library();
idx = find(strcmp({showcases.name}, 'Near-field square @0.1 mm'), 1);
assert(~isempty(idx), 'Missing near-field square showcase.');

params = showcases(idx).params;
params.gridSize = 96;
params.sourceGridSize = 41;
params.maxSourceSamples = 121;

result = lithography_run_physics(params);
geom = lithography_projection_geometry(params, result.projectionRelay);

zValues = [ ...
    geom.zField + 0.1, ...
    geom.zProjection1 - 0.1, ...
    geom.zProjection1 + 0.1, ...
    geom.zPupil - 0.1, ...
    geom.zPupil + 0.1, ...
    geom.zProjection2 - 0.1, ...
    geom.zProjection2 + 0.1, ...
    geom.zImage - 0.1, ...
    geom.zImage + 0.1];

slices = cell(size(zValues));
for k = 1:numel(zValues)
    slices{k} = lithography_compute_xy_slice(params, result, zValues(k));
end

modePass = all(cellfun(@(s) strcmp(s.mode, 'Wave'), slices));
lens1PeakRatio = max(slices{3}.rawIntensity(:)) / max(max(slices{2}.rawIntensity(:)), eps);
lens2PeakRatio = max(slices{7}.rawIntensity(:)) / max(max(slices{6}.rawIntensity(:)), eps);
imagePeakRatio = max(slices{9}.rawIntensity(:)) / max(max(slices{8}.rawIntensity(:)), eps);

exactImage = lithography_compute_xy_slice(params, result, geom.zImage);
beforeImage = slices{end - 1};
afterImage = slices{end};
imageCorrBefore = corr(exactImage.intensity(:), beforeImage.intensity(:));
imageCorrAfter = corr(exactImage.intensity(:), afterImage.intensity(:));

pupilExact = lithography_compute_xy_slice(params, result, geom.zPupil);
pupilPlus001 = lithography_compute_xy_slice(params, result, geom.zPupil + 0.001);
pupilPlus005 = lithography_compute_xy_slice(params, result, geom.zPupil + 0.05);
pupilCorr001 = corr(pupilExact.intensity(:), pupilPlus001.intensity(:));
pupilCorr005 = corr(pupilExact.intensity(:), pupilPlus005.intensity(:));

pupilBefore = slices{4};
pupilAfter = slices{5};
pupilNormCorr = corr(pupilBefore.intensity(:), pupilAfter.intensity(:));

report = struct();
report.pass = modePass && ...
    all(isfinite([lens1PeakRatio, lens2PeakRatio, imagePeakRatio, pupilNormCorr, imageCorrBefore, imageCorrAfter, pupilCorr001, pupilCorr005])) && ...
    lens1PeakRatio > 0.05 && lens1PeakRatio < 20 && ...
    lens2PeakRatio > 0.05 && lens2PeakRatio < 20 && ...
    imagePeakRatio > 0.05 && imagePeakRatio < 20 && ...
    pupilCorr001 > 0.90 && pupilCorr005 > 0.50 && ...
    imageCorrBefore > 0.85 && imageCorrAfter > 0.85;
report.modePass = modePass;
report.peakRatios = [lens1PeakRatio, lens2PeakRatio, imagePeakRatio];
report.pupilNormCorr = pupilNormCorr;
report.pupilCorr001 = pupilCorr001;
report.pupilCorr005 = pupilCorr005;
report.imageCorrBefore = imageCorrBefore;
report.imageCorrAfter = imageCorrAfter;
report.zValues = zValues;

if displayReport
    if report.pass
        fprintf('Full-path wave test passed.\n');
    else
        fprintf('Full-path wave test failed.\n');
    end
    fprintf('  All in-between slices use Wave mode: %d\n', report.modePass);
    fprintf('  Lens/image peak ratios: %s\n', sprintf('%.3g ', report.peakRatios));
    fprintf('  Pupil-side normalized correlation: %.4f\n', report.pupilNormCorr);
    fprintf('  Pupil continuity at +0.001 mm: %.4f\n', report.pupilCorr001);
    fprintf('  Pupil continuity at +0.05 mm: %.4f\n', report.pupilCorr005);
    fprintf('  Image correlation at zImage-0.1 mm: %.4f\n', report.imageCorrBefore);
    fprintf('  Image correlation at zImage+0.1 mm: %.4f\n', report.imageCorrAfter);
end
end
