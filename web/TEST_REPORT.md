# Expert Add without automatic page scroll — 30 September 2026

Both the Key Positions + and each card's + keep the current page scroll position while selecting the new position. Removed the explicit smooth scroll and restored the viewport after card rendering, since DOM reordering could otherwise trigger browser scroll anchoring.

Browser checks at 320, 393, 507 and 1280 CSS px kept the same scroll offset after both + actions, with the new position selected, correct card count and no page errors. A scrolled 393 px page remained at 571 px after duplicating E; before this fix, the same action moved it to 118 px. Browser emulation does not establish physical-device behavior.

# Interpolate button height — 30 September 2026

The visible orange Interpolate/Apply box is 38 px high, centered inside its unchanged 44 px button target. Desktop and mobile keep the same action row and card positions. Browser screenshots and geometry at 320, 393, 417, 507 and 1280 CSS px verified the 3 px top/bottom inset, orange and active colours, unchanged card y coordinates, no horizontal overflow and no page errors. This is a visual and browser interaction check, not physical-device testing.

# Interpolation Undo while selecting — 30 September 2026

Undo now remains enabled while an Interpolate selection is in progress, even with no earlier position edit. Before Apply it cancels the selection, clears endpoint markers and the guide, and leaves positions unchanged. After Apply it reverts the recorded interpolation as before. The control keeps its row and changes its accessible label to "Cancel interpolation selection" while selecting.

Focused position/history tests passed 9/9; syntax, whitespace and offline iPhone asset preparation passed. Browser clicks at 320, 393, 417, 507 and 1280 CSS px verified that Undo cancels an A–D selection without changing card positions or causing horizontal overflow. At 417 px, Apply then Undo restored B = 200 mm and C = 400 mm. No page errors were observed. Browser emulation does not certify physical-device behavior.

# Interpolate action placement and state — 30 September 2026

Desktop Key positions actions now read Reset, Undo, Redo, +, Interpolate. The orange Interpolate action sits slightly farther left on mobile Expert while High detail and Compute retain their positions. Starting endpoint selection darkens the button; selecting two endpoints changes its label to Apply and darkens it further. Its 44 px height and fixed width prevent the row from jumping. The one-line guide and card markers remain visible during selection.

Focused position/history tests passed 9/9; JavaScript syntax, whitespace and offline iPhone asset preparation passed. Browser checks at 320, 337, 393, 427, 507, 781, 820, 860 and 1280 CSS px found no horizontal overflow. At 393, 781, 820, 860 and 1280 px, button and first-card document positions were unchanged while entering selection and choosing A/D. Applying A/D returned to the normal button state and began computing the intervening slices. Mobile → desktop → mobile resizing preserved action order and button location. No page errors were observed. This is browser emulation, not physical-device testing.

# Two-endpoint Key Positions interpolation — 30 September 2026

Base: `b5c547a40e7c1ebfcca2e9ae3972f2d5c52c69bd`. Current intent: on mobile Expert and desktop Key positions, Interpolate replaces only the intervening cards' z settings with equal steps between two selected endpoint cards, keeps endpoints and the physical Image plane fixed, computes the affected optical slices, and records one reversible position edit. The prior divider becomes a one-line selection/error message without moving the action row or cards. At 320 px, the title wraps within its existing 44 px row.

Focused state/history tests passed 9/9; the full source suite passed 131/131. Offline iPhone asset preparation succeeded. Browser checks at 320, 337, 393, 427, 507, 781, 820, 860, 1280 and 1920 CSS px found the Interpolate, High detail and Compute actions aligned at the same row height, no horizontal overflow, and no card displacement when the selection message replaces the divider. Selecting A and D changed B/C to 150/300 mm; an adjacent-card error left settings unchanged. At 393 px, both affected slices finished a real Preview calculation and showed their new z values, then Undo restored Mask/Aperture and Redo restored the interpolated positions. At desktop 1280 px, a six-card A–F sequence preserved E/F when interpolating A–D in reverse selection order. Emulated touch taps also completed the A–D flow at 393 px. No page errors. Browser emulation does not establish physical-device touch behavior.

# Per-card Key Positions actions — 29 September 2026

Base: `6551bee2b167b82a0028b3ecff653e96ef0319a4`. Each card now has an aligned minus and plus action on desktop and mobile. Minus removes that card and renumbers the remaining cards in display order. Plus inserts an independent copy immediately after the chosen card, retains its plane, z and cached picture, and selects the copy. Both edits remain undoable and redoable; renamed cards get matching controls and canvas IDs.

Focused state/history tests passed 8/8. Browser interactions passed at 320, 337, 393, 428, 507, 1280 and 1920 CSS px: middle insertion/removal, sequential labels, custom z copying, undo/redo, clearing all cards and adding again, equal action alignment, and no horizontal overflow. A cached Mask image painted identically on the copied card at 393 and 1280 px. These are browser checks, not physical-device testing.

# Desktop and mobile control grouping — 29 September 2026

Base: `6c47dc2ec0771410c0b335a629d2acdc32bda6bc`. Desktop Key positions now orders Reset, Undo, Add, Redo on the left, with equal 44 px action heights and the Compute controls aligned at the right edge. Mobile Expert connects the tuning strip and Option row in one white section, then separates the Key Positions heading with a compact line. Key Positions and Intensity titles are both 20 px. The wave cursor keeps its draggable hit area and dashed line without the large top cap.

Browser checks at 320, 337, 393, 416, 507 and 1280 CSS px found no horizontal overflow. Desktop Add created four views and Undo restored four; mobile Add created two and Undo restored four, including after a desktop-to-mobile resize. No page errors. The complete source suite passed 129/129; offline iPhone asset preparation passed. Browser emulation does not certify physical touch hardware.

# Mobile Expert tuning layout and settings — 28 September 2026

Base: `f7d2d81253b9fcbcc2db12c9bdc126351eca56e4`. The five latest phone annotations are implemented in the authored `dist/` source.

- Expert places the named-plane selector beside a shorter tuning strip. At 507 CSS px the strip is 328 px within a 458 px row; at 320 px it is 159 px within a 271 px row. Standard still uses its entire 458 px tuning row at 507 px.
- Positions, Reset, Undo, Redo and the numeric z readout occupy one 44 px row. + Panels, High detail and Compute occupy the next. The history buttons use mirrored semicircular SVG arrows with 44 px-high click targets. At 320 CSS px, the full `450.123 mm` readout remains visible. No horizontal document overflow was observed at 507, 432, 393, 350, 337 or 320 CSS px.
- General Settings includes a collapsed Position tuning section for slow drag (0.5×/1×/2×), fast drag (0.5×/1×/1.5×) and glide (off/short/default). The same values apply to Standard and Expert; they are included in native experiment snapshots. Model tests verify both speed adjustments and disabling glide.
- In the browser, a tuned strip drag changed D from 200 to 427.507 mm; one Undo restored 200 mm. Compute kept the action row and card grid at document y=441 and y=493 px. Desktop at 1280 px kept its original position controls. No browser warnings or errors appeared. These are browser viewport checks, not physical-phone touch certification.
- Full source suite: **128/128 passed**. Offline iPhone asset preparation and whitespace checks passed. Local proof: `.sites-runtime/mobile-tuning-expert-507.png` (not deployed).

# Mobile Expert Undo/Redo verification — 28 September 2026

Base: `0b31616bead417a1c8326f7694eb9b6d8ecddb23`. This update adds Undo and Redo to the Expert position action area and slightly reduces the High detail switch.

- At 432 and 393 CSS px, + Panels, Reset, Undo, Redo, High detail and Compute share one 44 px-high aligned row. At 367, 350, 337 and 320 CSS px, the controls use two 44 px rows to preserve full-size Undo/Redo touch targets. No tested width overflowed horizontally. High detail retains a 44 px label target while the visual switch is 28 × 16 px.
- Browser actions: numeric edit 450 → 449.123 mm, Undo → 450, Redo → 449.123; add A–F, Undo A–D, Redo A–F; Reset A–D, Undo A–F; remove A, Undo restores A. A new position edit cleared the Redo branch. All panel canvas IDs remained correct.
- Actual beam-marker drag moved D from 450 to 354.878 mm; a single Undo restored 450 and disabled further Undo, then Redo restored 354.878. Actual relative-strip drag with short coasting moved D from 250.001 to 355.493 mm; a single Undo restored 250.001, and Redo restored 355.493. Drag and coast share one history entry. Calculations themselves are not history steps.
- Compute → Cancel → Compute kept the action area 44 px high and the card grid at document y=493 px. Desktop at 1280 CSS px retained Key positions and hid the mobile actions. The final interaction sequence showed no browser errors or warnings.
- The complete source suite passed 127/127 after the main implementation. Following the drag/coast grouping fix, all 17 focused gesture/history/drag tests passed; offline iPhone asset preparation and whitespace checks passed. Physical iPhone gestures and installation were not tested.
- Local visual captures: `.sites-runtime/mobile-history-432.png` and `.sites-runtime/mobile-history-320.png` (excluded from deployment).

