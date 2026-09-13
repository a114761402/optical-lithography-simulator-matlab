# Propagation equations and implementation

[Model contract: source, coherence and assumptions](../FULL_PATH_MODEL.md) · [User guide](USER_GUIDE.md)

This document describes the implemented operators, not a claim of validity for arbitrary real optics. Let **r** = (x, y), spatial frequency **ν** = (νx, νy), and k = 2π/λ. Internal lengths are metres. The Fourier convention is `F{U}(ν) = integral U(r) exp(-i 2π ν.r) d²r`. Overall phase common to one emitter's entire plane may be omitted. Different emitters are never summed as complex amplitudes.

## Thin mask and pupil

The [source model](../FULL_PATH_MODEL.md#source-and-condenser) supplies complex incident fields. The mask multiplies amplitude: `U_exit,q(r) = t(r) U_incident,q(r)`. Built-in masks are binary objects; the raster averages 4 × 4 subpixel samples. Fractional boundary pixels represent numerical area averaging, not real edge materials. No mask thickness or adjustable material phase is included.

For reduction R, the on-axis object-side coherent cutoff is `νc = NA_image / (R λ)`. A circular pupil passes `|ν| <= νc`; other shapes replace that support. Physical pupil coordinates are `rp = λ f1 ν`, so the circular radius is `f2 NA_image` in this paraxial model. At nominal conjugates:

```text
U_image,q(ri) = R * F^-1{ P(ν / νc) F{U_exit,q}(ν) }(-R ri)
I_image(ri)   = sum_q wq |U_image,q(ri)|²
```

The R amplitude factor preserves integrated power under reduction before aperture losses. P is amplitude, not intensity transmission. The physical pupil field includes `1 / (i λ f1)`; Fourier quadrature includes mask pixel area. See [lithography_coherent_fields.m](../lithography_coherent_fields.m).

## Scalar diffraction near the mask

For forward distance d > 0 and ρ = sqrt(x² + y² + d²), the implemented Rayleigh–Sommerfeld kernel is:

```text
h_d(x,y) = d / ρ² * [1/(2πρ) - i/λ] * exp(i k ρ)
U(d)     = U(0) * h_d                         (2D spatial convolution)
```

When the kernel meets the sampling criterion, FFT linear convolution includes integration factor Δx². Otherwise padded angular-spectrum propagation uses:

```text
H_AS(νx,νy;d) = exp[i 2π d sqrt(λ^-2 - νx² - νy²)]
U(d)          = F^-1{F{U(0)} H_AS}
```

The square root selects decaying evanescent frequencies for forward propagation. At sufficiently large d relative to a pixel, transfer-phase sampling bounds suppress aliased frequencies. Output is cropped to the requested window; power outside it is not captured by the plot. Negative-distance RS requests are rejected. See [lithography_wave_propagate.m](../lithography_wave_propagate.m).

Propagating a prescribed scalar boundary field, including evanescent frequencies, does **not** solve a thick or metallic mask's electromagnetic boundary problem.

## Paraxial relay and free-space slices

Free propagation uses `T(d) = [1 d; 0 1]`; a thin lens uses `L(f) = [1 0; -1/f 1]`. With f2 = f1/R:

```text
T(f2) L(f2) T(f1+f2) L(f1) T(f1) = [-1/R  0; 0  -R]
```

For `[A B; C D]` with B nonzero, the 2D Collins integral is:

```text
U2(r2) = exp[iπD|r2|²/(λB)] / (iλB)
         * integral U1(r1) exp[iπA|r1|²/(λB)]
           exp[-i2π r1.r2/(λB)] d²r1
```

Two Bluestein transforms evaluate it on explicit physical axes. See [lithography_lct.m](../lithography_lct.m). Near nominal image focus, same-grid Fresnel propagation uses `H_F = exp[-iπ λ d (νx² + νy²)]` with bounded padding and anti-aliasing, or the corresponding convolution kernel. See [lithography_fresnel_same.m](../lithography_fresnel_same.m).

Between pupil and L2, a backward Collins transform through L2 reconstructs the pupil-transmitted field from its nominal image. This is paraxial reconstruction after pupil loss, not backward propagation through an opaque mask. Choosing an image marker inserts no optical operation.

## Calculation selected at each z

| Region | Operator | Main limitation |
|---|---|---|
| Source to immediately before mask | Analytic Gaussian modes; continuous source-cell intensity integral | Paraxial emitters and Gaussian condenser, no hard edge |
| Exact mask | Thin-mask exit, same emitter quadrature as relay | Prescribed scalar boundary |
| First 0.5 mm after mask, before L1 | RS or band-limited angular spectrum | Cropped local ROI; not material near fields |
| Remaining mask-to-pupil path | Collins transform with relevant lens matrix | Paraxial, not rigorous high-angle/vector propagation |
| Exact pupil | Shared transmitted pupil field | Finite amplitude pupil |
| Pupil to L2 and downstream | Collins propagation/reconstruction; Fresnel near nominal image | Ideal lenses, bounded windows |
| Selected image | Same rules as neighbouring z; label only | No physical surface or transmission jump |

The near-image same-grid branch requires distance from nominal focus < 0.5 mm **and** a beam-expansion/window check. These distances are implementation switches, not universal physical boundaries. Quantitative use of transition regions requires convergence and cross-operator comparisons. Guards do not certify every continuous z or arbitrary pattern. See [lithography_projection_slice.m](../lithography_projection_slice.m).

## Display equations

Local linear displays `I / max(I)`; XYZ linear displays `I / Iref`. Log modes use `10 log10(I / reference)` with a −120 dB floor: intensity uses **10**, not 20. All-zero fields are handled explicitly. The shared reference uses selected source, incident-mask, pupil and image peaks, not a global maximum over all z. See [lithography_xy_display.m](../lithography_xy_display.m) and [lithography_preview_display.m](../lithography_preview_display.m).

The equations above are transcriptions of this implementation. For diffraction theory and the published numerical methods, see the [model references](../FULL_PATH_MODEL.md#references).
