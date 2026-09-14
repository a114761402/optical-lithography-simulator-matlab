# User guide

[README](../README.md) · [Equations](../FULL_PATH_MODEL.md) · [Validation](../VALIDATION.md)

## First experiment

Run `lithography_specular_gui` from the project folder. Leave the initial settings unchanged.

1. Look at **Mask amplitude**: three transmitting vertical bars.
2. Look at **Image (local scale)**: three bars remain visible, with blurred edges.
3. Select **Image**, then **Show XY**. Its raw image is the same calculation as the small image panel; the viewing window and colour scale may differ.
4. Select **Mask + 1 um**, then **Show XY**. This is diffraction just after the mask, not the focused image.
5. Click **Update YZ** for the sampled full path. Use XY for micrometre detail.

**Reset** restores the laboratory example. Reference presets and lecture examples are independent, often smaller-scale cases; choosing one changes more than the mask shape.

## Four sizes that must not be confused

| Name | Default | Meaning |
|---|---:|---|
| Plate side | 50.8 mm | Mechanical outline; not a computed optical aperture |
| Pattern envelope | 60 µm | Box containing the local pattern; not necessarily all transmitting |
| Mask window | 80 µm | Sampled region around the pattern |
| Image viewing window | 20 µm | Mask window divided by the 4× reduction |

The pattern envelope maps to 15 µm at the image. The actual bright footprint has diffracted edges and need not equal this envelope. **Plate vs local pattern** draws the plate and an enlarged local view, with different scales labelled.

Only the isolated local pattern transmits in this model. Other patterns, substrate effects and plate edges are omitted. Changing plate size alone cannot change the field.

**4× reduction** means a mask distance of 20 µm becomes an image distance of 5 µm. The image is also inverted, with magnification −0.25. The symmetric default grating does not make this inversion obvious.

## Where the components are

The source defines absolute z = 0. These are the startup values.

| Plane | Absolute z | Separation from previous plane |
|---|---:|---:|
| Source | 0 mm | — |
| Condenser | 100 mm | 100 mm |
| Mask | 200 mm | 100 mm |
| Lens 1 | 300 mm | 100 mm |
| Pupil | 400 mm | 100 mm |
| Lens 2 | 425 mm | 25 mm |
| Nominal image | 450 mm | 25 mm |

Thus **1 µm after the mask is z = 200.001 mm**, not z = 0.001 mm. The latter is near the source.

Lens 1 has f₁ = 100 mm and Lens 2 has f₂ = 25 mm. The 4f relay requires mask–L1 = f₁, L1–L2 = f₁ + f₂, and L2–image = f₂. The pupil lies at the shared focal plane. The GUI maintains these nominal separations as focal length or reduction changes. The condenser uses its focal length for both source–condenser and condenser–mask distances.

Named selections such as **Image** follow geometry changes. **Custom z** stays at its absolute coordinate. Defocus moves the observation plane relative to nominal focus; it does not insert an optical surface. Exact condenser, mask and pupil slices show the exit side.

The geometry drawing exaggerates transverse sizes. Lens 1 and Lens 2 use schematic biconvex icons, not physical lens profiles or measured diameters. The labels still say **Ideal, unbounded**: the finite pupil, not a modelled mechanical lens edge, limits transmitted spatial frequencies.

## What each picture means

| View | Quantity and interpretation |
|---|---|
| Geometry sketch | Ray-layout illustration, not intensity data |
| Source weights | Emitter-position weights, not wave intensity at the source plane |
| Mask amplitude | Amplitude transmission, approximately 0 or 1 with sampled boundary pixels |
| Pupil (local scale) | Intensity transmitted through the pupil, not just its outline |
| Image (local scale) | Image intensity divided by its own peak |
| XY | Wave intensity on a physical plane, using full source quadrature |
| Wave preview YZ | x = 0 cut, physical y in mm, reduced source quadrature |
| XZ | Additional reduced-source propagation preview |

YZ is not the full beam envelope. Grey regions are **outside the sampled transverse windows**, not opaque material. Interpolation joins calculated z samples; it is not an extra calculation at every screen pixel. Thin elements have no drawn physical thickness. Micrometre features can disappear visually when the millimetre-scale path is shown.

The four small overview panels omit colour bars to reduce clutter; their normalization is unchanged. XY and YZ retain their scale bars for quantitative reading.

**Show XY**, XZ, **Plate vs local pattern** and **Model details** open independent snapshots. Existing windows retain their data and individual colour controls when another plot is requested, settings change or input is rejected. A new XY window starts with the latest XY window's colour-mode choice. Closing a snapshot hides it safely and makes that closed window eligible for reuse; an open snapshot is never recycled. **Hide extra views** remains an explicit action to hide auxiliary windows.

### Colour scales

| Scale | Best use |
|---|---|
| Local linear | See shape; peak is 1 when nonzero |
| Local log (dB), XY only | Faint structure relative to the plane's peak |
| XYZ linear | Brightness across z on a shared reference |
| XYZ log (dB) | Weak signals across z; display floor −120 dB |

