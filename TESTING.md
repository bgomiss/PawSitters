# Local testing with the Firebase Emulator Suite

You can run the app against local emulators instead of the production
`pawsittersapp` project, so test accounts and listings never touch real data.

## 1. Start the emulators

Requires Node.js 18+ and Java 21+ (`npm install -g firebase-tools`).

```bash
firebase emulators:start --project pawsittersapp --only auth,firestore,storage
```

`firebase.json` configures the ports (Auth 9099, Firestore 8080, Storage 9199,
UI on http://127.0.0.1:4000) and loads `firestore.rules` / `storage.rules`.

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

## Test accounts used during development

These only exist in the local emulator (they are wiped when it stops):

| Role   | Email                    | Password    |
|--------|--------------------------|-------------|
| Owner  | owner1@pawsitters.test   | PawTest2026 |
| Sitter | sitter1@pawsitters.test  | PawTest2026 |

## Security rules

`firestore.rules` and `storage.rules` describe the access rules the app needs
(profiles, listings, per-user favorites, messages). Review them and deploy with
`firebase deploy --only firestore:rules,storage` if you want the production
project to use the same rules.
