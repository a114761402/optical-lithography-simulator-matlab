# Full optical path: model contract

[README](../README.md) · [User guide](USER_GUIDE.md) · [Propagation equations](EQUATIONS.md) · [Validation](VALIDATION.md)

This is a **scalar teaching model**, not a measured-source reconstruction or a Maxwell solution of real lenses and mask materials. The GUI uses this model by default. No geometrical illumination image is substituted for an XY wave calculation.

## Source and condenser

All distances in formulas below are metres; lambda is the wavelength in air.

- An emitter at transverse position q starts as `g_q(r) = sqrt(2/(pi*w0^2)) * exp(-|r-q|^2/w0^2)`. Its integrated power is one.
- `w0 = lambda/(pi*sourceEmissionNA)`; the new divergence control is the paraxial Gaussian half-divergence, not the imaging NA.
- Emitters are mutually incoherent, but each finite emitter is internally coherent. This is not an ideal delta-correlated, infinite-bandwidth source.
- The source-position distribution S(q) uses the selected circular/square/annular/dipole/quadrupole/freeform shape. The physical coordinate is `q = f_cond * NA_image / reduction * (u,v)`. This explicit mapping is a model assumption, not a measurement of a lamp.
- The total emitted power of a nonempty source is normalized to one. Raw intensities therefore have units of inverse square metres per unit source power. Display normalization does not change propagation.
- At the condenser, amplitude is multiplied by `exp(-r^2/a^2) * exp(-i*pi*r^2/(lambda*f_cond))`, where `a = f_cond * NA_image / reduction * condenserAperture`. Thus a is the intensity 1/e^2 radius. **This is a Gaussian transmission aperture, not a hard edge.** Zero radius is defined as fully closed.

Gaussian modes remain Gaussian through this ideal condenser, permitting an analytic Fresnel solution even across the micrometre-to-millimetre scale difference. For `U = gain * exp(-a*r^2 + b*q.r + c*q^2)` and free-space distance d, set `D = 1 + i*lambda*d*a/pi`; update `a -> a/D`, `b -> b/D`, `c -> c + i*lambda*d*b^2/(4*pi*D)`, and `gain -> gain/D` (old b on the right). A global phase per emitter is irrelevant because emitters are never summed coherently with one another.

Before the mask, intensity is `integral S(q)*|U_q(r,z)|^2 dq / integral S(q) dq`. Piecewise-constant source cells are integrated analytically with real Gaussian error functions. This avoids artificial checkerboards from sparse source-point plotting. Gaussian field evaluation uses a completed square to avoid overflow/cancellation for far-off-axis emitters.

## The calculation is connected

At the mask, **the propagated complex field**, not a reset plane wave, is used:

`U_mask,q = mask_amplitude * U_q(r,z_mask)`.

Each resulting field goes through the existing near-mask Rayleigh–Sommerfeld/angular-spectrum propagator or ideal paraxial 4f relay. The final intensity is `sum_q weight_q * |U_detector,q|^2`. Neither condenser loss nor pupil loss is renormalized away. Coherent interference is retained within each emitter's mask diffraction, not between independent emitters.

The relay control is labelled `Lens 1 f (mm)` and displays the actual first-lens focal length. The internal legacy parameter `projectionFocalMm` is still twice that focal length; the GUI converts between them. `f2=f1/reduction`. The 365-nm laboratory defaults have f1=100 mm, f2=25 mm, mask-L1=100 mm, L1-L2=125 mm, L2-image=25 mm and pupil-image=50 mm. These are ideal principal-plane separations, not a commercial lens prescription or glass-surface spacings.

Continuous source intensity before the mask and finite emitter quadrature after it are two numerical approximations to the same source integral. Their mask-plane agreement is explicitly tested; it is not assumed to be exact for arbitrary configurations. The mask-plane exit slice uses the same sum as the detector calculation.

## Axes and display

