function presets = lithography_showcase_library()
defaults = lithography_reference_params(); % Fixed historical examples.

presets = struct('name', {}, 'description', {}, 'params', {});

presets(end + 1) = struct( ...
    'name', 'None', ...
    'description', 'Keeps the current settings.', ...
    'params', []);

p = defaults;
p.sourceType = 'Circular';
p.sourceOuter = 0.30;
p.maskType = 'Circular Aperture';
p.maskSizeUm = 2.0;
p.lensType = 'Circular';
p.projNA = 0.25;
presets(end + 1) = struct( ...
    'name', 'Conv sigma 0.30', ...
    'description', 'A simple textbook circular source case. Useful to inspect rotational symmetry. Pupil intensity need not be a filled disk.', ...
    'params', p);

p = defaults;
p.sourceType = 'Annular';
p.sourceOuter = 0.80;
p.sourceInner = 0.50;
p.maskType = '1D Grating';
p.maskSizeUm = 2.0;
p.gratingPitchUm = 1.20;
p.gratingDuty = 0.50;
p.lensType = 'Circular';
p.projNA = 0.25;
presets(end + 1) = struct( ...
    'name', 'Annular dense lines', ...
    'description', 'Classic off-axis annular illumination for dense lines. Compare the source, pupil intensity and image; contrast is not guaranteed.', ...
    'params', p);

p = defaults;
p.sourceType = 'Annular';
p.sourceOuter = 0.60;
p.sourceInner = 0.30;
p.maskType = 'Circular Aperture';
p.maskSizeUm = 4.0;
p.fieldSizeUm = 8.0;
p.lensType = 'Circular';
p.projNA = 0.25;
presets(end + 1) = struct( ...
    'name', 'Open annular source at pupil', ...
    'description', 'Annular source with a large circular opening. The pupil panel should visibly show an annular ring by eye.', ...
    'params', p);

p = defaults;
p.sourceType = 'Dipole X';
p.sourceOuter = 0.12;
p.quadSeparation = 0.62;
p.maskType = '1D Grating';
p.maskSizeUm = 2.0;
p.gratingPitchUm = 1.20;
p.gratingDuty = 0.50;
p.lensType = 'Circular';
p.projNA = 0.25;
presets(end + 1) = struct( ...
    'name', 'Dipole X lines', ...
    'description', 'Off-axis dipole illumination matched to one line-space orientation. Useful to see directional source shaping.', ...
    'params', p);

p = defaults;
p.sourceType = 'Quadrupole';
p.quadSeparation = 0.62;
p.maskType = '2D Grating';
p.maskSizeUm = 2.0;
p.gratingPitchUm = 1.36;
p.gratingDuty = 0.50;
p.lensType = 'Circular';
p.projNA = 0.25;
presets(end + 1) = struct( ...
    'name', 'Quadrupole 2D', ...
    'description', 'Four-lobe off-axis source for a 2D periodic pattern. Useful to verify four-fold pupil symmetry.', ...
    'params', p);

p = defaults;
p.sourceType = 'Point';
p.pointSourceU = 0.00;
p.pointSourceV = 0.00;
p.maskType = 'Square Aperture';
p.maskSizeUm = 20.0;
p.fieldSizeUm = 44.0;
p.lensType = 'Circular';
p.projNA = 0.25;
p.xySliceZMm = p.sourceToCondenserMm + p.condenserFocalMm + 0.05;
presets(end + 1) = struct( ...
    'name', 'Near-field square @0.05 mm', ...
    'description', 'Point-source near-field demo. At 0.05 mm after a large square aperture, the square stays close to the mask shape.', ...
    'params', p);

p = defaults;
p.sourceType = 'Point';
p.pointSourceU = 0.00;
p.pointSourceV = 0.00;
p.maskType = 'Square Aperture';
p.maskSizeUm = 20.0;
p.fieldSizeUm = 44.0;
p.lensType = 'Circular';
p.projNA = 0.25;
p.xySliceZMm = p.sourceToCondenserMm + p.condenserFocalMm + 0.1;
presets(end + 1) = struct( ...
    'name', 'Near-field square @0.1 mm', ...
    'description', 'Point-source near-field demo. A large square aperture stays clearly square after 0.1 mm, with only Fresnel edge ringing.', ...
    'params', p);

p = defaults;
p.sourceType = 'Point';
p.pointSourceU = 0.00;
p.pointSourceV = 0.00;
p.maskType = '1D Grating';
p.maskSizeUm = 20.0;
p.gratingPitchUm = 8.0;
p.gratingDuty = 0.50;
p.fieldSizeUm = 44.0;
p.lensType = 'Circular';
p.projNA = 0.25;
p.xySliceZMm = p.sourceToCondenserMm + p.condenserFocalMm + 0.1;
presets(end + 1) = struct( ...
    'name', 'Near-field grating @0.1 mm', ...
    'description', 'Point-source near-field grating demo. A much larger pitch keeps the bar pattern recognizable after 0.1 mm.', ...
    'params', p);
end
