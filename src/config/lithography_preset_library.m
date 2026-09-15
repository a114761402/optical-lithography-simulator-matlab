function presets = lithography_preset_library()
defaults = lithography_reference_params(); % Keep historical examples reproducible.

presets = struct('name', {}, 'description', {}, 'params', {}, 'isLiteratureGuided', {});

presets(end + 1) = struct( ...
    'name', 'Custom', ...
    'description', 'Keeps the current control values.', ...
    'params', [], ...
    'isLiteratureGuided', false);

presets(end+1)=struct('name','Lab i-line 4x (default)',...
    'description','365 nm low-NA laboratory 4f example. A 60 um local pattern on a 50.8 mm plate; not a full-plate wave calculation.',...
    'params',lithography_default_params(),'isLiteratureGuided',false);
p = defaults;
p.sourceType = 'Circular';
p.sourceOuter = 0.30;
p.maskType = 'Circular Aperture';
p.maskSizeUm = 6.0;
p.lensType = 'Circular';
p.projNA = 0.25;
presets(end + 1) = struct( ...
    'name', 'Conv sigma 0.30', ...
    'description', 'Conventional illumination example; inspect the circular aperture image and structured pupil intensity.', ...
    'params', p, ...
    'isLiteratureGuided', false);

p = defaults;
p.sourceType = 'Circular';
p.sourceOuter = 0.85;
p.maskType = '1D Grating';
p.maskSizeUm = 6.0;
p.gratingPitchUm = 1.28;
p.gratingDuty = 0.50;
p.lensType = 'Circular';
p.projNA = 0.25;
presets(end + 1) = struct( ...
    'name', 'Dense conv sigma 0.85', ...
    'description', 'Illustrative dense line/space baseline. Pitch is mask-side; compare at matched pitch, NA and exposure.', ...
    'params', p, ...
    'isLiteratureGuided', false);

p = defaults;
p.sourceType = 'Annular';
p.sourceOuter = 0.80;
p.sourceInner = 0.50;
p.maskType = '1D Grating';
p.maskSizeUm = 6.0;
p.gratingPitchUm = 1.20;
p.gratingDuty = 0.50;
p.lensType = 'Circular';
p.projNA = 0.25;
presets(end + 1) = struct( ...
    'name', 'Dense annular 0.8/0.5', ...
    'description', 'Annular illumination example. Contrast depends on pitch, NA and source geometry; improvement is not guaranteed.', ...
    'params', p, ...
    'isLiteratureGuided', false);

p = defaults;
p.sourceType = 'Annular';
p.sourceOuter = 0.80;
p.sourceInner = 0.50;
p.maskType = '1D Grating';
p.maskSizeUm = 6.0;
p.gratingPitchUm = 1.04;
p.gratingDuty = 0.50;
p.lensType = 'Circular';
p.projNA = 0.25;
presets(end + 1) = struct( ...
    'name', 'Dense annular variant', ...
    'description', 'Alternative annular pitch example within the low-NA model.', ...
    'params', p, ...
    'isLiteratureGuided', false);

p = defaults;
p.sourceType = 'Dipole X';
p.sourceOuter = 0.12;
p.quadSeparation = 0.62;
p.maskType = '1D Grating';
p.maskSizeUm = 6.0;
p.gratingPitchUm = 1.20;
p.gratingDuty = 0.50;
p.lensType = 'Circular';
p.projNA = 0.25;
presets(end + 1) = struct( ...
    'name', 'Dipole X lines', ...
    'description', 'Constructed sanity case based on standard dipole off-axis practice. Compare line orientations under X-directed off-axis illumination.', ...
    'params', p, ...
    'isLiteratureGuided', false);

p = defaults;
p.sourceType = 'Quadrupole';
p.quadSeparation = 0.62;
p.maskType = '2D Grating';
p.maskSizeUm = 6.0;
p.gratingPitchUm = 1.36;
p.gratingDuty = 0.50;
p.lensType = 'Circular';
p.projNA = 0.25;
presets(end + 1) = struct( ...
    'name', 'Quadrupole 2D', ...
    'description', 'Constructed sanity case for 2D periodic features. Useful to verify that the pupil and image respond symmetrically in four directions.', ...
    'params', p, ...
    'isLiteratureGuided', false);
end