# Mobile compact layout verification — 28 September 2026

Base: `4bb74f9e7eaa6aaf5dcabc4be884da6145d82e87`. Covers the previous 11 mobile annotations plus removal of the Contact / Privacy page footer.

- Both modes: removed accumulated navigation/workspace padding. The tuning strip to Position / Positions row gap is now 8.7 CSS px (previously 36.7 px). Expert action rows are separated by 8 px; card title-to-image gap is 4 px; cards-to-wave section gap is 12 px. Spacing is owned in one mobile stylesheet with 4 / 8 / 12 px tokens.
- Labels and actions: Preset, Position, + Panels and direct Reset. Expert High detail stays beside Compute. Undo is available in General, so changing its visibility cannot insert another toolbar row.
- Settings menu has only General and About. Components is inside General. Contact and Privacy policy are in About; the mobile page footer is gone. Both dialogs and component access were checked.
- Browser geometry checked at 320, 337, 367 and 393 CSS px in Standard and Expert, including a 450.123 mm entry: no document horizontal overflow, stable 44 px action rows and no button wrapping. Desktop at 1280 px retains Key positions, sidebar contact, original controls and no horizontal overflow.
- Verified add -> reset -> undo restores A–F with correct canvas identities, then Reset returns A–D. An old cached dependency could allocate duplicate panel identities; updated the dependency URLs together. Clearing selection now updates the plane badge after the selection label is cleared, avoiding a stale letter.
- A changed-position Expert calculation changed Compute to Cancel and back without displacement: heading 95.99 px high, grid document y=492.08 px and first canvas y=531.85 px throughout.
- Marker value visibility follows tuning drag, coast and keyboard activity. Interaction tests cover start, release, coast completion, interruption, key release and blur. This does not certify physical iPhone touch feel; numerical tuning gains are unchanged.
- Full existing suite: 124/124 passed in 129.8 s. After dependency/selection cleanup, all 20 focused position, reference, quality and tuning tests passed, including the new production module-graph identity regression. Offline iPhone asset preparation and whitespace checks passed. Native device installation was not changed.
- Inspected final Standard and Expert browser screenshots. Local proof images: `.sites-runtime/mobile-compact-standard.png` and `.sites-runtime/mobile-compact-expert.png` (not deployed). Earlier console errors from the stale module identity case predate the fix; the verified add/reset/undo/compute/cancel sequence produced no new errors.

# Current verification — 27 September 2026, expandable positions and projection sampling

**100/100 automated checks passed** (`node --test tests/*.test.mjs`, 167.0 s on this Mac), with no skips or cancellations. Syntax and whitespace checks passed. MATLAB source and the underlying XY optical operators were not changed.

- Desktop adds four positions per click; mobile adds two. Verified 4→8→12→16 desktop and 4→6→8→12 mobile, selection, duplicate-result reuse, remove/Undo, Default positions/Undo, and automatic editor collapse after Compute all slices. Unit tests also cover identifiers beyond Z and reject obsolete asynchronous results after replacement/Undo.
- The retained-result lookup reuses identical displayed fields after LRU eviction; fixed-image preview has independent retention. New copies share immutable arrays, not mutable position state. The unused-result cache remains bounded; offscreen canvases render on approach and observers detach when removed.
- Position display/manual movement uses 1 µm. Browser test: changing reduction to 3 displayed Image = 466.667 mm; to 3.5 displayed 457.143 mm. Compute retained the `image` attachment; +1 µm displayed 457.144 mm; Reset offset restored the exact attachment. Model tests verify full-precision geometry and cache identity survive display formatting.
- Actual browser viewports: 1512×900, 1319×836, 995×836, 430×932, 390×844, 320×740 and 844×390 landscape. No horizontal page overflow; the whole mobile beam fits. Resizing retained all eight test positions. At 1319 px, eight canvases were equal 258 px squares. Source and grating-mask inspectors fit within the same 541 px panel height with no inner scrollbar. Mobile deletion, Undo and computation worked at 320 px; six views survived collapse. These are browser viewport tests, not physical-device certification.
- The repeated beam summary and inspector subtitle are removed. Parameter labels, values/units and slider tracks align. Mobile touch targets remain at least 44 px for action controls. A render-before-view-change fix prevents null-canvas errors when adding a mobile group; final flows produced no new JavaScript errors.
- Fine full-path sampling is 246 axial planes for the default geometry (previously 205). Additional samples are local to mask exit/focus; transverse output-cut spacing is unchanged while support expands up to 3×, capped at the input Nyquist bound. No global FFT-grid increase. Independent full-2D LCT comparisons validate both original and added output cuts below 1e-11 relative error. MATLAB comparisons remain below 1e-6 at the original physical coordinates. Fresh Fine XY comparisons validate cached cuts below 1e-10 after physical-coordinate resampling.
- At the default z=300 mm plane, the expanded-window endpoint is approximately 0.039% (XZ) / 0.030% (YZ) of peak, versus approximately 4% at the former window boundary. The expanded endpoints lie outside the default plotted ±7 mm window. The interpolation is bounded and nonnegative, keeps exact computed planes, and preserves Mask/Aperture discontinuities. Phase-only lens planes no longer force an artificial intensity hold.
- Same-machine timing sample, 256 grid / 7 source bins: previous path 106.46 s; expanded/refined path 102.93 s. Other numerical jobs were running, so this establishes comparable cost, not a speedup guarantee. Fine sources and all optical grids remain unchanged.
- All five preset caches have current engine hashes and full-precision lossless arrays. XY arrays are byte-for-byte equivalent as serialized to the verified previous fields. Only source-verified unchanged fields were reused. Default/annular/dipole assets grew from roughly 9–10 MB to 13–14 MB; coherent examples are 17–18 MB. Only the selected preset is loaded. Runtime cache-button behavior, initial Fine display, XZ/YZ switching and preset switching were checked.

Independent Fine midplane validation (default, annular, dipole; XZ and YZ; six uncached positions per preset, 36 comparisons) improved every sampled case. Mean relative error of the locally normalized displayed cut fell from 59.2% to 6.7%; default-only mean is 3.0%. Half-maximum full-width disagreement was at most 3.8%. The worst annular XZ interpolation case remains 21.5% in normalized profile error, so this overview is not a substitute for a directly computed XY slice when examining narrow fringes. Exact sampled cuts and Compute slice retain the numerical calculation. Reproduction: `node scripts/validate-projection-display.mjs`; results go to `.sites-runtime/projection-validation.json`.

Proof captures are in `.sites-runtime/desktop-projection-final.png`, `desktop-groups-final.png`, and `mobile-groups-final.png` (local QA artifacts, excluded from deployment).

# Previous verification — 27 September 2026, compact controls and continuous illumination

**92/92 tests passed** (`node --test tests/*.test.mjs`, 165.0 s on this Mac), with zero skips or cancellations. Syntax and whitespace checks passed. No MATLAB source was changed.

- Circular/annular illumination now uses continuous exact source boundaries. Tests cover an independent closed-form on-axis integral, independent polar source quadrature, integrated power before the condenser (error < 1e-4), transverse symmetry, and off-grid cached annular cuts (normalized maximum error < 0.04 at five early-z positions). These validate the implemented scalar emitter model, not a real optical instrument.
- All five Fine preset assets and the legacy default wave asset match the updated engine and parameter keys. The full path has 205 z planes. Reference slices and illumination columns were recomputed; unchanged projection columns were reused only after source/parameter/provenance checks. Fresh Fine 2D calculations before, at and after the projection pupil match cached central cuts below 1e-12, including the local dense pupil evaluation.
- Projection MATLAB comparisons retain the original strict tolerance. Two historical illumination-screen fixtures represent the replaced raster-source approximation; they are explicitly excluded from screen equality and replaced by the independent analytic/quadrature checks. Their axes and projection-pupil fields are still checked. See MATLAB_PARITY.md.
- Desktop/browser sizes: actual 995, 1319 and 1512 CSS pixels. Mobile: 320, 390 and 430 portrait, 844 × 390 landscape. No document horizontal overflow. At 995 px, all four image canvases were equal 410.60 px squares. Portrait Key positions has two columns; landscape has four. These are browser emulations, not physical phone certification.
- At 995 px, switching the long Source pupil inspector (874 px content in a 579 px scroll area) to Lens 1 left the workspace height at 580.5 px and Key positions at document y = 686.5 px. All source controls remain accessible by scrolling inside the inspector. Preset/Reset occupy the beam toolbar; ray controls work inside Settings.
- Mobile Key positions shows A–D under the beam. Compute all slices commits fine offsets before collapsing edit controls. Verified cached batches and a real Fine point-source batch with A = 0.005 mm: all four finished, no queued/error states remained, the editor stayed hidden, and reopening retained the offset. A long multi-emitter batch was also cancelled successfully. The narrow-screen controls retain 44 px main touch targets; the fine numeric entry no longer overlaps its slider.
- The fixed Image thumbnail stayed unchanged when observation D moved to the mask. Fit/2×/4× and Save image are available in the Image inspector. Save PNG produced a valid 960 × 960 RGBA image. No email was sent. The annular preset loaded its matching cached ring, image and full-path wave.
- Wave canvas defaults to a complete dark rectangle; Show calculation window toggles the optional grey support indication. XZ/YZ, components, yellow/blue stages and physical position markers remain. The ±7 mm labels are removed. Final browser console contained no application warnings or errors.

