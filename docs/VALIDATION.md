# Validation record — connected full-path model

[README](../README.md) · [How to run the tests](DEVELOPMENT.md) · [Model assumptions](FULL_PATH_MODEL.md)

## Folder organization — 2026-09-15

After grouping the files, MATLAB R2026a passed root-GUI startup with a fresh path, all 128 independent regression checks, and a scripted image/XY agreement check from a different current folder. A clean copy in a directory containing spaces also passed helper lookup and exported its documentation figure to that copy's `docs/assets/` folder.

Content hashes confirmed that 65 moved MATLAB helpers and all moved local output files were unchanged. The export utility's destination was adjusted for its new `tools/` location, and the root GUI now calls `lithography_setup`. Relative documentation links were checked after relocation. Run `lithography_setup` before direct helper/test commands.

## Unreleased UI refinement — 2026-09-14

MATLAB R2026a checks for the requested overview/window cleanup:

- `snapshotstest`: no overview colour bars, two lens-shaped icons, independent XY/XZ/plate/details windows, per-window colour controls, unchanged earlier data, preservation after invalid input, and reuse only after explicit close passed.
- `layouttest`: all 132 size/shape/page checks passed; display changes retained the same raw optical results.
- `lithography_xy_display_test`: four controls, 20 numerical corners and 16 mask/plane cases passed, with unchanged raw data.
- `previewuitest`: shared z alignment at three window sizes, 101 nonzero relay columns, three raw-data-preserving scales, dark views and seven pupil shapes passed; only the YZ colour bar remains in the main window.
- `uitest`: 20 explicit-close/reuse cycles and invalid-input recovery passed, also with an unrelated pre-existing figure that remained untouched.
- The exported GUI was visually inspected. The four overview bars are absent, lens labels remain readable, and a stale error heading after recovery was found, corrected and retested.

Only rendering and auxiliary-window behaviour changed; the optical operators and default parameters are unchanged. These local changes are separate from the published v0.2.0 record below.

## Public release verification — v0.2.0

The following were rerun on 2026-09-14 in MATLAB R2026a on macOS while preparing the public documentation:

| Check | Observed result |
|---|---|
| Actual startup / practical-default suite | Passed; three image lines at 5 µm pitch, 28 mask/plane cases, two dark cases and three rejected unsupported combinations |
| Startup raw-intensity refinement | 0.01126% source quadrature; 0.1833% padding; 0.01189% pixel grid, relative L2 on matching image ROI |
| Independent diffraction/relay references | 128/128 passed |
| Independent source/condenser references | 125/125 passed |
| XY display regression | Four controls, 20 numerical corners and 16 mask/plane cases passed; weak historical slice reproduced at −78.15 dB relative to its shared reference |
| Physical YZ mesh | 237 planes; off-axis coordinates, two-sided element samples, image-marker invariance/continuity, nine geometry corners and dark input passed |
| Illumination corners | 98/98 passed |
| Guarded settings | 186/186 passed; of 2,000 reproducible point-source combinations, 148 were admitted and propagated, 1,852 explicitly rejected |
| Historical refinement suite | 9/9 passed after restoring explicit historical fixtures; results reproduce the refinement table below |
| Qualitative near-mask shapes | 3/3 passed with base-MATLAB correlation; supplementary, not independent physical validation |
| Accepted-limit cases | 137/137 passed across extreme combinations, post-mask positions and blocked-condenser preview |
| GUI recovery | Invalid input cleared results; recovery and 20 hide/reuse cycles passed |
| GUI layout | 132 size/shape/page combinations passed, including named planes, focal-length conversion and display-only caching |
| Documentation image | Regenerated from the actual startup and visually checked; a dark-theme text contrast problem was corrected |

MATLAB dependency analysis of both the app entry point and all project MATLAB files reported MATLAB only. A reference-suite maintenance error was found during documentation review: `lithography_physicality_report` still inherited the new large-pattern startup although its refinement cases were designed for the historical settings. It now explicitly uses `lithography_reference_params`. The separate practical-default suite continues to test the actual startup. The qualitative shape test uses base-MATLAB `corrcoef`, and the practical test no longer writes a hard-coded temporary file.

These are numerical/GUI checks, not experimental measurements. Intentional invalid-input warnings are expected. XY export warnings concern omitted UI controls in local test artifacts, not missing computed image data. Native MATLAB/macOS crash elimination is still not proven.