YZ **Local / z** rescales each plane separately; it is not a power plot. XY and preview scales are independent. Switching scale changes neither raw intensity nor propagation. The XY title states the raw peak and its ratio to the shared reference. This reference uses selected planes, not necessarily the largest intensity anywhere; stronger intermediate peaks are flagged as colour saturation. A genuinely zero field stays dark.

## Why an image may not resemble the mask

A finite pupil filters spatial detail. Exact focus cannot recover diffraction orders removed by the pupil. Wavelength, NA, source distribution, pitch and reduction all matter.

For an on-axis coherent plane-wave estimate, the object-side cutoff is `NA_image / (R * wavelength)`. The default 20 µm pitch has first-order frequency 0.05 cycles/µm, below the cutoff of about 0.103 cycles/µm. This is a useful check, not the complete finite, partially coherent grating calculation. The default test also confirms three image peaks at 5 µm spacing.

Near a mask, diffraction rounds edges and produces fringes without a lens. A rough scale is `z ~ a² / wavelength`, where `a` is the feature scale being inspected. There is no universal distance at which the mask vanishes: contrast, feature size and coherence matter, and periodic gratings can form Talbot revivals. Use XY slices and convergence tests instead of treating this estimate as a rule. See the [diffraction references](../FULL_PATH_MODEL.md#references).

## Controls and admission limits

[lithography_check_settings.m](../lithography_check_settings.m) selects the grid and rejects unsupported combinations. The solver also checks incident-illumination quadrature before the relay sum. Invalid settings clear stale optical results.

| Control | Range or coupled condition |
|---|---|
| Wavelength | 50–2000 nm; feature and sampling guards still apply |
| Image-side NA | 0.05–0.30 in air; scalar/paraxial model only |
| Reduction | 1–20, subject to pupil sampling |
| Source outer extent | 0.08–1 in normalized source coordinates |
| Source inner radius / lobe separation | 0–0.96 / 0.1–2; annular thickness at least 0.04 |
| Point coordinates | u, v each −1 to 1, plus a coupled angular bound |
| Emitter divergence | 0.02–0.15 rad Gaussian half-divergence, distinct from image NA |
| Condenser Gaussian radius scale | 0–1; 0 blocks light, nonzero radii have a diffraction-angle guard |
| Plate side | 1–200 mm; context only |
| Local mask window | 1–100 µm, subject to the grid budget |
| Mask extent | 0.1–75 µm and at most 75% of the window |
| Grating pitch / duty | 0.1–50 µm / 0.10–0.90; pitch cannot exceed mask extent |
| Smallest mask feature | At least one wavelength and eight mask pixels |
| Mask inner ratio | 0–0.9 |
| Pupil inner/width ratio | 0–0.9; slit width ratio at least 0.1 |
| Freeform source/pupil | Finite square arrays, up to 129 × 129, values 0–1 |
| Condenser focal length | 20–160 mm, nominal conjugate distances |
| Lens 1 focal length | 10–110 mm; Lens 2 and spacings follow reduction |
| Defocus | At most ±20 µm, further restricted by phase-error and window-margin estimates |
| Absolute z | Nonnegative, within the system's supported end margin |
| Mask grid / padded transform | Automatic 256/384/512; padded arrays at most 2048 per side |
| Pupil sampling | At least 20 diameter samples, extra annular/slit restrictions, 64 for freeform |
| Source sampling | Up to 625 weighted modes; support-angle and phase-sampling checks |

These ranges are **not independently combinable**. A large pattern and broad source can fail quadrature checks with every individual control in range. For example, the broad Quadrupole setting is rejected with the startup's 60 µm pattern; its dedicated smaller-pattern preset remains available. Empty sources and closed apertures are valid dark cases. Unresolved patterns can be physically valid.

Freeform pupil values are **amplitude transmission**; intensity transmission is their square. Source values are relative emitter weights. Neither editor specifies optical phase. Tiny drawn details can require refinement beyond the baseline guards.

## Troubleshooting

| Symptom | First check |
|---|---|
| MATLAB cannot find the program | Set Current Folder to the repository root; run `which lithography_specular_gui` |
| XY uniformly dark | Check raw peak; try Local linear or XYZ log |
| Two image panels differ | Match z, physical axis limits and colour scale; one may show a wider ROI or logarithmic tails |
| No mask shape at image | Check reduction, pitch, wavelength and pupil cutoff; restore the default as a baseline |
| Bright slab or jump | Check axes and preview sampling; mask/pupil can attenuate, but image has no transmission operation |
| Slow preview | Leave Auto YZ off; inspect selected XY planes and update YZ when needed |
| Setting rejected | Read the coupled constraint; do not bypass it for a desired-looking picture |
| MATLAB crashes when closing a slice | Record MATLAB/OS version and reproduction steps; hidden reusable windows reduce destruction, but native crash elimination is not proven |

For a bug report, include the settings (or preset and changes), absolute z, colour scale, MATLAB version and expected behaviour. See [testing and development](DEVELOPMENT.md) for checks and limitations.
