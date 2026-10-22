# Study Together: iOS build

Your PWA wrapped as a native iOS app with Capacitor. You need a Mac with Xcode to produce the .ipa.

## One-time setup
1. Install Node.js (18+) and Xcode (from the Mac App Store), then run `sudo gem install cocoapods` (or `brew install cocoapods`).
2. In this folder: `npm install`
3. `npm run ios:add`   (creates the `ios/` Xcode project)
4. `npm run ios:sync`  (copies `www/` into the app)
5. `npm run ios:open`  (opens Xcode)

## In Xcode
1. Click the **App** project, then **Signing & Capabilities**.
2. Pick your Team (a free Apple ID works for installing on your own phone; the paid Developer Program is needed for TestFlight/App Store).
3. Change the Bundle Identifier to something unique (match `appId` in capacitor.config.json).
4. Replace the app icon: Assets > AppIcon, drag in a 1024x1024 PNG (your icon-512.png is too small for the App Store; upscale or redraw it).

## Get the .ipa
- **Test on your phone**: plug in, choose it as the run target, press Run. (Free accounts: the install expires after 7 days.)
- **Export an .ipa**: Product > Archive, then Distribute App. Choose Ad Hoc / Development for devices you registered, or App Store Connect for TestFlight/App Store.

## After editing the web app
Edit files in `www/`, then run `npm run ios:sync` and re-run in Xcode.

## Notes
- sw.js is bundled but service workers don't run inside the iOS app wrapper. That's harmless; the app files are already local. Firebase and Google Fonts still load over the network, so those parts need an internet connection.

## No Mac? Build on GitHub and install from Windows
1. Create a GitHub repo and push this whole folder to the `main` branch.
2. Open the repo's **Actions** tab, choose **Build unsigned IPA**, and click **Run workflow** (it also runs on every push).
3. When it finishes (about 5-10 minutes), open the run and download the **StudyTogether-ipa** artifact. Unzip it to get `StudyTogether.ipa`.
4. On Windows, install iTunes and iCloud from apple.com (not the Microsoft Store versions) and Sideloadly (sideloadly.io).
5. Plug in your iPhone and trust the computer. Drag the .ipa into Sideloadly, enter your Apple ID, and click Start.
6. On the iPhone: Settings > General > VPN & Device Management > trust your Apple ID. Turn on Developer Mode if asked (Settings > Privacy & Security).
7. A free Apple ID install expires after 7 days. Re-run Sideloadly to refresh it.

## v2 (native features)
Build logic now lives in `native/build.sh`; the workflow only calls it. Adds haptics, alarm notifications,
a Live Activity widget, background audio and no-zoom. To update: upload changed files to GitHub, wait for the build,
install the new .ipa over the old one.
