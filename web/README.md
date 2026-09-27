# Optical Bench

Standalone browser version of the MATLAB optical-lithography teaching simulator. No MATLAB, API key, GPU, or backend is required for the calculations. The hosted Site keeps its existing owner-private access.

Run `python3 -m http.server 8765 --directory dist`, then open `http://127.0.0.1:8765`. Module workers require HTTP rather than a file URL. Run `npm test` for numerical and state-management checks.

## Interface

- Desktop: select one of the four **Key positions** to edit it. Coarse positioning, fine tuning, numerical entry, and the draggable beam marker update that target. **Compute all slices** computes retained views and reuses matching results. Click blank space in the Key positions area or the beam, or press Escape, to deselect. All A–D labels stay below the beam; nearby labels separate horizontally with leader lines. Minus/Delete removes a position; Undo restores it.
- Mobile: the whole beam fits the screen. **Explore position** retains the single image with Send and Profile. **Key positions** shows the same four independently editable views as desktop. **Edit** reveals the shared tuning controls; select a tile before using them. **Done** hides the editor. **Reset** beside Edit restores only the current preset's four default positions. The top Reset restores the entire initial experiment.
- **Default positions** restores Source, Mask exit, Aperture plane, and the ideal Image plane, without changing the optical setup. Moving a screen does not move the physical image plane.
- Wave intensity has direct XZ/YZ switches and physically aligned component symbols. **Compute full path** is its only calculation action. Display/detail/brightness options are in Settings (the mobile menu). The optional desktop profile is disabled until enabled there.
- Yellow denotes illumination; blue denotes projection. These are stage colours, not different wavelengths. Source shape (illumination pupil) and projection aperture shape remain independent.

## Presets and saved numerical fields

The Preset menu includes the original default, coherent 4f spatial filtering, circular-aperture diffraction, annular illumination, and dipole illumination. Their parameters are illustrative low-NA scalar teaching setups, not exact reproductions of published instruments. Settings contains a description and a primary reference for each literature-inspired example.

Every preset ships four Fine XY fields and both XZ/YZ full-path cuts in `dist/data/presets/`. The files contain full-precision numeric arrays and coordinates, compressed losslessly with gzip. Only the selected preset is loaded and retained in the loader. A version/parameter key plus request and optical-revision checks prevents late or mismatched results from replacing the current setup. The in-session slice cache is bounded. Files use HTTP caching when provided by the host; no persistent browser database is required. Browsers with `DecompressionStream` load saved results; if loading fails, the interface permits local computation.

Fine uses a 512 × 512 mask grid, 2× propagation padding, and 25 × 25 source bins (445 weighted emitters for the default circular source). The underlying source distribution is 201 × 201. This is the maximum exposed detail, not a claim of convergence for every possible setup. Preview and Standard remain available in Settings for faster manual experiments.

Regenerate the preset assets with `node scripts/precompute-presets.mjs` after removing the preset files that need rebuilding. The generator retains completed presets, runs at most three jobs, and writes a manifest with engine provenance. The original default full-wave calculation is reused only for the identical default optics; its dense pupil cut is replaced consistently with the new XY calculation. The original file and `scripts/precompute-wave.mjs` remain available for full regeneration and independent regression checks.

## Aperture-plane sampling and display

The pupil Fourier-plane spacing is λf₁/(padding × mask window), so increasing the mask grid alone does not make its pixels closer. The default previously displayed about 36 samples across its 8.25 mm pupil window. A scaled Fourier/Collins transform now evaluates the same mask field directly on a local 257 × 257 pupil grid, about 32.23 µm spacing, while retaining the original input mask sampling and incoherent source weights. The projection aperture is applied to that field. This avoids globally increasing propagation padding and memory.

The dense pupil is used by cached XY views, manual pupil calculations, and the full-path central cuts. Wave updates evaluate the two dense cuts directly rather than computing an extra full XY field. Tests compare the dense pupil with a separately padded FFT at matched physical coordinates and compare the fast cuts with the full dense XY field.

Displayed intensity uses bilinear interpolation **before** brightness/colour mapping, with no CSS blur. Raw fields and profile values remain unchanged; the physical projection-stop boundary remains blocked. Canvas resolution follows display density up to 2×. Settings offers a raw-pixel display toggle for inspection. Interpolation makes a display smoother; it is separate from the added physical samples.

## Physics and limits

The model uses double-precision complex FFTs, mutually incoherent Gaussian emitters, a soft Gaussian condenser aperture, pixel-area mask sampling, a thin amplitude mask, and an ideal two-lens 4f relay. Near-mask propagation uses Rayleigh–Sommerfeld/angular spectrum; defocus and intermediate planes use scalar Fresnel/Collins propagation. The full path has adaptively placed z planes; near-mask mode has 61 planes. Grey indicates outside the calculated window. Local brightness scaling shows shape, not comparable power along z.

It omits polarization, vector/high-NA effects, real lens materials/surfaces, aberrations, resist, and whole-reticle simulation. Component heights and mounts are illustrative; the longitudinal ruler is physical. Source coordinates are normalized emitter positions, not directly specified lithographic sigma. Refine both mask and source sampling before quantitative interpretation.

MATLAB remains unchanged. See [MATLAB_PARITY.md](MATLAB_PARITY.md) and [TEST_REPORT.md](TEST_REPORT.md). The root MATLAB repository retains this website as its tracked `web/` subtree; the managed Sites working checkout is separate.
