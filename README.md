# Health Buddy

A wellness app for students: Health Score, weekly analytics, an AI Coach, and logs for food, stress and exercise.

> **Status: 8-screen prototype, hardcoded version (October 2026).** Home, Analytics, AI Coach, Food, Profile, Scan Meal, Stress Check and Log Exercise are all clickable. All data is sample data. Some numbers are still written directly inside the screens; moving them into `lib/data/dummy_data.dart` is part of the team's work. There is no login, backend or real AI yet.

## Running the app

Requirements: [Flutter SDK](https://docs.flutter.dev/get-started/install), stable channel.

```bash
git clone https://github.com/<org>/health-buddy.git
cd health-buddy
flutter pub get
flutter run -d chrome        # or pick a phone/emulator
```

The `android/`, `ios/` and `web/` folders are already in the repo, so you do **not** need to run `flutter create`.

### In VS Code

1. Open the repo folder (File → Open Folder). VS Code will suggest the **Flutter** extension; install it.
2. Open **Run and Debug** (Cmd/Ctrl+Shift+D) → choose **Health Buddy · Chrome** or **Health Buddy · Phone / emulator** → press F5.
3. Save a file (Cmd/Ctrl+S) to hot reload. Code is formatted automatically on save.

Seeing *"JDK 17 or higher is required"*? That comes from the Java extension, not Flutter: Extensions → **Language Support for Java** → **Disable (Workspace)**. For Android builds, run this once on a Mac:
`flutter config --jdk-dir="/Applications/Android Studio.app/Contents/jbr/Contents/Home"`

Build an APK: `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`

## Team

| Name | Role | Screens |
|---|---|---|
| Erwin (@erwin) | Lead & foundation | Home, Profile, tab bar, navigation |
| Teresa (@teresa) | Data & charts | Analytics, Food, Scan Meal |
| Fadhil (@fadhil) | Interaction & animation | AI Coach, Stress Check, Log Exercise |

## Folder structure

```
lib/
  main.dart            App entry point + tab bar           (Erwin)
  theme.dart           Colors, font, motion curves         (Erwin)
  data/
    models.dart        Data classes                        (Teresa)
    dummy_data.dart    ALL sample data lives here          (Teresa)
  widgets/
    common.dart        Cards, buttons, progress bar, toast (Erwin)
    charts.dart        Score ring, line, bar, radar charts (Teresa)
    animated.dart      FadeUp, PressScale, mascot          (Fadhil)
  screens/             One file per screen
assets/fonts/          Figtree (OFL license)
docs/                  Timeline PDF, setup guide, design links
tool/make_dartpad.py   Builds a single-file version for dartpad.dev
```

## Timeline

| Milestone | Date | Goal |
|---|---|---|
| M1 · Foundation | Fri Oct 9 | App runs on a phone, theme & tab bar ready |
| M2 · Core screens | Fri Oct 16 | Home, Analytics, AI Coach |
| M3 · All screens | Fri Oct 23 | All 8 screens connected |
| M4 · Release | Fri Oct 30 | APK ready to share |

Task details live in **Issues** and **Projects**. How to contribute: see [CONTRIBUTING.md](CONTRIBUTING.md).

## Design reference

- 8-screen mockup and Animation Flow board: see `docs/`
- Main colors: green `#16A34A`, purple (stress) `#7C3AED`, blue `#2563EB`, orange `#F59E0B`
- Font: Figtree
