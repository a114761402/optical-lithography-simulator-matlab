# Changes

## Unreleased

- Removed colour bars from the four overview panels; retained XY/YZ scale bars and unchanged normalization.
- Replaced the Lens 1/2 infinity glyphs with schematic biconvex icons, retaining ideal/unbounded labels.
- New XY, XZ, plate-scale and model-details requests preserve open snapshots. Only explicitly closed windows may be reused; rejected input no longer hides a previously valid XY snapshot.
- Added focused snapshot/visual regression coverage. No optical calculation changes.

## v0.2.0 — 2026-09-14

### Connected wave model

- Propagated finite Gaussian emitters now supply the complex incident mask field; condenser and pupil losses remain in raw intensity.
- Source-side XY uses analytic source-cell integration instead of a geometrical illustration or sparse-emitter checkerboard.
- Shared scalar-diffraction and ideal-relay operators support physical-coordinate slices throughout the path.
- The image is an observation plane, not a special field reset or transmission surface.

### Practical defaults

- A 365-nm, NA 0.15, 4× laboratory example replaces the tiny unresolved startup pattern.
- Three complete 20-µm-pitch mask bars form a resolved 5-µm-pitch image; the local mask envelope is 60 µm in an 80 µm window.
- A 50.8-mm plate outline is explicitly context only, not a full-plate calculation.
- The ideal relay uses f1=100 mm, f2=25 mm and 100/125/25 mm mask–L1/L1–L2/L2–image spacings. Startup selects image z=450 mm.
- Historical presets and mathematical benchmarks retain separate parameter constructors.

### Input and display

- Coupled sampling, paraxial, geometry and memory checks reject unsupported combinations and clear stale results.
- XY now offers local/shared linear and logarithmic scales without altering raw fields.
- Geometry and YZ share the z axis; labels avoid rays and physical component/ROI dimensions are shown.
- YZ uses a physical transverse mesh and refined z samples, avoiding artificial thick slabs from extruded slices.
- Named planes track geometry; custom z retains precision. Slice windows are hidden and reused on close.

### Tests and documentation

- Independent diffraction/relay and source/condenser reference suites, practical-default convergence, corner cases and UI checks.
- Getting-started guide, control/units reference, equations, test map, honest limitations and a reproducible calculated example figure.
- Practical-default tests no longer depend on a hard-coded `/tmp` output path.
- Historical convergence fixtures are isolated from startup changes; the qualitative correlation check uses base MATLAB.

### Known limits

This remains a scalar, low-NA teaching model with ideal lenses and a Gaussian condenser. It excludes thick masks, polarization, substrate/resist physics and real lens aberrations. Input admission is not a convergence guarantee for every case. Native MATLAB/macOS close-button crash elimination is not established by callback tests. See [VALIDATION.md](VALIDATION.md).

## Initial public version

Commit `169a749` introduced the configurable MATLAB GUI, source/mask/pupil controls and propagation views. Older screenshots and normalized intensities need not match the connected source model or the new defaults.