- z is absolute from the source. At current default settings, mask z = 200 mm; 1 micrometre after the mask means **200.001 mm**, not 0.001 mm. The selected image plane is z=450 mm.
- The 50.8 mm mask plate is a mechanical context outline only. Waves propagate through a 60 um local pattern within an 80 um window, with zero transmitted field outside the local window: this assumes an isolated pattern, not a repeated or complete reticle layout. Other transmitting features, plate edges and substrate effects are excluded. Changing plate-size metadata does not change the field. The default nominal image pattern envelope is 15 um across, with 5 um pitch and 2.5 um line width; the 20 um display ROI is not the image spot size.
- XY uses real spatial coordinates. The source-to-mask illumination view covers the beam; the mask/near-mask view is a micrometre-scale cropped region. A change in displayed extent is not an optical discontinuity.
- Off-axis point emitters have separately centred physical x/y axes. Source-plane images show a finite Gaussian waist, not a mathematical singularity.
- Exact element planes show the exit side: condenser transmission at z_cond, mask exit at z_mask, pupil exit at z_pupil.
- XYZ uses a shared reference from source, mask illumination, pupil and image peaks. Intermediate interference can exceed that reference; the GUI explicitly flags color saturation. Local scaling is for shape only. A point-source waist can be orders of magnitude brighter than downstream planes, so those planes can appear dark on XYZ even when nonzero.
- The small source panel shows emitter weights, not wave intensity. The top optical layout is a geometry sketch. YZ is a sampled x=0 wave centreline with physical y coordinates in millimetres; it is not a ray-density plot or the entire beam envelope. Its z mesh is refined on both sides of thin elements and around focus, with interpolation only between calculated samples. Grey regions lie outside the sampled transverse windows. XY uses full source quadrature. YZ/XZ are explicitly reduced-source previews. The selected image plane is an observation plane, not a separate optical operation or special propagation grid.

## Admitted settings and remaining limits

The GUI bounds scalar inputs, enforces nominal conjugates, chooses mask/pupil sampling, limits memory, and rejects undersampled combinations. New guards limit emitter divergence, nonzero Gaussian-aperture diffraction angle, source support angle, and emitter-quadrature phase variation across the mask. With a 25-by-25 source binning grid, the latter requires `2*sourceExtent*NA*maskSize/(25*reduction*lambda) <= 0.25`.

These are necessary numerical/model bounds, **not a proof that every admitted setting is accurate to a fixed percentage**. Arbitrary freeform masks, boundary positions and diffracted tails still require convergence checks. A dark result from a closed aperture or blocked diffraction orders can be correct. Invalid settings produce an explicit error, not a fabricated image.

Before the expensive relay calculation, a 7-by-7 check across the mask compares emitter quadrature with the analytic continuous illumination integral. Guarded runs reject a relative discrepancy greater than 2%, rather than showing an under-resolved source/condenser combination. This checks incident intensity coupling; it is not a substitute for convergence of the diffracted image. Gaussian cell tails use complementary error functions to avoid subtracting rounded values near one.

Not included: hard-edge condenser diffraction, polarization, material dispersion, thick masks, evanescent coupling to materials, real lens surfaces/aberrations, or rigorous vector high-NA focusing. Near-mask scalar RS propagation and the paraxial relay have different approximations. Do not interpret uncollected high-angle light in a paraxial relay view as a rigorous electromagnetic prediction.

## Independent checks

`lithography_illumination_tests` compares with independent Gaussian width/power formulas, direct complex Fresnel quadrature, analytical Gaussian-aperture transmission, and a separate dense source integral. It checks interfaces, all eight source shapes, actual mask-to-detector coupling and dark cases. `lithography_regression_tests` retains independent relay/diffraction mathematical references using an explicitly separate legacy angular-input benchmark.

## References

- [Ansys: coherence and incoherent source ensembles](https://optics.ansys.com/hc/en-us/articles/360034902293-Understanding-coherence-in-FDTD-simulations)
- [Edmund Optics: Gaussian beams and thin lenses](https://www.edmundoptics.eu/knowledge-center/application-notes/lasers/gaussian-beam-propagation/)
- [TU Delft: diffraction and the Fresnel approximation](https://qiweb.tudelft.nl/aoi/wavefielddiffraction/wavefielddiffraction/)
- [TU Delft: coherent imaging](https://qiweb.tudelft.nl/aoi/coherentimaging/coherentimaging/)

See VALIDATION.md for actually completed test results, not just test definitions.

Numerical methods: [Shen and Wang, FFT Rayleigh–Sommerfeld integration](https://pubmed.ncbi.nlm.nih.gov/16523770/); [Matsushima and Shimobaba, band-limited angular spectrum](https://pubmed.ncbi.nlm.nih.gov/19997186/). These motivate numerical operators, not a claim that the complete app reproduces every case in those papers.

Physical scale context: [Thorlabs chrome-on-glass targets](https://www.thorlabs.de/newgrouppage9.cfm?objectgroup_id=4338&pn=R1L1S1N) include 50.8 mm square plates; this supports the plate-scale illustration, not a claim that our local pattern is that product. [Nikon i-line systems](https://www.nikon.com/business/semi/sp_nsr-2205il1/) use 365 nm, but our low-NA focal lengths are illustrative laboratory parameters, not Nikon specifications. The relay uses the [4f construction described by Thorlabs](https://www.thorlabs.com/images/tabimages/MTN015225_A-CN02.pdf). Real [ASML DUV systems](https://www.asml.com/en/products/duv-lithography-systems/twinscan-nxt-1965ci) use substantially different high-NA, multi-element optics; this two-lens model does not reproduce them.
