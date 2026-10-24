# study-ios

Put this whole folder (named exactly `study-ios`) in the root of your GitHub repo, next to `.github/workflows/build.yml`.

    your-repo/
      .github/workflows/build.yml
      study-ios/
        package.json
        capacitor.config.json
        www/                 <- the web app (edit index.html here)
        native/build.sh      <- generates the Xcode project and builds the unsigned IPA
        native/alarm.wav

Build: push to main (or Actions -> Build unsigned IPA -> Run workflow), download artifact "StudyTogether-ipa".

Optional YouTube blocking (needs a PAID Apple developer account + Apple's Family Controls approval):
create an empty file `native/enable-screentime` and push. Leave it out for normal sideloading.

Not included in this build: the Live Activity and home-screen widget from the old IPA (their source code was not available).
The app falls back to normal notifications + in-app sound for alarms.
