# Testing and development

[README](../README.md) · [Validation record](../VALIDATION.md) · [Model](../FULL_PATH_MODEL.md)

## Environment

The release checks were run in MATLAB R2026a on macOS. Dependency analysis with `matlab.codetools.requiredFilesAndProducts('lithography_specular_gui.m')` reports MATLAB only. Other MATLAB/OS combinations remain unverified. Tests that create figures need MATLAB graphics support; run GUI suites in a separate session if you have unsaved simulator work.

Run commands from the repository root. There is no external dataset, Python package, web service or credential requirement. Numerical suites can take several minutes; GUI layout and extended sweeps add further time.

## Recommended release check

```matlab
[p,r] = lithography_practical_defaults_test();
report = lithography_full_path_wave_test(true);
assert(report.pass);
lithography_specular_gui('uitest');
lithography_specular_gui('layouttest');
lithography_xy_display_test();
lithography_preview_mesh_test();
lithography_export_documentation(p,r);
```

The practical-default test asserts results directly and optionally returns parameters and raw data. It no longer writes to a hard-coded temporary path. For numerical reporting functions, check the returned `pass` flag; do not infer success only because the function returned. Intentional invalid-input tests can emit warnings even when they pass.

### Extended checks

```matlab
report = lithography_settings_tests(true); assert(report.pass);
report = lithography_limit_tests(); assert(report.pass);
report = lithography_illumination_corner_tests(); assert(report.pass);
report = lithography_physicality_report(true); assert(report.pass);
report = lithography_nearfield_shape_test(true); assert(report.pass);
lithography_specular_gui('previewuitest');
lithography_display_test();
lithography_full_path_display_test(fullfile(pwd,'validation_artifacts'));
```

| Suite | What it checks |
|---|---|
| `lithography_practical_defaults_test` | Actual 365-nm startup: geometry, three lines, magnification, image/XY equality, three refinements, seven masks and dark/rejection cases |
| `lithography_regression_tests` | Independent RS/Collins quadrature, Gaussian/Airy references, power, magnification and numerical corners |
| `lithography_illumination_tests` | Gaussian emitters, condenser, continuous-source integral, mask coupling, source shapes and zero fields |
| `lithography_full_path_wave_test` | Runs the preceding two reference suites; does not add a third independent set |
| `lithography_illumination_corner_tests` | Extreme wavelength/divergence, off-axis source windows, narrow condenser and runtime rejection |
| `lithography_settings_tests` | Input validation, supported shapes, preset admission and reproducible sampled parameter combinations |
| `lithography_limit_tests` | Accepted extreme combinations and post-mask positions |
| `lithography_physicality_report` | Separate grid, padding and source-quadrature refinement on matching physical coordinates |
| `lithography_xy_display_test` | Four XY colour modes, unchanged raw data, faint/zero/tiny/bright signals and other masks/planes |
| `lithography_preview_mesh_test` | Physical y coordinates, refined z mesh, image-plane continuity and observation-marker invariance |
| GUI `uitest`, `layouttest`, `previewuitest` | Reusable windows, invalid-input recovery, layout, named planes, display caching, preview labels and scales |

Historical helper entry points remain available for compatibility; many now wrap shared suites. Do not add their totals to the underlying suites as if they were independent tests.

## Three distinct parameter constructors

| Constructor | Intended use |
|---|---|
| `lithography_default_params` | Current public startup and practical-default tests |
| `lithography_reference_params` | Frozen 193-nm historical presets/reference fixtures |
| `lithography_benchmark_params` | Explicit legacy angular-illumination mathematical benchmarks; bypasses GUI admission guards |

Reference tests must not change silently when the startup is adjusted. A benchmark can intentionally use a grid or NA disallowed by the GUI; passing it does not admit that setting for interactive use.

## How to validate a changed configuration

1. Start from default or a documented preset, record every change and call `lithography_check_settings` before `lithography_run_physics`.
2. Check finite, nonnegative raw intensity. Treat real zero power as a valid possibility, not a plotting failure.
3. Compare with an independent prediction: magnification, Gaussian width, grating order position, aperture diffraction or a direct quadrature calculation.
4. Refine pixel spacing, padded window and source quadrature **separately**. Compare raw intensities on the same physical coordinates, not just normalized pictures.
5. Inspect mask, pupil, image, nearby z values and propagation-method transitions. Check that cropping is not mistaken for loss of physical power.
6. Repeat with different shapes and true-dark inputs; then run display/GUI checks.

The default refinement metric is relative L2 intensity difference on a common image ROI, `norm(I_fine - I_base) / norm(I_fine)`. It is neither a maximum pointwise error nor experimental accuracy. Refinement beyond the GUI budget is confined to explicit scripted probes, not offered as a supported interactive mode. Do not disable guards merely to obtain a desired picture.

## Generate documentation figures

```matlab
lithography_export_documentation();   % Recalculate the actual startup
```

Or reuse `[p,r]` from the practical-default test. The function writes `docs/assets/default-imaging.png`, uses a light theme for legibility and contains only calculated mask/image data, not a desktop screenshot. Do not replace the public default figure with custom parameters without also updating its caption and validation record.

Check the exported image visually before committing. Generated MATLAB data, logs, test artifacts and old debugging screenshots are ignored. Only the explicitly allowed documentation PNGs are versioned. To save local results, choose a portable path, for example:

```matlab
save(fullfile(tempdir,'lithography-results.mat'),'p','r');
```

## Code map

| Area | Main files |
|---|---|
| UI and input planning | `lithography_specular_gui`, `lithography_collect_input`, `lithography_check_settings` |
| Defaults and examples | `lithography_default_params`, `lithography_reference_params`, preset/showcase libraries |
| Full result and geometry | `lithography_run_physics`, `lithography_projection_geometry` |
| Source/condenser | `lithography_gaussian_illumination`, `lithography_gaussian_mode`, `lithography_illumination_wave_slice` |
| Per-emitter relay | `lithography_coherent_fields`, `lithography_pupil_amplitude` |
| Propagation | `lithography_wave_propagate`, `lithography_lct`, `lithography_fresnel_same`, `lithography_projection_slice` |
| XY display | `lithography_compute_xy_slice`, `lithography_xy_display`, `lithography_render_xy_slice` |
| Preview and dimensions | `lithography_wave_yz_preview`, `lithography_preview_z_grid`, `lithography_render_yz_panel`, plane-size and mask-scale renderers |

One legacy parameter needs care: `projectionFocalMm = 2*f1`. The GUI displays **Lens 1 f (mm)** and converts it on input/output. `projNA` is image-side NA in air, `reduction` is positive R, and image magnification is −1/R. Mask lengths are supplied in µm, layout distances in mm, wavelength in nm; field axes and operators use metres.

## Contributing and publication

Keep physical-model, numerical and display changes distinguishable. Include a failing example or independent reference with fixes, update the relevant documentation and preserve historical fixtures. Never publish local logs or screenshots containing personal information. The current repository has no selected open-source license; clarify permission before reuse or redistribution.
