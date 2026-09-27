# Optical Bench

Standalone browser version of the MATLAB optical-lithography teaching simulator. No MATLAB, API key, GPU, or backend is required for the calculations. The hosted Site keeps its existing owner-private access.

Run `python3 -m http.server 8765 --directory dist`, then open `http://127.0.0.1:8765`. Module workers require HTTP rather than a file URL. Run `npm test` for numerical and state-management checks.

## Interface

- Desktop: Preset and Reset sit above the beam; ray visibility lives in Settings. Long component controls scroll within the right panel without moving Key positions. The fixed Image symbol previews its own cached image, with display zoom, position selection and PNG saving in its inspector.
- Desktop: select a **Key position** to edit it. Coarse positioning, fine tuning, numerical entry, and the draggable beam marker update that target. **Compute all slices** computes retained views and reuses matching results. Click blank space in the Key positions area or the beam, or press Escape, to deselect. All A–D labels stay below the beam; nearby labels separate horizontally with leader lines. Minus/Delete removes a position; Undo restores it.
- Mobile: the whole beam fits the screen. **Explore position** retains the single image with Send and Profile. **Key positions** starts with the same four independently editable views as desktop. **Edit** reveals the shared tuning controls; select a tile before using them. **Done** hides the editor; **Compute all slices** also closes it after committing the current position. The active group’s letters stay below the mobile beam; other positions remain as faint ticks. **Reset** beside Edit restores only the current preset's four default positions. The top Reset restores the entire initial experiment.
- **Default positions** restores Pupil plane, Mask exit, Aperture plane, and the ideal Image plane, without changing the optical setup. Moving a screen does not move the physical image plane.
- Wave intensity has direct XZ/YZ switches and physically aligned component symbols. **Compute full path** is its only calculation action. Display/detail/brightness options are in Settings (the mobile menu). The optional desktop profile is disabled until enabled there.
- Yellow denotes illumination; blue denotes projection. These are stage colours, not different wavelengths. Source pupil shape (illumination pupil) and projection aperture shape remain independent.

### Position groups and compact controls

**＋** beside Key positions duplicates the preceding four positions on desktop or two on mobile. The new group starts selected/editable and shares existing immutable results until moved. Letters continue after D (and after Z); resize never changes the group count. Delete/Minus and Undo work with expanded groups; mobile Minus appears only during Edit. Default positions / local Reset returns to the original four and supports Undo. Matching displayed results are reused even after their LRU entry expires; the fixed image is retained separately. Offscreen cards render on approach to the viewport.

Position readouts use up to three decimal places in mm; ordinary moves and Fine tuning use 1 µm increments. Internal attached-plane geometry remains exact: merely displaying a rounded position or clicking Compute does not detach it. The inspector has one component heading, aligned number/unit columns and compact parameter spacing, with internal scrolling retained for small screens or expanded help.

## Presets and saved numerical fields

The Preset menu includes the original default, coherent 4f spatial filtering, circular-aperture diffraction, annular illumination, and dipole illumination. Their parameters are illustrative low-NA scalar teaching setups, not exact reproductions of published instruments. Settings contains a description and a primary reference for each literature-inspired example.

Every preset ships four Fine XY fields and both XZ/YZ full-path cuts in `dist/data/presets/`. The files contain full-precision numeric arrays and coordinates, compressed losslessly with gzip. Only the selected preset is loaded and retained in the loader. A version/parameter key plus request and optical-revision checks prevents late or mismatched results from replacing the current setup. The in-session slice cache is bounded. Files use HTTP caching when provided by the host; no persistent browser database is required. Browsers with `DecompressionStream` load saved results; if loading fails, the interface permits local computation.

Fine uses a 512 × 512 mask grid, 2× propagation padding, and 25 × 25 source bins (445 weighted emitters for the default circular source). Circular and annular illumination use a continuous source integral over the exact circular boundaries. Other extended source shapes retain their 201 × 201 distribution. This is the maximum exposed detail, not a claim of convergence for every possible setup. Preview and Standard remain available in Settings for faster manual experiments.

Regenerate the preset assets with `node scripts/precompute-presets.mjs` after removing the preset files that need rebuilding. The generator retains completed presets, runs at most three jobs, and writes a manifest with engine provenance. All rebuilt presets compute fresh full-path cuts, including the default. Their dense pupil cut is replaced consistently with the XY calculation. The original file and `scripts/precompute-wave.mjs` remain available for full regeneration and independent regression checks.

## Aperture-plane sampling and display

The pupil Fourier-plane spacing is λf₁/(padding × mask window), so increasing the mask grid alone does not make its pixels closer. The default previously displayed about 36 samples across its 8.25 mm pupil window. A scaled Fourier/Collins transform now evaluates the same mask field directly on a local 257 × 257 pupil grid, about 32.23 µm spacing, while retaining the original input mask sampling and incoherent source weights. The projection aperture is applied to that field. This avoids globally increasing propagation padding and memory.