Screenshots are retained locally in `.sites-runtime/desktop-wave-verified.png` and `.sites-runtime/mobile-key-positions-verified.png`.

The following records describe earlier revisions, including superseded labels and numerical approximations.

---

# Current verification — 27 September 2026

**87/87 tests pass** (`npm test`, 90.6 seconds on this Mac). This includes fresh Fine comparisons against the original wave cache, MATLAB parity fixtures, independent DFT/Gaussian checks, numerical guards, observation lifecycle/queue tests, and new preset/dense-pupil checks. No MATLAB code was changed.

New checks verify all five shipped presets contain four valid Fine XY fields and complete XZ/YZ columns, match their parameter/version keys, and reject mismatches. The generation manifest matches the current engine hash. Dense pupil evaluation agrees with an independently padded FFT at matching coordinates (maximum relative error below 1e-8). Fast dense wave cuts agree with the full dense pupil below 1e-9, including off-axis source weights and annular blocking. Display interpolation is bounded, nonnegative, exact at stored samples, and does not mutate raw arrays. Coincident A–D markers remain below the beam without focal-label conflicts.

Browser checks in the Codex in-app browser used actual CSS widths of 320, 390, 995, and 1319 pixels, plus an 844 × 390 landscape phone layout. No page-level horizontal overflow was found. The 995-pixel desktop has four equal 412-pixel square images in two columns. Portrait mobile has equal square images in two columns; landscape mobile shows four equal squares across the available width. These are emulated sizes, not physical iPhone/Android certification.

Verified flows: initial Fine cached fields; all five presets including rapid switching; desktop select/deselect by Escape and clicking the Key positions heading/blank area; Delete and default-position restoration; a real C-position calculation at Lens 1 while the other results remain unchanged; mobile Edit with disabled controls before tile selection; independent B-position editing and cached batch calculation; local Reset retaining the dipole preset; top Reset restoring Default/Explore with Fine tuning collapsed; Send preview; optional profile; smoothing toggle; Settings; and resizing between desktop and phone without duplicated controls. No application warnings/errors were observed in the browser logs. Native sharing was opened but no email was sent. Existing snapping/state tests pass; direct hardware touch/drag was not newly certified.

A point-source Fine benchmark measured about 268 ms for the original full XY routine plus 134 ms for the dense pupil on this Mac. Multi-source work scales with emitter count and remains slower; this is not a guaranteed speed for phones. Default presets avoid that computation by loading their precomputed fields. The new pupil spacing is about 32.23 µm across the 8.25 mm default window, versus 228.13 µm previously. Interpolation is a display improvement, not an additional physical accuracy claim.

The sections below are historical verification records and may describe earlier UI labels/layouts.

---

## 2026-09-27 — reference preset and compact wave controls

Desktop uses one Explore workspace with Reference positions and one-step Undo. The preset restores A Source / B Mask / C Aperture plane / D Image Plane, follows current geometry, resets offsets, retains optical parameters and reuses matching slice caches. Restored and added cards share a single identity sequence; replaced workers cannot attach to them. All four default views display intensity. Source distribution and Mask/Aperture openings remain available in Settings for exact, current reference planes; opening modes are labelled and switch back to intensity when moved. Enlarged views follow the selected display mode; intensity profiles are disabled for opening/distribution displays.

Both layouts use a 3 px section separator and Compute full path (Compute near mask for that selected region). Desktop Compute all slices and the wave action are 176 x 44 px and vertically aligned. The desktop Image symbol is a white screen. Mobile keeps Explore / Key positions, folds fine tuning by default with its 44 px touch area, removes numeric headings and captions, and uses 24 px titles with a 6 px image gap. Mobile Region and all wave settings are in overall Settings; window metadata is retained under Calculation details. Mobile Key positions and wave actions are 150 x 44 px, aligned at the right edge, including at 320 px.

Verification:
- 77 automated checks passed, including three new reference-preset tests, optical benchmarks against MATLAB reference cuts, cache integrity, view lifecycle, overlays and interpolation. The expensive fresh Fine cache recomputation was excluded because the optical engine and cached data are unchanged. Ten focused lifecycle/preset checks passed again after consolidating the shared position-identity module. Syntax and diff whitespace checks passed.
- Desktop browser: removed B, moved D to Lens 1 + 0.5 micrometres, restored references from valid cache, then Undo restored A/C/D and D = 300.0005 mm. Restoring during a running batch cancelled the old positional work. Removing all four produced a functional empty state; Reference positions restored all four. Repeated restore/delete/add kept unique card identities and correct order.
- Desktop browser: a real Preview Compute all slices batch finished with four current results and no queued/stale states. Source distribution, Mask Opening and Aperture Opening were verified in the merged grid. Fine tuning a Mask view removed its Opening label and selected intensity. Fixed Image symbol has no embedded image thumbnail.
- Responsive browser widths 320, 390, 482, 844 landscape, 1024, 1280 and 1440: no horizontal overflow. Mobile Key positions and Explore both checked. Desktop cards remain square with aligned rows; both primary actions match size and right edge. Mobile headings have no numbers and no captions under images; Fine tuning stays collapsed with 44 px hit area. Wave Region exists only inside Settings on mobile and remains beside the wave on desktop.
- Mobile Settings changes update the wave action to Compute near mask, preserve values across layout changes and route the computation correctly. Reset during wave work cancelled it and restored default Full path / Fine cache. This was a cancellation/reset test, not a completed near-wave benchmark.
- Initial preview exposed a moved-control initialization error, corrected before final verification. No new warning/error messages appeared in subsequent interactions. Testing uses responsive browser viewports, not physical phones.

## 2026-09-27 — unified settings, illumination terminology and aligned comparison views

Desktop Reset now sits beside Experiment. Settings replaces the header overflow menu and contains shared slice detail/brightness/reference-display controls, separate wave controls and About. Region and XZ/YZ stay beside the wave. Fixed reference Compute slice and Update wave share a 140 × 44 px action column. Explore and Fixed reference views share the same square image layout; deleting cards no longer enlarges the remaining cards, and new cards retain insertion order. Phone navigation stays compact and Fine tuning follows its slider without extra spacing.

Terminology distinguishes Source shape (illumination pupil) from Projection aperture / Aperture shape. The fixed third reference and observation location are Aperture plane. Annular illumination now sets an annular source with a circular projection aperture; the two shapes remain independent. Source painting uses Light/Dark, aperture painting uses Transmit/Block. Numerical engine and default Fine data are unchanged.

Verification:
- 32 automated checks passed: 28 observation lifecycle, geometry, palette, component-overlay and new experiment/label tests, plus 4 cache integrity/parameter matching tests. Initial failures were the two intentionally changed display-label expectations; these were updated while retaining the numerical array/axis comparisons. Syntax and whitespace checks passed.
- Browser: Annular illumination selects Source shape = Annular and Aperture shape = Circular; changing the aperture does not alter the source. A real Standard annular-source calculation completed (2.8 s), displaying a ring source. The default circular wave cache is rejected for that changed source.
- Browser: Settings retains shared slice brightness, separate wave brightness and display selections through desktop/mobile changes. About opens and returns to Settings. Reset restores defaults and the saved Fine cache. Main desktop views contain no duplicate brightness selector or Display settings disclosure.
- Desktop widths 1024, 1280 and 1440: Explore and Fixed images have matching x/width/height, square aspect ratio and matching 2/4-column breakpoints; approximate sides 431.28, 254.40 and 291.20 px respectively. Compute slice and Update wave have identical x/width/height at all three widths. No horizontal overflow.
- Browser: removing A/B then adding them back retains C/D/A/B order; existing and uncalculated image tops are exactly aligned (622 px in the measured viewport). Compute reuses matching cached slices and keeps all image tops aligned. There is no 7 px shift for new cards.
- Phone widths 320, 390, 482 and 844 landscape: no overflow in either view. Fine tuning starts collapsed; slider and summary retain 44 px touch areas, with zero extra gap. Reset stays in the header; phone overflow and local wave settings remain available. Fixed images retain the concise mobile captions.
- Browser console recorded no warning/error logs. Responsive tests use browser viewports, not physical phones. Screenshot capture in the in-app browser produced clipping/stitching artifacts at some desktop overrides; layout measurements and desktop dialog inspection were used alongside the clean normal-size phone screenshot. No optical engine or Fine cache recomputation was required.

