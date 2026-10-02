# Optical Bench — US and Netherlands App Store submission draft

This is a draft for App Store Connect, not a submitted listing. The Apple Developer Program account must be enrolled using the developer's real legal identity and current country of residence. The app's **availability** should be set separately to **United States and Netherlands only**.

## Product page (English, shared by both stores)

- Platform: iOS (iPhone)
- Name: Optical Bench
- Subtitle: Explore light and imaging
- Primary language: English (U.S.)
- Primary category: Education
- Bundle ID: `com.chuanglu.opticalbench` (confirm availability in the paid team)
- Version: 1.0
- Price: Free **proposed; owner to confirm**
- Keywords: `optics,light,imaging,diffraction,simulation,physics,aperture,lens`
- Support URL: https://lu-optical-bench.targarney.chatgpt.site/
- Privacy policy URL: https://lu-optical-bench.targarney.chatgpt.site/privacy.html

Description:

> Explore how light travels through an optical system, from a source pupil and mask to a projected image. Move the observation plane to see how the image changes, then inspect intensity across the optical path.
>
> Use Standard Mode for a focused view or Expert Mode to compare key positions. Adjust the optical components, choose a preset, and calculate updated results. Save an experiment on your iPhone and share an observation image.
>
> The included examples and calculations work offline. Optical Bench is an educational scalar-wave model, not a tool for designing or certifying real optical hardware.

Review notes draft:

> No account or login is required. On launch, the default three-line imaging preset is ready to explore. Drag the observation-plane marker on the beam path or use the position control, then tap Compute to refresh the image. Switch to Expert Mode to compare key positions. Settings contains Save Experiment and Open Saved Experiment; images can be shared through the iOS share sheet. Calculations and saved experiments remain on the device. Optional external educational links are not required for core functionality.

## Submission checklist

- [x] All 109 automated tests pass; unsigned iOS Release archive builds successfully.
- [x] A 1320 × 2868 iPhone simulator screenshot was captured at `app-store/common/iphone-6.9-standard.png`; compare it with the final uploaded app before using it.
- [ ] Finish Apple Developer Program enrollment with the real residence and legal details; verify paid membership is active.
- [ ] Confirm the App Store name and bundle ID are available to the paid team, and accept Apple's latest agreements.
- [ ] Verify an App Store-signed build on a real compatible iPhone (offline calculation, saved experiment after relaunch, image sharing, Standard and Expert Mode). The previous company-managed iPhone blocked local development signing, so this remains unverified on that device.
- [ ] Create the App Store Connect app record and upload the final distribution-signed archive.
- [ ] Confirm the screenshot accurately represents the final uploaded build; add other screenshots if they help show Expert Mode and intensity views.
- [ ] Complete the age-rating and privacy questionnaires based on the final binary. The current app appears to keep experiments on device and not collect analytics or account data, but confirm all included SDK behavior before declaring “No data collected.”
- [ ] For Netherlands availability, the owner must complete Apple's EU Digital Services Act trader-status declaration; Apple may request verified contact details if the owner declares trader status.
- [ ] Set Pricing and Availability to **Specific Countries or Regions → United States and Netherlands** only; confirm this before submitting.
- [ ] Submit for App Review, then verify both the US and Netherlands App Stores show the app as available after approval and release.

Apple references: [Create an app record](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/), [Manage availability](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-for-your-app-on-the-app-store/), [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/), [Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy), [EU trader requirements](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements).
