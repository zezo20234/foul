# study-ios

Study Together (Capacitor web app + native iOS plugins). Pushing to `main` runs the
"Build unsigned IPA" workflow and uploads `StudyTogether-ipa`.

## Update popup
In Firebase Console > Realtime Database, create `config/update`:

    {
      "id": "v1.1",
      "message": "A new version of Study Together is available!",
      "url": "https://github.com/zezo20234/pomodoro/releases/latest/download/StudyTogether.ipa"
    }

Change `id` whenever you push an update; every user then sees the popup once, and the
Update button opens `url` in Safari. Add this to your database rules so apps can read it:

    "config": { ".read": true, ".write": false }

## Screen Time
Needs Apple's Family Controls entitlement on the account that signs the app (see notes).
