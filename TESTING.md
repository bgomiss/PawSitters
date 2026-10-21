# Local testing with the Firebase Emulator Suite

You can run the app against local emulators instead of the production
`pawsittersapp` project, so test accounts and listings never touch real data.

## 1. Start the emulators

Requires Node.js 18+ and Java 21+ (`npm install -g firebase-tools`).

```bash
firebase emulators:start --project pawsittersapp --only auth,firestore,storage \
  --import ./emulator-data --export-on-exit ./emulator-data
```

`firebase.json` configures the ports (Auth 9099, Firestore 8080, Storage 9199,
UI on http://127.0.0.1:4000), listens on your local network (`0.0.0.0`) so a
physical iPhone can connect, and loads `firestore.rules` / `storage.rules`.

`emulator-data/` holds the sample data (the test accounts below, a listing, an
accepted application and two reviews). `--import` loads it and
`--export-on-exit` saves whatever you change when you stop the emulators with Ctrl+C.

## 2. Run the app against them (Debug builds only)

In Xcode: Product → Scheme → Edit Scheme → Run → Arguments, add:

```
-useFirebaseEmulator YES
```

Optional, to prefill the sign-in / sign-up email and password fields
(handy when the simulator keyboard layout makes typing `@` awkward):

```
-emulatorEmail owner1@pawsitters.test -emulatorPassword PawTest2026
```

Without `-useFirebaseEmulator` the app talks to the real Firebase project as before.

## 3. On a physical iPhone

1. Mac and iPhone must be on the same Wi-Fi network.
2. Run the Debug build on the phone from Xcode with these arguments
   (replace the host with your Mac's name from System Settings › General › Sharing,
   or its IP address):

   ```
   -useFirebaseEmulator YES -emulatorHost aycans-iMac.local
   ```

3. Allow "Local Network" access when iOS asks.

The app remembers these settings, so you can open it from the home screen later.
To switch the Debug build back to the real Firebase project, run it once with
`-useFirebaseEmulator NO`. Release builds always use the real project.

## Test accounts used during development

These only exist in the local emulator and are loaded from `emulator-data/`:

| Role   | Email                    | Password    |
|--------|--------------------------|-------------|
| Owner  | owner1@pawsitters.test   | PawTest2026 |
| Sitter | sitter1@pawsitters.test  | PawTest2026 |

## Security rules

`firestore.rules` and `storage.rules` describe the access rules the app needs
(profiles, listings, per-user favorites, messages). Review them and deploy with
`firebase deploy --only firestore:rules,storage` if you want the production
project to use the same rules.