## 2026-09-27 — complete reset and compact mobile references

A visible header Reset restarts the bench with all startup defaults, stops current work, resets browser-restored form values, and restores the default Fine wave cache. Beam region labels sit above the diagram; beam and wave region labels are bold. On mobile, Source/Mask/Pupil display selectors move into More options → Display settings, with the original controls and handlers retained. Completed timing/grid detail is available only in the settings disclosure. Active calculation progress, stale-result notices and reference calculation errors remain visible.

Verification:
- 24 existing observation lifecycle, geometry, palette and overlay checks passed. JavaScript syntax and whitespace checks passed. Optical equations and saved Fine data were unchanged.
- Browser mobile Reset: changed all three reference display selectors, detail, brightness, experiment, wave region and opened tuning; Reset restored circular pupil, Standard XY detail, all default display modes, Image at 450 mm, four positions, zero offset, collapsed tuning and the saved 512 × 512 / 445-emitter Fine wave.
- Browser desktop Reset: changed aperture, ray visibility, wave detail/section/brightness/components, comparison brightness and fine offset; deleted A and C, started the remaining two-view batch, then reset while computing. A–D returned, pending work was replaced by the startup calculation, and all controls returned to defaults.
- Responsive widths 320, 390, 482, 844 landscape, 1024 and 1440: no horizontal overflow; Reset is 44 px high and fits in the header; region labels precede the beam, position controls remain below it. Reference selects move back to desktop captions without duplicate IDs or lost handlers.
- At 320 px, mobile settings fit without internal horizontal overflow; selecting emitter weights updates the source image label. Changing detail shows Needs update; Update all views shows Calculating and progress, then hides completed timing/grid text.
- Screenshots reviewed for desktop and mobile. No browser warning/error logs were recorded. Tests used responsive browser viewports, not physical phones. Failure-message rendering was inspected in code; no artificial worker failure was injected.

## 2026-09-27 — batch observations, removable views and mobile sharing

Desktop now computes every retained exploration view with one action (selected view first, serial workers, identical-position cache reuse). Views have stable letters, separate remove controls, Delete/Backspace shortcuts, Undo, Add and a zero-view state. Fine tuning precedes the final position/action row. Mobile tuning starts collapsed and retains explicit disclosure state; mobile Compute updates only its selected view. Mobile wave height is 110–128 px (100 px landscape); optical data and Fine cache remain unchanged. Mobile observation metadata is hidden, Send prepares a 768×768 PNG, and Profile has a border. Desktop contact and shared brightness selection were added.

Verification:
- 70 distinct automated checks passed: 66 numerical, geometry, interpolation, observation lifecycle and sharing tests, plus 4 cache validation tests. The expensive fresh Fine cache recomputation was not repeated; neither numerical engine nor cache data changed. After final overlay edits the 24 affected observation/geometry checks were rerun and passed.
- Browser: one Compute completed three independent positions at 0, 200 and 240.0005 mm; selection remained C. During a Fine batch, deleting and restoring C reduced the original batch to A/B, left the restored C marked stale, and Cancel stopped the remaining batch without script errors.
- Browser: remove non-selected B preserves D selection; Undo restores B; removal down to zero disables controls and removes bench observation markers; Add starts a new view. Delete on a card removes it; Delete inside z input does not remove any card.
- Browser: mobile tuning starts collapsed, +0.5 µm remains indicated when collapsed, computation does not reopen it, and only the selected view becomes pending. Compute explicitly commits a typed position before starting.
- Browser: Profile opens with its calculated curve. Send prepares a complete 768×768 PNG and exposes Save PNG/native Share. The save action was invoked, but the in-app browser download bridge did not return a file event/path; actual destination file delivery and physical-phone native email sharing remain unverified. File-support detection, unsupported fallback, successful share, cancellation and errors are covered by an isolated test. No email was sent.
- Browser widths 320, 390, 430, 482, 844 landscape, 1024, 1280 and 1440: no horizontal overflow; action row below tuning; mobile action buttons have identical x/width/height. Desktop main and fine sliders have identical x/width. Desktop 1024 uses two columns; 1280/1440 use four. Phone wave height measured 110/117/128 px across portrait widths, 100 px landscape. Contact is hidden from the mobile footer.
- Visual screenshots reviewed for desktop and phone. Physical iOS/Android devices and 200% text zoom were not tested. Optical/default cached data are unchanged.

## 2026-09-27 — independent observation views and Fine tuning

Implemented on desktop and mobile: arbitrary-position Fine tuning (±100 µm, 0.5 µm steps, clipped at path ends), yellow illumination/blue projection in rays and XY/XZ/YZ intensity, and compact stale-result badges retaining the actual calculated z.
Desktop adds independent A–D views, a shared position editor, draggable/snapping screen and selectable position markers. Mobile keeps one observation image and visible Fine tuning. Fixed Image Plane remains unchanged.

Verification:
- 63 automated tests passed after the final functional edits: state isolation, stale/late result rejection, serial job replacement, bounded slice caching, physical snapping, all named/custom fine-tuning positions and boundaries, exact XY reference reuse, regional colour rendering, numerical and MATLAB parity, display interpolation and responsive geometry.
- The separate fresh Fine cache comparison passed (96.6 s): independently recomputed cuts before/at/after the pupil agree with the existing cached data. Optical engine and cache data were not changed.
- Browser: dragged the observation handle to Mask and verified exact 200 mm snap; keyboard movement worked. At 1024 px, desktop also retains the draggable handle.
- Browser: D calculated at 200.0005 mm and B at 199.9995 mm while C remained selected at 400 mm. Results returned to D and B; C's view/profile did not change. Re-selecting D restored its +0.5 µm tuning offset, and Reset offset returned its target to 200 mm.
- Browser: fixed Image Plane remained z = 450 mm after moving observation views.
- Responsive browser checks: widths 320, 390, 430, 844 landscape, 1024, 1280, 1440; no horizontal page overflow. Fine tuning visible at all widths. Four views on desktop, single view on mobile. Real physical phones were not available for testing.
- Browser screenshots verified warm illumination and blue projection; explicit asset versions avoid stale dependency colours after refresh.

# Test report — 25 September 2026

This is a chronological record. The final section describes the current release; earlier cache sampling and UI descriptions are historical.

## Numerical tests

27/27 passed with `npm test`. See `MATLAB_PARITY.md` for scenarios, tolerance, convergence results and limitations. MATLAB R2026a generated fresh wave-reference data during this update; reference fixtures are committed with their generator.

## Browser checks

Local HTTP preview in the Codex in-app browser. Checked real worker calculations, not mocked responses.

- Initial standard image calculation: passed.
- Full-path XZ preview: 128 grid, 25 emitters, 119 z planes; completed in about 27 seconds on this machine.
- Near-mask wave calculation: 256 grid, point source, 61 z planes; completed in about 7 seconds.
- Switching between XZ and YZ without recalculation: passed.
- XYZ log display and −120 to 0 dB legend: passed.
- Click near-mask plot midpoint → observation z = 200.1 mm → calculate XY slice: passed.
- Cancel 512-grid wave job → controls usable again: passed.
- Desktop 1440-pixel viewport: no page overflow; all four field canvases measured 220 × 220 CSS pixels.

- Real numeric input: 11 µm window with a 20 µm mask rejects the calculation; previous valid XY result remains visible. Reset restores working settings.
- Mobile 390 × 844 viewport: no page-level horizontal overflow; all four canvases measure 173 × 173 CSS pixels; controls and editor remain usable. The geometric bench scrolls horizontally inside its own panel.
- Custom source painting dialog: clear → apply → calculate gives zero transmitted light.
- Source weights, mask-exit intensity and shared log selectors: correct labels, no errors on zero fields.
- Browser console warnings/errors during these interactions: none observed.

A browser automation `fill` alone did not dispatch the committed numeric edit on this browser bridge. The test used a real ArrowUp edit before calculating; the settings and validation message then updated correctly.

Coverage is on this machine/browser. No claim is made of exhaustive cross-browser support or convergence for every possible optical configuration.

## Layout and precalculated startup update — 26 September 2026

31/31 automated tests passed (27 optical tests plus 4 cache regressions). The Fine asset was generated from the current engine: 512 grid, 25 emitters, 119 planes, both raw central cuts; generation took 338.3 seconds. The saved image-plane cuts agree with a fresh Fine calculation to relative error below 10^-12. Tests reject mismatching parameters, model versions and malformed assets, and check the numerical-engine hash.

Browser observations:

