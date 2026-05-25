# iOS Home Screen Widget — Setup

Implementation lives in:

| Layer | Path |
|-------|------|
| Flutter bridge | `lib/widget/widget_bridge.dart`, `widget_snapshot.dart` |
| App Group store | `ios/Shared/WidgetDataStore.swift` |
| Runner plugin | `ios/Runner/WidgetBridgePlugin.swift` |
| Widget UI + intents | `ios/TodayWidget/` |

## One-time Xcode setup

1. **Install xcodeproj** (if needed):

   ```bash
   gem install xcodeproj
   ```

2. **Add the widget target** (automated):

   ```bash
   cd mobile/ios
   ruby configure_widget.rb
   ```

3. **Open Xcode**:

   ```bash
   open Runner.xcworkspace
   ```

4. **Signing & Capabilities** (Runner and TodayWidgetExtension):
   - Team: your Apple Developer team
   - **App Groups**: enable `group.com.dailyticker.dailyTicker` on **both** targets
   - If the script set entitlements files, confirm they match in the Signing UI

5. **Deployment target**: iOS **17.0+** (interactive widget buttons)

6. **Build & run** on a physical device or simulator (iOS 17+):

   ```bash
   cd mobile
   flutter run
   ```

7. **Add widget**: long-press Home Screen → **+** → **Daily Ticker** → choose Medium/Large/Small.

## How sync works

- Every app save exports `widget_snapshot.json` to the App Group.
- Widget taps run App Intents → update the same file with `needsAppSync: true`.
- When the app resumes, Flutter merges widget changes into `daily_ticker_data`.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| **Invalid placeholder attributes** (simulator won’t install) | Widget extension was missing **CFBundleVersion**. Fixed in `TodayWidget/Info.plist` (version `1` / `1.0.0`). In Xcode: **Product → Clean Build Folder**, delete app from simulator, run again. |
| Widget shows “Open the app…” | Open app once while signed in so snapshot exports |
| Taps do nothing | Simulator/device must be iOS 17+; rebuild after adding extension |
| `configure_widget.rb` fails | Add **Widget Extension** manually in Xcode (name `TodayWidgetExtension`, include all `ios/TodayWidget/*.swift` + `ios/Shared/WidgetDataStore.swift`) |
| App Group errors | Same group ID on Runner + extension entitlements |

### “Invalid placeholder attributes” (detail)

The home screen **widget extension** (`TodayWidgetExtension.appex`) must have a valid **bundle version**. If `CFBundleVersion` is empty, iOS refuses to install the app on the simulator.

Before running from Xcode, generate Flutter iOS config once:

```bash
cd mobile
flutter pub get
```

Then in Xcode: **⇧⌘K** (Clean), **⌘R** on **Runner** with an **iPad/iPhone simulator** selected.

## Manual target creation (if Ruby script unavailable)

1. File → New → Target → **Widget Extension**
2. Product name: `TodayWidgetExtension`, include Live Activity: **No**
3. Delete generated Swift files; add files from `ios/TodayWidget/` and `ios/Shared/WidgetDataStore.swift` to the extension target
4. Add `WidgetDataStore.swift` + `WidgetBridgePlugin.swift` to **Runner** target
5. App Groups on both targets: `group.com.dailyticker.dailyTicker`
6. Runner **Build Settings** → Code Sign Entitlements → `Runner/Runner.entitlements`
7. Extension entitlements → `TodayWidget/TodayWidget.entitlements`
