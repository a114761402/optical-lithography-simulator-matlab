function presets = lithography_preset_library()
defaults = lithography_default_params();

presets = struct('name', {}, 'description', {}, 'params', {}, 'isLiteratureGuided', {});

presets(end + 1) = struct( ...
    'name', 'Custom', ...
    'description', 'Keeps the current control values.', ...
    'params', [], ...
    'isLiteratureGuided', false);

p = defaults;
p.sourceType = 'Circular';
p.sourceOuter = 0.30;
p.maskType = 'Circular Aperture';
p.maskSizeUm = 2.0;
p.lensType = 'Circular';
p.projNA = 0.60;
presets(end + 1) = struct( ...
    'name', 'Conv sigma 0.30', ...
    'description', 'Literature-guided conventional illumination. The pupil should stay a filled disk and an isolated circular mask should image as a circular spot.', ...
    'params', p, ...
    'isLiteratureGuided', true);

p = defaults;
p.sourceType = 'Circular';
p.sourceOuter = 0.85;
p.maskType = '1D Grating';
p.maskSizeUm = 2.0;
p.gratingPitchUm = 0.32;
p.gratingDuty = 0.50;
p.lensType = 'Circular';
p.projNA = 0.60;
presets(end + 1) = struct( ...
    'name', 'Dense conv sigma 0.85', ...
    'description', 'Literature-guided dense line/space baseline similar to older 193 nm scan-tool settings. Use this as the conventional reference case.', ...
    'params', p, ...
    'isLiteratureGuided', true);

p = defaults;
p.sourceType = 'Annular';
p.sourceOuter = 0.80;
p.sourceInner = 0.50;
p.maskType = '1D Grating';
p.maskSizeUm = 2.0;
p.gratingPitchUm = 0.30;
p.gratingDuty = 0.50;
p.lensType = 'Circular';
p.projNA = 0.58;
presets(end + 1) = struct( ...
    'name', 'Dense annular 0.8/0.5', ...
    'description', 'Literature-guided annular off-axis illumination used for dense lines. Expect stronger line contrast than the conventional dense-line reference.', ...
    'params', p, ...
    'isLiteratureGuided', true);

p = defaults;
p.sourceType = 'Annular';
p.sourceOuter = 0.80;
p.sourceInner = 0.50;
p.maskType = '1D Grating';
p.maskSizeUm = 2.0;
p.gratingPitchUm = 0.26;
p.gratingDuty = 0.50;
p.lensType = 'Circular';
p.projNA = 0.63;
presets(end + 1) = struct( ...
    'name', 'Dense annular NA 0.63', ...
    'description', 'Literature-guided higher-NA annular dense-line case. The line image should remain line-like while contrast improves versus lower-NA settings.', ...
    'params', p, ...
    'isLiteratureGuided', true);

p = defaults;
p.sourceType = 'Dipole X';
p.sourceOuter = 0.12;
p.quadSeparation = 0.62;
p.maskType = '1D Grating';
p.maskSizeUm = 2.0;
p.gratingPitchUm = 0.30;
p.gratingDuty = 0.50;
p.lensType = 'Circular';
p.projNA = 0.75;
presets(end + 1) = struct( ...
    'name', 'Dipole X lines', ...
    'description', 'Constructed sanity case based on standard dipole off-axis practice. Useful to check that X-directed off-axis source energy enhances one line-space orientation.', ...
    'params', p, ...
    'isLiteratureGuided', false);

p = defaults;
p.sourceType = 'Quadrupole';
p.quadSeparation = 0.62;
p.maskType = '2D Grating';
p.maskSizeUm = 2.0;
p.gratingPitchUm = 0.34;
p.gratingDuty = 0.50;
p.lensType = 'Circular';
p.projNA = 0.75;
presets(end + 1) = struct( ...
    'name', 'Quadrupole 2D', ...
    'description', 'Constructed sanity case for 2D periodic features. Useful to verify that the pupil and image respond symmetrically in four directions.', ...
    'params', p, ...
    'isLiteratureGuided', false);
end