## 2026-09-14: practical laboratory startup

The startup is now 365 nm, image NA 0.15, 4x reduction, 60 um isolated pattern in an 80 um window, with a 50.8 mm plate outline for context. Other transmitted features outside the local window, substrate effects and plate-edge diffraction are excluded. The ideal relay has f1=100 mm, f2=25 mm and mask-L1/L1-L2/L2-image distances 100/125/25 mm. The image is selected at z=450 mm.

Executed in MATLAB R2026a:

- Independent 4f ray matrix gives magnification -0.25 and B=0; XY and overview raw image arrays agree exactly.
- The initial 16 um-pitch candidate left two clipped edge fragments in its 60 um mask envelope. Visual inspection caught this; the final default uses 20 um pitch and explicitly tests that there are exactly three complete mask bars.
- Final default image resolves three bright lines: measured centreline pitch **5 um**, matching nominal 5 um; inter-line intensities about **0.01225** of the local peak.
- Final default image convergence on matching physical ROI, comparing raw intensity in relative L2 norm: source quadrature 625->1225 **0.01126%**, padding 2->3 **0.1833%**, mask grid 512->768 **0.01189%**. Finer-grid probes are script-only; GUI memory/sampling guards were not relaxed.
- The 25-mode preview versus full 625-budget image gives **0.5010%** relative intensity difference in the default image ROI. This is an image-plane check, not a convergence guarantee at every preview z.
- 28 additional mask/plane cases (seven shapes, point illumination); two true-dark cases; rejection of three unsupported full-plate/geometry/source combinations passed.
- Independent diffraction/relay reference regression **128/128** and Gaussian/source/condenser reference tests **125/125** passed. These reference fixtures retain the historical 193-nm setup through `lithography_reference_params`; they are distinct from the new-default convergence tests above.
- Updated GUI tests cover focal-length input conversion, named-image tracking as focal length changes, preserved custom-z precision, and 20 hide/reuse cycles. Layout checks cover 132 size/shape/page combinations. The new plate/local-pattern view is included in GUI construction checks.
- All built-in preset/showcase settings passed admission. With the new local 60 um pattern, simply switching to the broad Quadrupole source is explicitly rejected by the source-quadrature guard; its dedicated small-pattern preset remains available. Other source shapes passed the admission check at their new default controls. This does not replace full propagation/convergence testing for each source configuration.

These tests establish bounded numerical consistency, not measured agreement with a manufactured lens or a full industrial mask. Reproduce the new-startup checks with `lithography_practical_defaults_test`.

## Historical 2026-09-13 reference results

Tests ran in MATLAB R2026a. This record supersedes the earlier source-side geometrical-schematic version. These results establish numerical consistency for the tested model and cases, not universal experimental accuracy.

## Completed numerical tests

| Suite | Result | Scope |
|---|---:|---|
| Independent relay/diffraction references | 128/128 | Direct RS and Collins quadrature, Gaussian/Airy references, power and geometry; explicitly legacy angular-input mathematical benchmarks |
| New full-path illumination | 125/125 | Independent complex Fresnel calculation, Gaussian width/power, condenser transmission, source integration, all eight source types, actual mask coupling, dark conditions |
| New illumination corners | 98/98 | 50/2000 nm; divergence 0.02/0.15; off-axis sources; narrow Gaussian aperture; source/lens/near-mask planes; sampling rejection |
| Guarded settings | 185/185 | Invalid numeric input, source shapes, all seven masks × seven pupils, presets, physical display checks |
| Accepted extreme combinations | 137/137 | Wavelengths, NA/reductions and defocus signs; nine post-mask positions; blocked-condenser YZ |
| Additional script guards | 6/6 | Unknown shape/normalization choices and bypassed source-grid/sample-count planning rejected |
| Numerical refinements | 9/9 | Pixel spacing, padded window and source quadrature; both shape-normalized and absolute intensities compared |
| Qualitative near-mask shapes | 3/3 | Correlations 0.9210, 0.8895, 0.7994; supplementary shape checks, not independent physical proof |

The settings suite also drew 2,000 reproducible combinations: **148 were admitted and actually propagated; 1,852 were explicitly rejected**. These random cases use point illumination; extended-source coverage is separate. All 14 non-custom built-in presets/showcases passed admission checks.

