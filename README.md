# buttonoo

Remap the Essential Key on Nothing phones to whatever you want, on any press pattern.

Single, double, triple and quadruple press, plus hold — each one can launch an app, open a shortcut
or a specific activity, toggle the torch, change volume or brightness, cycle the ringer, fire the
assistant, or show a column of apps to pick from. An edge overlay confirms what fired.

Android only. Built with Flutter over a Kotlin accessibility service.

---

## Status

Working, and used daily on the author's device. Not yet on any store.

Single press needs an extra setup step — see [Freeing the single press](#freeing-the-single-press).
Everything else works with nothing but the accessibility permission.

## Download

Grab the APK from [the latest release](https://github.com/bractstudio/buttonoo/releases/latest).

Take `app-arm64-v8a-release.apk` — every Nothing and CMF phone with an Essential Key is 64-bit
ARM. The `armeabi-v7a` and `x86_64` builds are there for completeness and for emulators; you
almost certainly do not want them.

## Requirements

- A Nothing or CMF phone with an Essential Key
- Android 13 (API 33) or newer

Other devices with an unmapped hardware key may work — the app matches on the raw scan code and
nothing about it is specific to Nothing hardware — but no one has tested that.

## Building

```bash
flutter pub get
flutter build apk --release
```

Release signing is opt-in — without a keystore the release APK comes out unsigned. To sign your
own builds, create `android/key.properties`, which is gitignored:

```properties
storeFile=/absolute/path/to/release.jks
storePassword=…
keyAlias=…
keyPassword=…
```

## How it works

The short version: Android exposes hardware key events to accessibility services and almost nowhere
else, so the app runs one — `KeyRemapService` — with `canRequestFilterKeyEvents`. It watches for a
single scan code, classifies the press pattern, and runs the action you mapped to it.

The service does not request `canRetrieveWindowContent` and `onAccessibilityEvent` is empty, so it
cannot read screen content, text fields, or any other keystroke.

For the details — how the key surfaces, why the classifier is shaped the way it is, and what the
unlock flow actually does — see [docs/how-it-works.md](docs/how-it-works.md).

## Freeing the single press

Nothing OS claims the single press for Essential Space at the system level. Returning `true` from an
accessibility service does not take it back; the only way is to disable the system apps that hold it.
Nothing is uninstalled and it is reversible from inside the app.

Four routes, in order of friction:

1. **App Info** — the app deep-links you to each package's settings page and you tap Disable. No
   tools, works on most Nothing OS builds.
2. **Built-in Wi-Fi ADB** — pair over Wireless debugging from the phone itself, no PC.
3. **Shizuku** — if you already have it set up.
4. **Manual ADB** — the app gives you the exact commands to paste into a terminal.

Double, triple, quadruple and long press need none of this.

## Privacy

No network use at runtime, no analytics, no accounts. Configuration lives in local Android DataStore.
The `INTERNET` permission is present only for the built-in ADB route, which connects to the phone's
own `adbd` over loopback.

## Contributing

Issues and pull requests are welcome. Please run `flutter analyze` and `flutter test` before opening
a PR.

The codebase is small: `lib/` is the Flutter UI, `android/app/src/main/kotlin/` holds the service,
the gesture classifier, the action executor and the overlay. `lib/native/remapper_channel.dart` is
the entire boundary between the two.

## Licence

GPL-3.0-or-later. See [LICENSE](LICENSE).

Third-party components:

- [libadb-android](https://github.com/MuntashirAkon/libadb-android) and
  [sun-security-android](https://github.com/MuntashirAkon/sun-security-android) — dual GPL-3.0-or-later / Apache-2.0
- [Shizuku API](https://github.com/RikkaApps/Shizuku-API) — Apache-2.0
- [HiddenApiBypass](https://github.com/LSPosed/AndroidHiddenApiBypass) — Apache-2.0
- [phosphor_flutter](https://pub.dev/packages/phosphor_flutter) — MIT
- [Doto](https://github.com/oliverlalan/Doto) and [Geist Mono](https://github.com/vercel/geist-font)
  typefaces — SIL Open Font License 1.1, see `fonts/OFL.txt`

Not affiliated with, endorsed by, or connected to Nothing Technology Limited. "Nothing", "CMF" and
"Essential Space" are their trademarks, used here only to describe what this app interoperates with.
