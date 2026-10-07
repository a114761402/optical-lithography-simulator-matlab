# Optical Bench on iPhone

The iPhone app uses the same simulator and mobile interface as the website. Calculations and bundled example data work offline. Experiment settings are saved on the phone; individual images can be saved or shared with the iOS share sheet.

## Keep the iPhone app synchronized

The website source is `dist/`. After web changes, run `npm run ios:sync` in this checkout, then build and run the app in Xcode. This regenerates both `ios-web/` and `ios/App/App/public/` from the same source, including all preset caches, and clears obsolete files from the generated native copy. These generated folders are intentionally not stored in Git; a fresh checkout must run the same command before building. Publishing the website does not update an installed iPhone app.

For an in-place phone update, keep the same bundle identifier and signing team so saved experiments remain available. If Xcode has no Apple Account or the previous provisioning profile has expired, sign in under **Xcode → Settings → Apple Accounts** and rebuild using Automatic signing. A prepared bundle or a simulator build is not an installed phone update.

## Install on your iPhone 14 Pro

1. Connect and unlock your iPhone. Tap **Trust** if the phone asks. On the phone, turn on **Settings → Privacy & Security → Developer Mode**, then restart and confirm.
2. Open `ios/App/App.xcodeproj` in Xcode. In **Xcode → Settings → Accounts**, sign in with your own Apple Account. A free Personal Team is sufficient for testing on your own phone; App Store distribution needs Apple Developer Program membership.
3. Click the blue **App** project in Xcode, select the **App** target, then **Signing & Capabilities**. Turn on **Automatically manage signing** and choose your team. If Xcode says the bundle identifier is already taken, replace `com.chuanglu.opticalbench` with an identifier unique to your team.
4. Select your connected **iPhone 14 Pro** beside the Run button, then press **Run** (▶). If the first launch is blocked, open **Settings → General → VPN & Device Management** on the iPhone and trust your Apple Account's developer app, then try again.
5. After installation, test without Wi-Fi: change a preset, move an observation position, compute a slice and a full path, save an experiment, close and reopen the app, then share an image.

If Xcode reports **No signing certificate**, first complete step 2 and choose your team again. If it reports **device unavailable**, unlock the iPhone and reconnect the cable. If signing fails with **resource fork or Finder information not allowed**, copy this project to a local folder outside iCloud Drive or synced Documents, run `npm run ios:sync` there, and open that copy in Xcode. A free Personal Team installation may expire and need another Run from Xcode.

## App Store preparation

The app has an iPhone-only portrait target, an app icon, splash screen, local data storage, native image sharing, a privacy manifest, and a public [privacy policy](https://lu-optical-bench.targarney.chatgpt.site/privacy.html). The app does not include advertising, accounts, or analytics. App Store Connect setup, distribution signing, screenshots, upload, and Apple's review still require the owner's Apple Developer Program account; acceptance cannot be guaranteed before review.

Suggested listing:

- Name: **Optical Bench**
- Subtitle: **Explore light and imaging**
- Category: **Education**
- Support URL: `https://lu-optical-bench.targarney.chatgpt.site/`
- Privacy URL: `https://lu-optical-bench.targarney.chatgpt.site/privacy.html`
- Description: “Explore how light travels from a source through a mask and projection optics to an image. Move observation planes, compare intensity slices, and calculate the full optical path. Built for learning with interactive optics diagrams and offline examples.”

Before submitting, verify the physical iPhone workflow and current App Store Connect requirements, complete the privacy questionnaire accurately, create screenshots from the final signed build, and check rights for the app name and artwork.

For contributors: run `npm ci`, `npm test`, `npm run ios:sync`, then open the Xcode project. The web files in `dist/` remain the website source. `scripts/prepare-ios.mjs` copies them to the offline app bundle and adds the native storage and sharing bridge. Avoid editing the generated `ios/App/App/public/` folder directly.