GUI checks cover invalid-input rejection, stale-result clearing, recovery and 20 close-callback/hide/reuse cycles. The native macOS close-button crash was not reproduced or proven fixed by these callback tests.

## Refinement results

Relative changes on matching physical axes. Each entry is image / pupil. These are differences between two numerical resolutions, not errors against a real instrument. The threshold was 5% for **both** shape and raw intensity; all passed.

| Source / refinement | Shape change | Absolute-intensity change |
|---|---:|---:|
| Point / grid 256→384 | 0.142% / 0.340% | 1.210% / 1.088% |
| Point / doubled padding | 0.467% / 0% | 0.709% / 0% |
| Point / source 625→2500 | 0% / 0% | 0% / 0% |
| Circular / grid 256→384 | 0.256% / 0.191% | 1.293% / 1.123% |
| Circular / doubled padding | 0.398% / 0% | 0.771% / 0% |
| Circular / source 625→2500 | 0.002% / 0.004% | 0.067% / 0.066% |
| Annular / grid 256→384 | 0.006% / 0.003% | 0.007% / 0.008% |
| Annular / doubled padding | 0.293% / 0% | 0.377% / 0% |
| Annular / source 625→2500 | 0.061% / 0.198% | 0.073% / 0.212% |

## Problems found and corrected

- The old front-half picture did not drive the mask field. The propagated complex Gaussian-mode field now does; condenser attenuation is retained through the detector calculation.
- Continuous source-cell integration replaces sparse plotted emitters in source-side XY. An independent dense source sum agrees within the test tolerance; circle interiors do not acquire a checkerboard.
- Off-axis micrometre point-source waists could disappear on a millimetre-wide display. XY now uses separately centred physical x/y axes; corner tests check peak and captured power.
- A circular extended source with Gaussian condenser radius 0.01 produced a **274.51%** quadrature discrepancy at the mask. The new preflight rejects this combination before expensive relay calculation. The same aperture with a single on-axis Gaussian emitter passes.
- Gaussian tail integration uses complementary error functions to avoid subtracting numbers rounded to one.
- Pupil XY zooms to the physical pupil instead of showing a tiny spot inside the entire padded Fourier window.
- At that revision the relay control was labelled "2*f1", and the top sketch displayed the actual pupil-to-image distance (then 21.25 mm), not the legacy 85 mm relay parameter. The current GUI instead displays f1 directly; see the 2026-09-14 section.

## Interpretation and limits

The source consists of mutually incoherent, internally coherent finite Gaussian emitters. The condenser is an ideal thin lens with **Gaussian transmission, not a hard circular aperture**. Source dimensions are mapped from normalized emitter coordinates by a stated model rule, not inferred from experimental data. See [the model contract](FULL_PATH_MODEL.md) for formulas and primary references.

Source-side XY uses an analytical paraxial Gaussian propagation integral. After-mask XY uses the coupled scalar diffraction/ideal paraxial relay. YZ now retains real transverse coordinates on a nonuniform mesh with reduced source quadrature; XZ is also a reduced-source preview. Neither replaces full-quadrature XY.

The 2% illumination preflight is a **necessary local sampling check**, not a convergence certificate for every diffracted image or arbitrary freeform source. Not all combinations inside individual parameter ranges are valid. Material/thick-mask fields, polarization, real surfaces/aberrations, hard-edge condenser diffraction and rigorous vector high-NA optics remain outside this model. Near-mask plots are cropped regions.

## Reproduce and inspect

    projectRoot = lithography_setup();
    report = lithography_full_path_wave_test(true); assert(report.pass)
    lithography_illumination_corner_tests()
    lithography_settings_tests(true)
    lithography_limit_tests()
    lithography_physicality_report(true)
    lithography_nearfield_shape_test(true)
    lithography_specular_gui('uitest')
    lithography_full_path_display_test(fullfile(projectRoot,'outputs','validation'))

`lithography_full_path_display_test` creates full-path XY/preview figures and `full-path-result.mat` in the selected output directory. Other report functions return MATLAB structures; save those explicitly if needed. Earlier local runs also saved report files, but these are not shipped or required. Figures use local scaling for shape comparison and label that choice; propagation retains raw intensities. See [the testing guide](DEVELOPMENT.md) for the complete current command list.
