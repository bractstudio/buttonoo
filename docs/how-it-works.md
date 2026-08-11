# How it works

The mechanics behind the app, and the constraints that shaped them. Useful if you are changing the
key handling, the unlock flow, or the overlay.

---

## 1. Getting the key at all

The Essential Key enters the input pipeline as `keyCode = 0` (`KEYCODE_UNKNOWN`). Android's key
layout files do not map it, so it arrives with only its raw Linux **scan code** intact.

Ordinary apps never see it. Hardware key events are delivered to accessibility services that declare
`canRequestFilterKeyEvents`, and essentially nowhere else — there is no foreground-app API, no
broadcast, no manifest-registered receiver. That is the whole reason this app asks for an
accessibility permission, and it is worth saying plainly in the UI, because users are right to be
suspicious of the request.

**The scan code is not the same on every device.** Values of 250 and 296 have both been observed on
shipping hardware. Never hardcode it. `ConfigStore.DEFAULT_SCAN_CODE` is a seed, not an answer — the
learn-mode screen exists so the user can record the real one.

### Minimum-privilege service config

`android/app/src/main/res/xml/accessibility_service_config.xml` requests key filtering and nothing
else:

- `android:canRequestFilterKeyEvents="true"` and `accessibilityFlags="flagRequestFilterKeyEvents"`
- no `accessibilityEventTypes`
- no `canRetrieveWindowContent`

`KeyRemapService.onAccessibilityEvent` is deliberately empty. Keep it that way. This configuration is
what makes "it cannot read your screen or any other keystroke" a true statement rather than a
promise, and it is the argument to make if a store review asks why an accessibility service is
needed.

### Consuming an event is not the same as owning it

`onKeyEvent` returning `true` stops the event reaching other apps. It does **not** stop Nothing OS's
own handling of the single press, which happens at the system-policy level, below where an
accessibility service sits. See §3.

---

## 2. Gesture classification

`KeyGestureClassifier` turns a stream of down/up pairs into one of five gestures. It takes a
`GestureScheduler` rather than touching `Handler` directly, so the whole thing is testable without an
Android runtime.

Two timings, both user-configurable:

| | Default | Meaning |
|---|---|---|
| `longPressMs` | 500 ms | held this long without release → long press |
| `multiTapMs` | 400 ms | window to wait for the next tap before deciding |

The part worth understanding is `immediateOrNull`. If the user has not assigned anything to double,
triple or quadruple press, there is nothing to wait *for* — a single tap can fire the moment the key
is released instead of sitting through the multi-tap window. The classifier is constructed with the
set of gestures that currently have actions, so assigning a double press deliberately makes single
press feel slower. That is a real trade-off, not a bug, and the Behaviour screen says so.

The service rebuilds the classifier whenever the config changes, because both the timings and the
enabled-gesture set are baked in at construction.

---

## 3. Freeing the single press

Nothing OS routes the single press to Essential Space in system policy. An accessibility service
cannot intercept that, and consuming the event does not help — by the time it reaches the service the
system has already acted. Coexistence is not possible without root or an LSPosed module.

What *is* possible: the packages that claim it are user-disableable system apps.

| Package | Holds |
|---|---|
| `com.nothing.ntessentialspace` | single and double press |
| `com.nothing.ntessentialrecorder` | long press |
| `com.essentialintelligence` | present on some models |

Probe which are actually installed rather than assuming — `ConsumerPackages.forUnlock` does this.
Their enabled state is readable without any privilege via
`PackageManager.getApplicationEnabledSetting`, which is how the unlock screen knows what it is
looking at.

Disabling them is `pm disable-user --user 0 <package>`, reachable four ways:

1. **App Info** — `Settings.ACTION_APPLICATION_DETAILS_SETTINGS` deep-links to the page and the user
   taps Disable. No tooling. Try this first; on most Nothing OS builds it is the whole flow.
2. **Built-in ADB** — `BuiltInAdbRoute` pairs with the phone's own `adbd` over Wireless debugging
   via loopback. Pairing is one-time; `adbd` remembers the key.
3. **Shizuku** — `ShizukuRoute`, if the user already runs it.
4. **Manual ADB** — the app prints the commands for a PC.

Nothing is uninstalled and all of it is reversible. `restoreEssentialSpace` tries every route it can,
cheapest first, and falls back to opening App Info.

### Two things that will bite you

**Pairing needs a notification with an inline reply.** Opening any in-app dialog to collect the
pairing code backgrounds the system pairing dialog, which cancels pairing. The code has to be entered
somewhere that does not take focus — hence `PairingNotification` and the runtime
`POST_NOTIFICATIONS` request in `MainActivity`.

**Shizuku hands over its binder asynchronously.** Without the sticky binder-received listener in
`MainActivity.configureFlutterEngine`, a cold start races it and every availability check answers
"not running".

---

## 4. Why the app needs so few permissions

`<queries>` with a MAIN/LAUNCHER `<intent>` returns every launchable app, which is all an app picker
needs. `QUERY_ALL_PACKAGES` is not required and should not be added — it is a sensitive permission
that triggers a Play declaration for no benefit here.

The permissions that are present are each tied to one feature and requested only when it is used:

| Permission | Needed for |
|---|---|
| `SYSTEM_ALERT_WINDOW` | the edge overlay |
| `WRITE_SETTINGS` | brightness and rotation lock |
| `ACCESS_NOTIFICATION_POLICY` | Do Not Disturb and silent ringer mode |
| `VIBRATE` | action haptics |
| `POST_NOTIFICATIONS` | the ADB pairing reply field, nothing else |
| `INTERNET` | the built-in ADB route's loopback socket |

No foreground service and no boot receiver: the system restarts accessibility services on its own.

---

## 5. Configuration and the bridge

`ConfigStore` wraps a single DataStore instance and exposes each setting as a `Flow`. The service
collects those flows, so a change made in the UI reaches the key handler without any explicit
plumbing — write to DataStore and the running service reconfigures itself.

`MethodBridge` is the only entry point from Flutter. Everything crosses as JSON strings except the
app list and icons, which are maps and raw bytes. `lib/native/remapper_channel.dart` is the matching
Dart side; the two files are the entire contract, so changing one means changing the other.

Backup and restore reuse the same JSON schema as the bridge, which is why `AppConfig.toJson` is both
the export format and the wire format.

### App list and icons

These are two calls, not one, and it matters. `installedApps` returns package names and labels only.
Icons come from `appIcon`, one package at a time, drawn at the size the row actually needs and cached
natively behind an LRU that a package-change broadcast invalidates.

Fetching every icon up front meant allocating a full-size bitmap per installed app and compressing it
losslessly — several megabytes across the channel, and multiple seconds, to render a list of names.
If you add a screen that needs app names, use `appLabels` for the specific packages you care about.

---

## 6. The overlay

`OverlayController` owns a `TYPE_APPLICATION_OVERLAY` window and two views: `NothingGlowView` (an
edge-anchored strip) and `StockPillView` (a centred pill).

The glow style is a full-height strip pinned to an edge, not a box at the anchor point — the hairline
runs the height of the screen and the bloom spills past the edge, so the view places the panel itself
from `anchorFraction`. Layout params are rebuilt on rotation via `onConfigurationChanged`.

The overlay is normally `FLAG_NOT_TOUCHABLE`. The Apps Column action is the exception: it has to
receive taps, so it drops that flag and dismisses itself once something is launched.

The overlay settings screen shows edits on the *real* overlay by calling `previewOverlay(sticky: true)`,
which holds it on screen until the page closes. There is no second in-app rendering of the overlay to
drift out of sync.