- Fresh startup displays “Fine · saved calculation · matches the current optics” before the ordinary XY calculation finishes, without clicking Update wave.
- Section order is bench, screen results, wave intensity; profile is initially closed.
- Profile opens with the current result and physical z, closes with Escape, and returns focus to its button.
- Changing the mask removes the cached wave. Reset restores it. Selecting Preview removes the Fine cache; selecting Fine restores it immediately.
- XZ/YZ switching retains the cached result. Seven component symbols line up with the physical path.
- 1440-pixel desktop and 390-pixel phone layouts have no page-level horizontal overflow. Mobile profile dialog fits within the viewport.
- Footer shows Chuang Lu and the exact mailto contact luchuangl@gmail.com.

The cache covers the default full path only. Changed optics and the near-mask region calculate on request, and Fine updates can take minutes. Cache transfer time depends on the connection; the asset is approximately 4.2 MB before HTTP compression.

Final UI checks: mobile profile axes remain readable after resizing; its Close button works. Update wave reuses the matching Fine cache without starting a long job. Clicking the midpoint of the full wave plot selects z = 235 mm and “Show this slice” starts that XY calculation. No browser console warnings or errors were observed.

## Annular pupil default — 26 September 2026

Startup and Reset now select the existing annular-pupil experiment, with inner/outer radius 0.65. Other experiments retain their previous settings. The saved Fine wave uses the same annular parameters. Its 33 columns at/after the pupil were recomputed; 86 upstream columns were reused only after verifying identical upstream parameters, coordinates, and engine hash (this forward model has no pupil feedback upstream). Fresh Fine calculations at z = 200, 300, 400 and 450 mm match both cached cuts to relative error below 10^-12. Full regeneration remains available through `scripts/precompute-wave.mjs`.

31/31 tests passed. A fresh browser page showed the annular experiment, pupil inspector and matching saved Fine wave. Changing to Circular and pressing Reset restored Annular with obstruction 0.65. No browser warnings or errors were observed.

## Fixed key planes and independent observation screen — 26 September 2026

34/34 automated tests passed. Three new regressions verify that moving the observation screen leaves Source, Mask, Pupil and the fixed Image arrays unchanged; defocus moves only the observation result; shared XY intensity reference stays at nominal focus; screen-only and combined calculations agree; progress completes and invalid z fails. The existing optical engine, MATLAB fixtures and precomputed Fine cache are unchanged.

Browser checks in the Codex in-app browser:
- Near-mask observation completed at z = 200.001 mm while the final Key planes plot remained Image plane at z = 450 mm. Its profile dialog identified Mask diffraction at the correct position.
- Through-focus preset completed at Preview detail with the observation at z = 450.025 mm and fixed Image at z = 450 mm; its profile identified Through focus.
- Reset restored the annular pupil and matching saved Fine wave.
- Desktop (1440 × 1000) and phone (390 × 844) layouts were visually inspected. The phone page had no page-level horizontal overflow; the optical bench retains its intentional internal horizontal scroll. The observation panel and profile dialog fit the phone width.
- Pupil preview now has one black plate with the actual white opening, plus explicit transmission/blocking labels. No overlapping gray mount.
- Previous results remain labeled while position/settings are pending. Focus offset controls are only shown for Image / through focus.

These are functional and regression checks, not a claim of convergence for all possible optical settings or exhaustive cross-browser compatibility.

## Full Fine cache, touch layout and fixed positions — 26 September 2026

**40/40 automated tests passed** with `npm test` (262.32 seconds). Fresh full Fine calculations at z = 200, 300, 400 and 450 mm match both cached cuts to relative error below 10^-12. Existing MATLAB XY and XZ/YZ fixture comparisons pass, as do the fixed-image, independent-screen, invalid-cache, propagation-cache and exact-center-cut regressions. `git diff --check` passed.

The current startup asset uses the highest exposed Fine settings: a 512 × 512 mask grid, 2× propagation padding, 25 × 25 source bins (445 weighted emitters for the default source), and 119 physical z positions. Both XZ and YZ cuts are saved. Every plane was regenerated with all 445 emitters; no old source-reduced columns were reused. Generation took 831.972 seconds and the JSON is 4,222,316 bytes before compression.

Exact calculation optimizations reuse immutable propagation kernels and Fourier transforms within a job, with a 128 MiB kernel-cache limit. LCT center cuts calculate the same bracketing rows/columns and interpolate intensity, matching the full two-dimensional transform; they do not reduce source or spatial sampling.

Browser checks on the local release assets in the Codex in-app browser:

- Fresh load displays the saved Fine path with 512 × 512, 445 emitters and 119 positions, without a wave calculation. Switching XZ/YZ and local/shared-log brightness retains the same cache. Update wave immediately reuses it.
- A 0.5 µm observation offset updates the screen to z = 450.0005 mm after Show slice. The fixed Image Plane remains at z = 450 mm and the Fine cache remains valid. Numerical regression tests separately compare the fixed arrays.
- Changing Annular to Circular invalidates the cached wave. Reset restores Annular and the matching Fine cache.
- Key positions contains four compact plots; the fourth is always Image Plane. Observation screen has a separate result, position controls and profile dialog. Wave intensity is the last section.
- The pupil inspector shows a single black plate and white transmitting opening with an explicit legend. The gray circular mount has been removed. The optical path and wave plot show component symbols and a linked observation marker.
- Desktop, 390 × 844 portrait, 320 × 568 narrow portrait and 844 × 390 landscape were checked. No page-level horizontal overflow was found; the bench intentionally scrolls inside its panel. Relevant controls have at least 44 CSS-pixel touch targets. A component selector avoids requiring taps on small optical symbols.
- At 200% text size in the 320-pixel layout, the component selector, plots and dialogs reflow without page overflow. The profile dialog remains scrollable, Escape closes it and focus returns to its opening button.
- A real near-mask Preview wave completed; wave arrow-key selection and Show this slice worked. Cancellation retains the previous result and enables the controls again.
- No browser console warnings or errors were observed in the final release-preview interactions after the new cache was available.

Phone sizes were emulated on this computer, not tested on physical iPhone/Android devices. Fine is the highest current application setting, not proof of convergence for every configuration; the scalar, ideal-lens model limitations still apply.

## Mobile view switch — 26 September 2026

This update changes presentation and navigation only; the optical engine and highest-Fine cache asset are unchanged. The four fixed-plane/observation regressions passed again, both edited JavaScript modules passed syntax checks, and `git diff --check` passed.

Browser checks on the final local assets:

- At 390 × 844 and 320 × 568, Explore any position is first and selected by default. Only its panel is visible. Tapping Fixed reference planes displays the existing four plots; inactive-panel controls are not visible or keyboard-focusable.
- The sliding thumb follows the selection. A horizontal drag on the switch and left/right keyboard navigation switch panels. Keyboard focus follows the selected tab.
- Display settings holds the single existing detail selector and brightness selector. Changing Preview and shared-log updates those controls and the summary; switching panels retains their values and calculations.
- Show slice completed at z = 200.001 mm while Image Plane remained at z = 450 mm and the highest-Fine wave cache remained valid.
- From Fixed reference planes, selecting a wave position and pressing Show this slice automatically opens Explore any position and calculates the requested observation.
- At 844 × 390, both modes still use the switch and the observation figure/control layout uses two columns. At 1280 × 900, both original desktop sections are visible, the switch is hidden, and detail/brightness return to their original locations without duplicate controls or tabpanel roles.
- At 320 pixels with 200% text, both labels wrap, tabs remain usable, and there is no page-level horizontal overflow. Normal mobile tab targets are at least 52 CSS pixels tall.
- No browser console warnings or errors were observed. Phone checks used emulated dimensions, not physical devices.

## Desktop switch and circular default — 26 September 2026

The sliding view selector now applies to every viewport, including desktop. The observation tab is first and selected on startup; Fixed reference planes shows Key positions. One panel remains visible when the viewport changes, and both share the same display controls. Startup and Reset now use Circular; the Annular preset still selects an annular opening with inner/outer radius 0.65.

The optical engine is unchanged. The 35 optical, MATLAB-parity, independent-screen and wave-cut regressions passed again. JavaScript syntax checks and `git diff --check` passed.

Browser checks:

- Desktop at 1280 pixels shows the switch. Clicking each tab changes the visible panel, and left/right keys move selection and focus.
- Resizing to 390-pixel portrait and back preserves the selected tab and keeps exactly one panel visible, with no page-level horizontal overflow.
- Selecting the Annular experiment shows Annular; Reset restores the Circular opening and circular experiment label.
- Show slice at z = 200.001 mm leaves the fixed Image Plane at z = 450 mm.

For the circular Fine cache, the 86 raw upstream columns are reused only after matching the engine hash, complete coordinates and all non-pupil parameters against the previous 512-grid, 445-emitter asset. This forward model has no pupil feedback upstream. All 33 positions at or after the pupil, plus the common intensity reference, are recalculated with all 445 emitters. A new v4 parameter key and asset filename prevent displaying the previous annular cache as circular.

