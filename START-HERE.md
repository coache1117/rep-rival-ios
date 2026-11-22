# Rep Rival - the iPhone app · RR31 (R2)

This folder is the iPhone wrapper for **myreprival.netlify.app**. The app opens the live site inside a real iPhone app.
When you put a new build on the site, the app gets it too. No new upload needed for normal updates.

Rep Rival is the gym app.

- App name: **Rep Rival**
- Bundle ID: **com.myreprival.app**  (if Apple says it is taken, change it in `capacitor.config.json` AND `codemagic.yaml`)
- Built by: **Codemagic**, with the same Apple key as the RideFlow apps (label: RideFlow App Store key).

## What you do

1. **Make the app ID.** developer.apple.com > Account > Identifiers > + > App IDs > App.
   Description: `Rep Rival` (any label). Bundle ID: Explicit, `com.myreprival.app`. Continue, Register.
2. **Make the app in App Store Connect.** appstoreconnect.apple.com > Apps > + > New App.
   Platform iOS, name `My Rep Rival`, language English, bundle ID `com.myreprival.app`, SKU `rep-rival`.
3. **Put this folder on GitHub.** github.com > New repository > name `rep-rival-ios`, Private > Create.
   Then "uploading an existing file", drag in everything in this folder, Commit to `main`.
4. **Codemagic.** codemagic.io > Add application > pick `rep-rival-ios`. It finds `codemagic.yaml` on its own.
5. **Signing.** Codemagic > Team settings > Code signing identities > iOS provisioning profiles > Fetch profiles >
   pick the App Store profile for `com.myreprival.app`.
   (If none shows: developer.apple.com > Profiles > + > App Store Connect > pick `com.myreprival.app` > your Apple Distribution
   certificate > Generate. Then Fetch again.)
6. **Build.** Codemagic > rep-rival-ios > Start new build > workflow `Rep Rival - iPhone`. About 15-25 minutes. Green = it went to TestFlight.
7. **On your phone.** App Store Connect > Rep Rival > TestFlight > add yourself as an internal tester. Install it from the TestFlight app.

## Test on the phone

1. Open it and log a set.
2. Close the app all the way and open it again. Your work is still there.

## Good to know

- This gets you onto TestFlight for your own testers. Sending it to Apple for public review also needs screenshots,
  a description, a privacy policy link, a support link and the privacy label.
- The words Apple shows when it asks for a permission are in `scripts/ios-setup.sh`.


## RR30 · voice (needs a new Codemagic build)
Tap the mic (bottom left) once, then say "Coach, ..." - the app keeps listening with the iPhone's own speech engine, and answers in Coach E's voice.
The first time you tap the mic, the iPhone asks to allow the Microphone and Speech Recognition. Say Allow to both.
New files: `native/`. The setup script adds them to the project by itself. If Codemagic stops at "could not point Main.storyboard", send Claude the log.


## RR31 · R2 · the ears for real, plus the app link
- The coach's ears are now attached two ways. If either piece is missing, Codemagic STOPS with a plain message instead of making an app that can't listen.
- App link rivalrep:// - Club Rival's tile opens this app instead of the website.
- Upload EVERYTHING in this zip to the repo (replace all), then Start new build in Codemagic.
