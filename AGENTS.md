# Optical Bench web and iOS

The owner is a scientist, not a software engineer: explain outcomes briefly in familiar language. Preserve the latest approved request; later corrections supersede earlier layout choices.

## Source map

- `dist/` is the authored web application despite its name. `scripts/` contains asset preparation and the native bridge. `tests/` holds numerical and state checks.
- `npm run ios:sync` prepares `ios-web/` and synchronizes `ios/App/App/public/`. These are generated outputs; fix their source instead. `IOS_INSTALL.md` documents the native build/install route. Verify preparation still finds the app entry after changing versioned script URLs.
- The containing MATLAB repository may track a `web/` subtree mirror. Verify the active Git root and revision, and synchronize through the existing workflow when required; do not treat both copies as independent sources.
- Read `README.md` for calculation/cache architecture, `MATLAB_PARITY.md` for cross-implementation comparisons, and the relevant portion of `TEST_REPORT.md` for historical evidence. Recheck live hosting/signing status rather than copying old prose.

## Behavior to preserve

- Source pupil and projection aperture are independent. Moving a view does not move the physical Image plane; named-plane geometry remains precise despite rounded labels.
- Layout changes preserve raw fields, sampling levels, normalization semantics and cache provenance. Cache acceptance must account for the current parameters and result identity; late jobs cannot overwrite a replaced or deleted/recreated view.
- Selection, position movement and Compute are separate actions. Mobile Standard keeps a full-width relative tuning strip with plane and z in its Position row. Expert uses a shorter strip with the plane selector beside it; its Positions row contains Reset, Undo, Redo and z. The next row holds + Panels, High detail and Compute. Fast releases may coast briefly, but Compute and selection changes must synchronously stop motion at the displayed z. General Settings has a collapsed Position tuning section for slow speed, fast speed and glide; these apply to both modes. Position history covers movement, add/remove and Reset, and groups a scrub gesture as one step. A new edit clears Redo; optical setup changes clear history. Position editing no longer needs Edit disclosure. Keep marker and scrubber pointer capture on stable nodes, declare touch-action before gesture start, and preserve the selected identity while dragging.
- Fine-tuning updates must not replace or reparent the active range control during a drag. In `dist/control-layout.js`, position updates refresh readouts; structural relocation belongs to actual mode/layout transitions. Check the final stylesheet/script cascade before adding another override.
- Preserve the current larger Key positions images and natural scrolling. The old goal of squeezing the whole desktop app onto one screen is superseded. Frequent controls stay near their action; secondary wave options stay in Settings on mobile. Latest user instructions take precedence over this baseline.

## Mobile layout acceptance

- Mobile Standard hides the complete Intensity section and its divider. Mobile Expert and desktop retain Intensity. The default-on "Aperture-transmitted projection" selection uses the actual NA and pupil shape to reconstruct the transmitted complex field before the projection stop. Projection outline cropping is a display envelope, not physical lens acceptance. Yellow illumination shows the original computed incident field and bypasses schematic cropping; the earlier full-path yellow crop is superseded. Do not make a collimated beam converge to the small mask calculation window. Keep the full-field and transmitted selections distinct, automatically load the matching Fine preset cache after switching, require Compute for uncached edited settings or other detail levels, and never reuse the full-field cache for the transmitted selection.
- The condenser applies soft Gaussian attenuation, not a finite hard edge. Lens 1 and Lens 2 are ideal phase-only lenses with no independent finite hard aperture. The projection pupil applies its configured opening/shape, independently of the amplitude mask; illustrated component dimensions must not imply additional physical blocking. Display corrections preserve raw fields, sampling and XY/image physics.

- Own compact spacing in `dist/interaction-layout.css`: 4px within groups, 8px between rows, 12px between sections. Inspect parent padding/margins and actual display mode before changing gaps. Do not add a new contradictory override for each annotation.
- Settings menu contains only General and About. Components belong in General; contact and privacy belong in About, with no mobile page footer. Default preset reads Preset; Standard result heading reads Position.
- Tuning shows the live marker value during drag/coast, just as dragging the beam marker does. Numerical kernels and cache identity are unaffected.
- Check 320/337/393/507 CSS px with long z, Standard/Expert, add/reset/undo and compute/cancel. Inspect both measured document-coordinate gaps and whole screenshots; no horizontal spill or status-driven extra rows. At 320 px the precise z value must remain fully visible and action targets remain 44 px high.

## Verification and delivery

- Never redraw a hidden intensity canvas using a fallback width of one pixel. Preserve the previous buffer while hidden; redraw after reveal using its real layout size and keep the SVG overlay aligned. Check fresh Standard startup then Expert without resizing, as well as repeated switching.

- For layout changes, use the reported CSS viewport and mode, then inspect a representative shared-code layout. Verify requested edges/rows plus the overall screenshot; shorter labels alone do not prove alignment. Keep physical beam and wave coordinates aligned, not just their outer boxes.
- Run relevant existing tests; `npm test` is the complete suite and includes expensive fresh numerical calculations. UI-only changes need affected interaction/layout checks, while numerical changes and release checks justify the complete suite and independent references.
- Browser emulation, native simulator, signed physical-device behavior and distribution are different evidence. For native changes, check bundled/offline loading, a changed-parameter calculation, save/reopen/relaunch and system export as relevant. See `IOS_INSTALL.md` and the current App Store release draft for delivery work.
- Record new validation with revision, environment and limitations. Do not treat an old test count, unsigned archive, opened share sheet or deployment command as proof of publication or successful delivery.