The completed circular cache contains all 119 positions and both XZ/YZ cuts, uses 512 × 512 with 2× padding and 445 emitters, and is 4,181,732 bytes before compression. Updating it took 570.75 seconds. All five cache regressions passed, including independently recomputed full 2D Fine fields at z = 200, 300, 400 and 450 mm; relative cut errors remain below 10^-12 and the shared intensity references match. The four independent references now run in parallel, completing the cache suite in 97.19 seconds. Together with the 35 earlier regressions, **40/40 tests passed** for this release.

A fresh browser load selected Circular, showed the desktop switch, and displayed the matching saved Fine wave automatically. On desktop, Show this slice from the wave plot returned from Fixed reference planes to Explore any position. Reset restored Circular and its saved wave. The obsolete annular startup asset is no longer shipped.


## Smooth wave rendering — 26 September 2026

The prior renderer selected the nearest z column and stretched it horizontally. Its changing transverse calculation windows consequently had visible staircase boundaries. The new renderer interpolates raw intensity and the transverse mesh between calculated planes, then applies the selected linear/log scale. Two horizontal subpixel samples and fractional vertical coverage antialias the computational-window boundary. Thin component changes are not blended upstream. The canvas supports device pixel density up to 2×; labels and component positions stay in CSS coordinates. Narrow-screen axes now show only the start, 200 mm and endpoint labels to avoid overlap.

The seven new display tests cover all 119 exact cached planes for both XZ/YZ, physical coordinate interpolation, no source-data mutation, local/shared normalization, bounded interpolation, thin-component transitions, fractional edge coverage and dark/single-plane cases. Together with the 13 existing wave regressions (including MATLAB XZ/YZ comparisons), **20/20 tests passed**. The numerical engine, default parameters and highest-Fine circular cache are unchanged; the expensive full-cache reference suite was not repeated for this display-only update.

Browser checks on the final local assets in the Codex in-app browser:

- Desktop full-path XZ and YZ show continuous window edges. Local linear and shared logarithmic brightness render correctly.
- Fresh load and Reset retain Circular and immediately display the saved Fine calculation: 512 × 512, 445 emitters and 119 z planes.
- At 390 × 844 and 320 × 568, the wave plot fits the viewport with no page-level horizontal overflow. The final narrow axis labels do not overlap, and coordinate-label backgrounds fit their text. These are emulated sizes, not physical phone tests.
- Selecting z = 0 with the wave plot and confirming Show this slice updates the independent observation to Source plane, while retaining the saved Fine wave.
- No browser warnings or errors were observed.

A local Node timing check of the pure renderer took 25 ms at 340 × 240, 34 ms at 1164 × 240 and 81 ms at 2328 × 480 pixels. These are developer-machine measurements, not phone performance guarantees. Smoother rendering does not claim additional numerical precision or convergence between saved planes.

## Fit-to-width mobile bench — 26 September 2026

The complete beam path now fits the phone width without an internal horizontal scroller. The mobile layout uses a compact schematic with More rays, a single header, a component summary and an on-demand bottom sheet. Desktop retains its ray controls and side inspector. The observation image is visible much earlier on the page. Numerical routines, defaults and the highest-Fine wave cache are unchanged.

**14/14 targeted automated tests passed**: three compact-bench regressions, four fixed-plane/independent-observation regressions and seven smooth-wave rendering regressions. The compact tests include extreme geometry, proportional z coordinates, all seven components within bounds, selection/accessibility labels, finite output, ray modes and unchanged input parameters. The expensive full-cache numerical suite was not repeated for this presentation-only update.

Browser checks in the Codex in-app browser:

- Emulated 320 × 568, 390 × 844, 430 × 932, 844 × 390 and desktop 1280 × 900: no page-level horizontal overflow; complete optical path fits. Landscape uses the same compact schematic. The 390-pixel first viewport includes the whole beam path and observation image.
- All seven component choices open the matching settings. Buttons in the sheet have at least 44-pixel targets. The 320-pixel sheet scrolls vertically and stays within the viewport.
- Annular selection and a real numeric edit from NA 0.15 to 0.16 persist when resizing to desktop. The sheet closes and the same inspector returns to the sidebar. Closing the mobile sheet with Escape restores focus to the summary.
- Nested Freeform pupil editing opens, Clear and Apply return to the component sheet, and Done returns to the page.
- Show slice completed at z = 200.001 mm, while Key positions retained Image Plane at z = 450 mm. The two tabs remain usable.
- About the model opens from More. Reset closes the menu, restores Circular and immediately displays the saved Fine wave (512 × 512, 445 emitters, 119 z planes).
- No browser warnings or errors were observed.

These are desktop browser simulations of phone dimensions, not physical iPhone/Android tests. Main-page contact details were removed; this update does not change the wave component overlay or optical precision.

## Controls below the beam and in-plot components — 26 September 2026

The shared view switch now sits immediately below the beam on desktop and phone. Observation position controls follow it and hide in Key positions mode. Components opens the existing mobile sheet from above the beam. Fine focus expands on demand; the profile is in the observation options menu. XZ/YZ have direct buttons. Normal cache/detail text and instructions are inside Wave settings; pending, progress, cancellation and error notices stay visible.

Wave components are now a transparent SVG overlay on the intensity canvas, centered on the optical axis at the displayed calculation's z positions. The overlay has no pointer hit area and can be hidden. Image is a fixed symbol; the movable cursor uses a different colour/dashed line. Near-mask plots filter out components outside the displayed interval. The numerical engine and highest-Fine circular cache are unchanged.

**17/17 targeted tests passed**: three new wave-overlay tests plus the existing compact-bench, independent-observation and smooth-wave-display regressions. Overlay tests cover physical coordinates at five widths and extreme focal-length/reduction settings, spacing, finite values, no mutation, near-mask clipping, sparse labels, annular obstruction and the fixed Image symbol. Syntax and whitespace checks passed. The expensive cache recalculation suite was not rerun for this UI change.

Browser verification on local release assets:

- 320 × 568, 390 × 844, 430 × 932, 844 × 390 and 1280 × 900 layouts: the path fits, with no page-level horizontal overflow. The switch sits directly under it on desktop and phone. XZ/YZ and settings controls have 44-pixel touch targets.
- Explore/Key positions clicks and keyboard switching show the correct panel and hide/show observation controls. A 0.5 µm focus offset survives resizing from desktop to phone.
- Moving the position slider to 0 updates the beam marker while the old figure remains labeled z = 450 mm and a pending notice appears. Show slice then displays z = 0 mm; the fixed Image remains z = 450 mm.
- Observation options opens the profile. Escape closes it and restores focus to the options button. The normal page has no standalone profile link.
- Wave settings reveals the full Fine/cache information. Show components hides/restores the SVG overlay. Switching to Near mask selects XZ and clears stale full-path symbols.
- Cancellation makes Update wave usable again and shows a short notice. A real single-point-source, Preview near-mask calculation completed in 1.5 seconds, displaying only Mask. Clicking the midpoint selected z = 200.1 mm; Show this slice displayed that observation while fixed Image remained z = 450 mm.
- An invalid 11 µm window with the default mask produced the visible wave error asking for a larger window. Reset restored Circular and the matching highest-Fine cache immediately.

Responsive checks use desktop browser viewport emulation, not physical phone hardware. Component sizes are schematic; z positions are physical. No additional numerical accuracy is claimed by adding the overlay.


## Compact wave plot height — 26 September 2026

Reduced the wave canvas from 240 to 160 CSS pixels on desktop and mobile. Component symbols shrink vertically by the same ratio, with staggered desktop labels below the symbols. The canvas, component overlay and observation cursor retain matching heights. Physical coordinate ranges, wave data, numerical routines and the highest-Fine circular cache are unchanged.

All 10 targeted wave-overlay and wave-display regressions passed. Existing overlay coverage now checks both 160- and 240-pixel heights and label clearance. Browser checks at emulated 320 × 568, 390 × 844 and desktop 1280 × 900 confirm no horizontal page overflow, readable symbols/labels, matching 160-pixel layers and working XZ/YZ switching. Clicking the plot midpoint at 320 pixels selected z = 235 mm correctly. The saved Fine calculation still loads at startup. No browser warnings or errors were observed. These checks use browser viewport simulation, not physical phones; the unchanged full numerical cache suite was not rerun.


## Aligned diagrams, region labels and observation tools — 26 September 2026

The desktop bench now draws in responsive coordinates, filling the available left column without horizontally stretching its component symbols. Wave intensity uses the same column, end insets and physical z domain; its controls occupy the right sidebar. Both diagrams label Illumination (source to mask) and Projection (mask to fixed image). The wave labels use displayed calculation geometry, and hide for unavailable or near-mask views.

