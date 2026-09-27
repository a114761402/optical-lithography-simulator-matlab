# Current scope — 27 September 2026

The projection propagation remains subject to the original MATLAB tolerances. Circular/annular illumination now integrates the exact continuous source boundary instead of the old MATLAB rasterized source mask. The two old illumination screen fixtures therefore are no longer asserted to be numerically identical; their projection-pupil fields and axes still are. Separate analytic, independent polar quadrature, symmetry and integrated-power tests validate the new illumination routine. No MATLAB source was changed. The historical measurements below describe the earlier matching implementation.

# Browser / MATLAB comparison — 26 September 2026

Compared against the current local MATLAB source, including `lithography_specular_gui.m`, `lithography_open_xz.m`, `lithography_wave_yz_preview.m`, `lithography_preview_display.m`, `lithography_xy_display.m`, and `lithography_check_settings.m`.

## Addressed in this update

| Feature | Browser behavior |
|---|---|
| Oversized image | Four equal field views, capped at 220 CSS pixels on desktop; image-plane icon reduced from 110 to 64 drawing units. Physical propagation dimensions are unchanged. |
| Horizontal wave section | XZ intensity at physical y = 0, both across the whole bench and 0–200 µm after the mask. |
| Vertical wave section | YZ at physical x = 0, displayed in the last section, after the screen results. |
| Near-mask diffraction | 61 physical z planes, using the same scalar Rayleigh–Sommerfeld / angular-spectrum propagation as MATLAB. |
| Physical central cuts | Interpolation at zero on independent x/y axes, including shifted image grids and off-axis sources. |
| Brightness | Local linear and fixed XYZ linear / −120 to 0 dB log scales; raw intensities are preserved. Removed the unexplained square-root scaling. |
| Fixed XYZ reference | Source, mask-incident, pupil and nominal/defocused image peaks determine the reference; moving the observation screen does not change it. |
| Source and mask intensity | Source intensity versus emitter weights, and mask exit intensity versus opening, are selectable. |
| Local calculation window | Adjustable in the mask inspector, with a 75% mask-width guard. |
| Wave sampling | Explicit 128/256/512 mask grid selection, no hidden spatial downsampling. Matches XY source quadrature at each detail: 7×7 / 13×13 / 25×25 weighted bins. Fine startup cache uses 445 emitters for its circular source. |
| Calculation controls | Progress, cancellable workers, retained valid XY results after errors, and invalidation of wave results on optical-setting changes. |

## Still different or missing

1. **MATLAB's full reference and lecture preset libraries.** The site has four introductory experiments, not the complete libraries or their exact settings.
2. **Independent saved XY/XZ snapshot windows and per-window scales.** The browser has one current XY result and one current wave plot. Switching XZ/YZ uses the same calculation. It does not keep a collection of previous snapshots.
3. **Mechanical plate control and plate-versus-local-pattern comparison.** The browser describes a fixed illustrative 50.8 mm plate; only the local window is simulated. MATLAB can change the plate outline and open a scale comparison.
4. **129 × 129 freeform editors.** The browser uses 32 × 32 piecewise-constant painting. It has source/pupil painting but not MATLAB's editor resolution.
5. **MATLAB's complete automatic sampling and model-validity policy.** The browser validates finite inputs, FFT sizes, source-bin limits, custom patterns, mask containment, grating sampling and passed spatial frequencies. It does not yet reproduce MATLAB's 256/384/512 grid selection, automatic pupil padding, all feature-size/paraxial/defocus guards, illumination mismatch checks, or the full numerical diagnostics display. Extreme settings are not certified by the parity tests.
6. **Auto YZ refresh and MATLAB's dense adaptive z grid.** The default Fine full-path view is precomputed and loaded at startup; changed optics compute on request. Default full-path preview uses 119 sampled z positions; the near-mask plot uses 61. It uses physical z coordinates and nearest sampled columns for display. Narrow axial features can be missed; individual XY slices and finer spatial detail are available. Wave and XY source quadrature now match at each detail level; source, spatial and z convergence still require separate assessment.
7. **Independent scale selection for each overview field.** The browser shares one XY brightness selector; opening/weight views retain their own scale. MATLAB snapshot windows each have independent scale controls.

These are interface and numerical-policy differences, not evidence that the ideal scalar model describes real high-NA industrial optics. Both versions omit vector polarization, material effects and lens aberrations.

## Verification

`npm test` runs the optical and startup-cache regression suites. Fresh MATLAB R2026a output is generated by `tests/export_matlab_wave_reference.m`; original benchmarks by `tests/export_matlab_reference.m`.

- Independent direct DFT / FFT round trip and analytic Gaussian Collins propagation.
- Eight existing MATLAB parity scenarios for source, condenser, near-mask, pupil-adjacent and image planes.
- Five new MATLAB scenarios comprising **21 planes**, checking **both XZ and YZ cuts**, coordinate axes and fixed intensity references. Includes circular extended illumination, off-axis point illumination, annular pupil/defocus, 256 grids, and a 512-grid slit pupil.
- Worst relative L2 cut difference in the new fixtures: **6.61 × 10⁻¹¹**. The acceptance tolerance is 10⁻⁶; continuous-source erf approximation and floating-point ordering can differ.
- Point-source grating convergence: 128→256 centreline difference **0.255%**, 256→512 **0.064%**; corresponding integrated-intensity changes **0.247%** and **0.062%**. This is one convergence case, not a guarantee for every setting.
- Physical-origin interpolation on different x/y axes, log-floor behavior, fixed reference across screen positions, XY-versus-wave-cut consistency, closed condenser, empty custom source, and invalid inputs.

Parity fixtures use `enforceLimits=false` to compare the underlying algorithms at identical settings. They do not validate equivalence of the MATLAB input-checking policy.

Browser interaction and layout checks are recorded in `TEST_REPORT.md`.