The dense pupil is used by cached XY views, manual pupil calculations, and the full-path central cuts. Wave updates evaluate the two dense cuts directly rather than computing an extra full XY field. Tests compare the dense pupil with a separately padded FFT at matched physical coordinates and compare the fast cuts with the full dense XY field.

Displayed intensity uses bilinear interpolation **before** brightness/colour mapping, with no CSS blur. Raw fields and profile values remain unchanged; the physical projection-stop boundary remains blocked. Canvas resolution follows display density up to 2×. Settings offers a raw-pixel display toggle for inspection. Interpolation makes a display smoother; it is separate from the added physical samples.

## Continuous circular and annular illumination

The source Gaussian intensities are integrated over exact circular/annular support with uniform power per unit source area. A one-dimensional adaptive integral and radial lookup replace the old pixelized source boundary in the illumination region only. Projection still uses the unchanged incoherent emitter sampling and FFT/Collins model.

The full-path display samples neighboring columns at the same physical transverse coordinate, then interpolates longitudinally. Fine adds 0.5 mm planes through the first 40 mm (and tighter sampling immediately next to the source), bringing the default full path to 205 planes. Those extra planes use the inexpensive illumination integral; they do not add projection FFTs. Interpolation never mixes opposite sides of a thin element. Numerical tests check analytic on-axis intensities, independent polar integration, symmetry, integrated power before the condenser, and intermediate-z cuts.

The ring can physically fill inward as mutually incoherent Gaussian emitters broaden. The former coarse zigzags were not evidence of annular-source interference: moving-window interpolation, coarse z spacing and rasterized source edges all contributed. This remains a teaching emitter model, not a complete lithographic Köhler illuminator. The incoherent intensity-sum principle is described in [Zuo et al., Scientific Reports (2017)](https://www.nature.com/articles/s41598-017-06837-1); aperture-plane conjugacy is explained by [Nikon MicroscopyU](https://www.microscopyu.com/microscopy-basics/conjugate-planes-in-optical-microscopy). These references support the model interpretation, not the numerical artifact diagnosis, which comes from code inspection and comparison tests.

All five Fine caches have been refreshed. `scripts/refresh-illumination-caches.mjs` recomputes reference images and illumination columns, and reuses projection columns only after verifying the original projection source and parameters against the recorded baseline.

## Physics and limits

The model uses double-precision complex FFTs, mutually incoherent Gaussian emitters, a soft Gaussian condenser aperture, pixel-area mask sampling, a thin amplitude mask, and an ideal two-lens 4f relay. Near-mask propagation uses Rayleigh–Sommerfeld/angular spectrum; defocus and intermediate planes use scalar Fresnel/Collins propagation. The full path has adaptively placed z planes; near-mask mode has 61 planes. The wave background is a full dark rectangle. Settings can optionally mark the calculated window in grey; black beyond that window is background, not evidence of a simulated zero field. Local brightness scaling shows shape, not comparable power along z.

It omits polarization, vector/high-NA effects, real lens materials/surfaces, aberrations, resist, and whole-reticle simulation. Component heights and mounts are illustrative; the longitudinal ruler is physical. Source coordinates are normalized emitter positions, not directly specified lithographic sigma. Refine both mask and source sampling before quantitative interpretation.

MATLAB remains unchanged. See [MATLAB_PARITY.md](MATLAB_PARITY.md) and [TEST_REPORT.md](TEST_REPORT.md). The root MATLAB repository retains this website as its tracked `web/` subtree; the managed Sites working checkout is separate.

## Projection path display sampling

The full path adds geometrically spaced axial samples around the mask exit and focus (246 Fine planes for default geometry, previously 205). LCT centre cuts extend the output window to up to three times its former span with the same transverse spacing; the 2-D FFT grid and source quadrature are unchanged. This captures previously clipped tails without globally increasing propagation memory. Added output samples are capped at the input Nyquist bound to avoid periodic aliases for coarse/custom setups. Exact calculated planes are unchanged within their former domain. Between projection planes, nonnegative monotone cubic interpolation operates at fixed physical transverse coordinates and is bounded by the two bracketing intensities. Mask and projection-aperture jumps remain one-sided; phase-only lenses are not treated as intensity jumps. Final pixel coverage provides antialiasing without a CSS blur.

`refresh-projection-caches.mjs` records and verifies the earlier engine hash, unchanged optical operators and matching parameters before reusing unaffected XY, illumination and non-LCT cuts. All changed LCT cuts and new axial positions are recalculated at Fine detail. Arrays remain full-precision and gzip is lossless.