Mobile position controls have equal widths and 44-pixel heights, with compact plane names and a separate z-unit label. Display settings moves into a dialog reached through the main menu. Observation is a left-aligned square with its calculated-position metadata, enlargement and profile actions on the right. Desktop Fine focus is expanded; away from image/focus it is disabled and offers Return to image, preventing an unexpected jump. Mobile wave controls share a baseline, and the transverse ± labels are omitted. The numerical engine and highest-Fine circular cache are unchanged.

**20/20 targeted tests passed** across path layout, compact bench, wave components, smooth wave display and fixed/independent views. New coverage verifies physical component coordinates at four desktop widths and extreme geometry, fixed region boundaries despite defocus, ray modes, no mutation and a movable marker independent of fixed components. Syntax and whitespace checks passed.

Browser verification used the in-app browser at widths 320, 390, 430, 844 (landscape), 1280 and 1440. No page-level horizontal overflow was found. Mobile controls measured equal widths (90px at width 320; 112px at width 390) and at least 44px height. The wave canvas stays 160px high. Desktop component alignment was checked to subpixel display rounding.

Verified settings dialog opening/closing and focus return, settings retention across desktop/mobile, independent observation at z = 200.001 mm, enlarged image and profile metadata matching that calculation, Escape dismissal, fixed Image Plane remaining at 450mm, and 0.5µm focus adjustment selecting z = 450.0005mm. Changing condenser focal length to 105mm moved mask/image references to 210/460mm and cleared the outdated wave; returning to Circular restored the Fine cache. XZ/YZ switching, shared-log display, component visibility and full/near selection also worked. No application warnings or errors were observed.

These are browser-size simulations, not physical iPhone/Android tests. Interaction flows were exercised with keyboard and native select actions; automated pointer clicks in this in-app browser were unreliable and are not claimed as verified touch tests. The unchanged expensive numerical-cache suite was not rerun.

## Unified controls and mobile modes — 27 September 2026

Numbers and unit suffixes now share a single bordered field in the component inspector and Fine tuning. Mobile component controls use aligned value fields, 16px numeric text, compact previews and retained touch areas. The redundant Components toolbar is removed; beam elements and Settings → Edit components open the shared sheet. Closing the sheet or image-sharing dialog resolves a visible focus target even after the SVG is redrawn.

Mobile tabs are Standard Mode and Expert Mode, with the same numerical quality and retained observation state. XZ/YZ sits immediately before Compute full path; small layouts put the title above that action row. Cancel remains below the compute button. Desktop action right edges remain aligned. With no selected observation, the position selector shows Select a position and z is empty/disabled instead of displaying contradictory old values. Reset scopes are described in Settings and accessible button labels.

Validation:

- 25/25 targeted automated tests passed: observation lifecycle/sharing, independent positions, reference restoration, extra position groups and compact beam geometry. JavaScript syntax and whitespace checks passed.
- Chrome responsive viewport checks: 320×740, 390×844, 430×932, 638×836, 844×390, 995×766 and 1228×836. No page horizontal overflow was observed. Mask unit suffixes were contained in their borders at each compact size; the mobile number field outer height was 44px and its text 16px. All seven component panels remained accessible.
- XZ/YZ and Compute were verified left-to-right, with equal top and height at 320, 390, 995 and 1228px. At 1228px the compute right edge exactly matched Compute all slices. Preview calculation start/cancel did not disrupt their alignment.
- Settings → Components, beam → Components, close focus, fixed image → share → close, Standard/Expert switching, six/eight retained cards, and Compute all slices hiding mobile tuning were exercised. Real keyboard fine tuning changed 200mm to 199.999mm and 199.975mm. Deselecting cleared both position controls while keeping batch computation available.
- Reset restored Fine slice quality, 512 wave detail and the saved Fine path. XZ/YZ switched the displayed cached cut without a calculation. No browser warning/error logs were recorded.

These are desktop browser viewport simulations, not physical iOS/Android touch or software-keyboard tests. A browser zoom shortcut did not change the controlled viewport, so 200% browser zoom is not claimed as verified. The numerical engine and all preset cache assets are unchanged; the expensive numerical cache suite was not rerun for this interface revision.

## Action-local detail and compact controls — 27 September 2026

- Mobile Standard defaults to Fast (256 grid / 13 source bins); mobile Expert and desktop share the independent High detail default (512 / 25). Preferences survive mode changes, resizing and Preset selection; full Reset reloads defaults. Wave detail remains independent.
- Fine slices satisfy Fast requests without downgrading; physics and z must match. Batch requests snapshot quality. In-flight Fast results remain accepted after a UI toggle, but cannot replace a matching Fine result. Repeated positions share immutable results.
- Standard positions are collapsed by default under the coarse slider, with Compute slice / High detail above Send. Expert editing retains its controls and closes after Compute all slices. Hidden invalid fields open for validation; inadequate Fast sampling gives an actionable High detail notice and retains previous results.
- Wave title, XZ/YZ and compute share a row. Desktop source pupil uses a warm emitting pattern in a restrained mount; the independent projection aperture has a transparent opening. Numerical optics and wave caches are unchanged.
- 27 targeted tests passed: detail policies, cache hydration, lifecycle/cancellation, position groups, responsive beam geometry and screen/reference isolation. Syntax and whitespace checks passed.
- Browser QA: 320×740, 390×844, 638×836, 995×766, 1228×836; no horizontal page overflow and wave controls share a centerline. Checked Standard/Expert defaults and preference retention; 4/6/8 positions; cache-backed batch completion; Expert collapse; default/annular/dipole/filtering/diffraction preset loading; fresh Fast completion after enabling High detail mid-flight; fresh Fine result; cancellation retaining the old image; and an undersampled 2 µm grating at a 200 µm window producing the High detail notice. New QA tab console had no warnings/errors. These are browser viewport tests, not physical phone measurements.

### Bounded numerical / performance checks

- Fresh Fast image-plane calculation versus validated precomputed Fine image-plane cache, all five presets, center horizontal normalized profile over ±10 µm: RMSE 0.000068–0.000544; maximum pointwise difference 0.00018–0.00190 (relative to normalized peak). Half-height crossing differences at most 0.004 µm. This is an image-plane check, not a universal error bound for arbitrary planes/settings.
- Fresh uncached point-source checks at image + 10 µm: filtering Fast 0.641 s / Fine 0.781 s; circular diffraction Fast 0.607 s / Fine 0.797 s. Half-height crossings within 0.003 µm. Local Node measurements, not phone timings.
- Default extended-source at image + 10 µm: Fast 74.988 s in Node. Its fresh Fine timing was stopped before completion to bound testing cost; no extended-source speedup factor is claimed. A fresh browser Fast run at this plane also completed and displayed the Fast badge despite the switch being changed during calculation. Arbitrary defocus remains expensive. Existing default-position cache hits do not run this calculation.
- Separate image-plane Fast solver checks took about 4.67 s default, 3.22 s annular, 0.82 s dipole, and 0.09 s for the two coherent presets. These solver timings omit cache loading and UI rendering, and do not establish browser end-to-end latency.

## 2026-09-27 — Observation heading and Settings polish

- Mobile position disclosure now opens from the Observation screen heading; shared controls retain their values across Standard/Expert/desktop moves. Mobile idle action reads Compute.
- Mobile Settings exposes General, Components, About and Contact. Dialog closure restores focus to Settings. At 320px Reset shares the Preset row.
- Desktop High detail stays with Compute all slices; the action group wraps together on narrow desktops. Desktop aperture uses the mobile-style side section; its inspector retains the front view and annular obstruction remains visible.
- Browser checked at 320×740, 390×844, 638×836, 995×836 and 1228×836: no horizontal overflow. Position expansion, fine tuning, Standard/Expert switching, cached pupil calculation, stale-result status and all three menu dialogs checked. Contact verified as the existing mailto destination without opening or sending mail.
- At 1228px the detail switch and compute button share the same vertical bounds, and both slice/wave compute right edges are 839.484px. Browser reported no warnings/errors.
- 24 existing targeted tests passed (quality policy, observation lifecycle, view isolation, positions, desktop path and compact bench). No optical solver changes; no new accuracy/performance claim.
- Screenshots: .sites-runtime/polish-phone.png and .sites-runtime/polish-desktop.png. Responsive emulation, not physical-phone testing.

## 2026-09-27 — Lighter aperture and closer position control

- Mobile position trigger sits next to Observation screen instead of the far right.
- Both beam diagrams use thin aperture blades, blue when selected, without a filled selection rectangle. Transparent hit targets and annular obstruction are preserved.
- Browser checks at 320×740, 611×836 and 1176×836: no horizontal overflow; long micrometre position labels fit, disclosure opens and mobile aperture still opens its editor. No browser warnings/errors. Seven existing compact/path tests passed; solver unchanged.
- Screenshots: .sites-runtime/aperture-phone.png and .sites-runtime/aperture-desktop.png.

## 2026-09-27 — Expert detail in heading

- Mobile Expert High detail moved to the Key positions heading, before Add. Edit/Reset/Compute retains its full action row; no separate detail row.
- Checked 320, 390, 611 and 1228px widths, no horizontal overflow. Toggle persists across mode/viewport changes; add-to-six and Undo checked. Heading keyboard order matches visual order. Desktop action remains unchanged.
- Two detail policy tests passed; browser logs contain no warnings/errors. Screenshot: .sites-runtime/detail-heading-phone.png.

## 2026-09-27 — Mobile alignment, precision action and Contact

- Standard position trigger is 36px high, right-aligned with Compute within the same 480px maximum observation width.
- Full-path wave plot and region strip share the compact bench's 27px physical-domain inset. At 413px viewport, source/mask/image screen x positions match exactly (39, 175.1702, 345.3830px). Position/Compute right edges both 386px.
- Expert precision moved immediately before Compute all slices; four compact action columns preserve Edit/Reset. Below 500px the detail label and switch stack internally; the compute label may wrap.
- Mobile wave legend hidden; bottom Contact shows Chuang Lu and the existing mailto address. Desktop legend retained.
- Verified 320, 413, 611 and 1228px layouts with no horizontal overflow; position disclosure and quality preference checked. Six existing path/quality tests passed; no browser errors/warnings. No physics changes.
- Screenshots: .sites-runtime/mobile-actions-final.png and .sites-runtime/mobile-standard-final.png.

## 2026-09-28 — Physical comparison of illumination slices

- Source baseline: c5c7eb7d9eccd09589e77b6b092fb0bdc0a5a333, with this section's display changes; Node on macOS and local in-app browser preview.
- Complete suite: 113/113 passed, including four new comparison tests; final targeted comparison/quality checks: 6/6 passed. Regression covers reported distances, widening/weakening, unchanged raw arrays, independent x/y axes for displaced sources, scale-bar units, and disabled/non-peer framing.
- Desktop reproduced A=0.049, B=40.355, C=61.593, D=87.073 mm in Fast mode. All four display a 28.552 mm common window; visible B/C/D widths increase. Turning common size off restores 2.450/14.537/20.908/28.552 mm windows. Shared brightness makes later images dimmer without recomputation. Calculated z and stale target remain distinct.
- Standard Mode keeps an independent single-image view; Expert retains calibrated cards. Browser validation uses CSS viewport sizes, not a physical iPhone run. No propagation engine, raw cache assets or installed native app changed.
- Web entry and native preparation entry checked for matching versioned URL. Publishing is tracked by the Sites version/deployment result, separately from these local checks.
- Final responsive checks: 1280px desktop, 393×852 Standard/Expert, and 320×720 Expert. Captions/scale bars readable, no horizontal overflow; comparison note follows the Expert grid. Browser console: no warnings/errors. Desktop evidence: /tmp/optical-bench-comparison-desktop.png.

## 2026-09-28 — Compact relative tuning and reliable marker capture

- Baseline: a2e023a8c8bd6742f96ce47179703c75f1a17f26. Authored web UI, no propagation engine or numerical cache asset changes.
- Local in-app browser: CSS widths 320, 393, 648 and 1280, using DOM measurements (the browser's capture/zoom dimensions differ). Standard/Expert controls fit without page-level horizontal overflow. Preset and mode switch share a row; position select, relative strip and z share a row; Edit and duplicate fine/position disclosures are hidden on phones.
- Expert B: keyboard moved 200 → 200.001 mm; direct input set 34.219 mm. A Remove/Undo round trip retained four positions. Switching between desktop/mobile keeps the same control instances and values.
- Compute/Cancel check: the Expert grid document top stayed 512.0759 px before/during calculation; button stayed 95.9989 × 43.9955 px. Cancel restored Compute. Stale Standard results have a badge inside the image, not a new row.
- Pointer-based browser drags: Expert B from 200 to 303.514 mm while dragging diagonally beyond the SVG; Standard from 200 to 96.486 mm with a similarly off-diagram endpoint. Identity/mode retained and capture ended on release. Relative-strip drag continued beyond its bounds and stopped at the valid endpoint. These are browser pointer tests, not physical iPhone finger/VoiceOver verification.
- Display checks: Fixed width 40 mm produced 40 mm window captions on all four intensity views; details could be shown/hidden, scale bars independently disabled. Default details are hidden and the old illumination note is removed.
- Desktop: offset +2500 µm at Mask produced z = 202.5 mm. Reducing the configured span to ±1 mm kept z = 202.5 mm and offset +2500 µm; Reset offset returned to 200 mm and range ±1000 µm.
- New deterministic tests cover slow/fast gain, sub-micrometre accumulation, comparable 60/120 Hz travel, stationary contact, reversal, endpoints, new-contact continuity, frame coalescing, release/cancel/blur/second touch, selection identity and fixed physical frames. Browser console has no warnings/errors in these checks.
- Release checks: complete suite 121/121 passed in 133.5 s; final targeted interaction/comparison tests 17/17 passed. Native offline asset preparation succeeded; this does not establish native sync, signing, installation or a device run. A fresh Standard computation at 34.219 mm completed and displayed its calculated position with the Fast badge. Cached Image-plane result was then reused.

## 2026-09-28 — full-width tuning and compact position headings

Based on `0d452896359e58d60939683c50052d6e08bf4113`; source changes in this release:

- Mobile tuning occupies the entire beam footer. Plane and z share the Observation / Positions heading. Expert Add and group actions share the Compute row; Restore default positions and contextual Undo are in the group menu. Existing two-column cards are retained.
- Bounded gradual drag gain preserves 1 µm accumulation. Only sustained fast releases coast, for at most 240 ms; touch/regrip, external edits, mode/target changes, backgrounding and Compute stop it synchronously. Stale animation callbacks cannot change the new target. Tick phase persists across release/regrip.
- `npm test`: 124/124 passed (133.4 seconds). After the final visual tick-phase adjustment, relative-tuning and screen-drag tests were rerun: 15/15 passed. `npm run ios:prepare` succeeded after final source changes.
- Local in-app browser: CSS widths 320, 393 and 430 checked; no horizontal overflow. At 393 the strip grew from about 108 to 349 px; title fields stayed in one row. At 320 Add, menu, detail and Compute all fit with 44 px action heights. Desktop 1280 retained coarse/fine fields and ±2500 µm range; mobile strip was hidden.
- Browser interaction checks: Standard keyboard fine adjustment 200 → 200.001 mm matched the marker; Expert Add E–F and menu Undo returned to four cards. New Standard Fast calculation completed at exactly 34.219 mm. Batch start/cancel kept document-coordinate heading y=416.094 and card y=564.860 stable (focus scrolling accounted for).
- Native pointer-drag automation on this in-app viewport did not reliably hit the strip, so actual flick feel is not claimed as browser-verified. Pointer capture, release, cancel, regrip, momentum interruption and stale frames were checked with deterministic event tests. Physical iPhone Photos-like feel still requires device feedback.
- This is a web deployment. Offline iOS asset preparation is verified; installed native applications were not rebuilt, signed or reinstalled in this turn.

## 2 October 2026 — Standard Intensity removal and Projection display crop

Artifact: authored `dist/` changes based on `befafa0`, entry `app.js?v=20261002-projection-display` and `interaction-layout.css?v=20261002-standard-intensity`; final source revision is the commit containing this record. macOS, Node v25.8.0, Codex in-app browser.

- 35 relevant tests pass: wave display/components/path layout, compact bench, relative tuning and position history. Two new display checks verify preserved illumination and retained intensity values in XZ/YZ, unchanged raw arrays, near-mask bypass, and crop-to-symbol alignment at 104/128/240/300 CSS px plot heights.
- Browser review used a same-origin iframe harness because the current browser zoom limited its top-level narrow viewport. Actual frame CSS widths 320, 337, 393 and 507: Standard hides the entire wave section, Expert restores it, and body scrollWidth equals clientWidth. Desktop frame width 1280 (1250 content width with scrollbar) retains Intensity. Screenshots inspected at 393 and 1280; no physical-phone certification.
- Exercised General settings, both Projection display choices, Standard/Expert switching and resized desktop/mobile layouts. Full-field versus cropped screenshots preserve illumination and show projection bounded by Lens 1/Lens 2 outlines; changing the choice needs no Compute.
- Numerical operators, caches and MATLAB source were not edited. This is display cropping, not a lens-transmission calculation. Native assets/install and App Store distribution were not part of this task.
- Local screenshots: parent project `output/playwright/standard-no-intensity.jpg` and `output/playwright/projection-within-lenses.jpg`. Hosting result is verified separately after source preparation.
