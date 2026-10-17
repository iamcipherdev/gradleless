# BuildAPK

**Build signed Android APKs without Gradle, without Android Studio, without network.**

BuildAPK is a small, dependency-free CLI that turns a simple project folder into a
signed, zipaligned APK using only the Android SDK build-tools (`aapt2`, `d8`,
`zipalign`, `apksigner`) and a JDK. It exists because Gradle is slow, heavy, and
overkill for small apps — and because you should be able to build an APK on any
machine with a JDK and the SDK build-tools.

## Why

- **Fast:** a full build of the starter template takes seconds, not minutes.
- **Offline:** zero network calls. No plugin downloads, no dependency resolution.
- **Transparent:** 5 explicit pipeline stages you can read in one shell script.
- **Portable:** runs anywhere a JDK 17+ and the Android SDK build-tools exist.

## Prerequisites

1. **JDK 17+** — set `JAVA_HOME`, or place one at `~/workspace/tools/jdk-17.0.20.1+1`
   (the default this script looks for).
2. **Android SDK build-tools** (34.0.0 tested) — `aapt2`, `d8`, `zipalign`,
   `apksigner`. Override with `ANDROID_BT` if installed elsewhere.
3. **Android platform** `android-34` (`android.jar`). Override with `ANDROID_JAR`.

The script checks all of these up front and tells you exactly what's missing.

## Quickstart

```bash
# 1. Build the bundled starter app
./buildapk.sh --src template --out hello.apk \
  --name "Hello BuildAPK" --package com.example.hello

# 2. Verify it
~/Android/sdk/build-tools/34.0.0/aapt dump badging hello.apk | grep -E "^(package|launchable-activity):"

# 3. Install on your device
adb install hello.apk
```

On first run, BuildAPK creates a debug keystore at `~/.buildapk/debug.keystore`
and reuses it afterwards. Bring your own release key with `--keystore`.

## CLI reference

```
buildapk.sh --src <project-dir> --out <app.apk> [options]

  --name NAME          App label                      (default: BuildAPK)
  --package PKG        Application id                 (default: com.example.buildapk)
  --version-code N     Integer version code           (default: 1)
  --version-name X     Version name                   (default: 1.0)
  --min-sdk N          minSdkVersion                  (default: 24)
  --target-sdk N       targetSdkVersion               (default: 34)
  --keystore PATH      Signing keystore               (default: ~/.buildapk/debug.keystore)
  --ks-pass PASS       Keystore password              (default: android)
  --key-pass PASS      Key password                   (default: android)
  --key-alias ALIAS    Key alias                      (default: androiddebugkey)
  --keep-tmp           Keep the temp build dir for debugging
```

## Project layout

```
myapp/
  AndroidManifest.xml     ({{PACKAGE}} / {{APP_NAME}} are auto-substituted)
  java/                   Java sources, e.g. java/com/example/app/MainActivity.java
  res/                    Android resources (values, drawable, mipmap, …)
  assets/                 (optional) bundled raw assets
  libs/*.jar              (optional) extra jars — added to javac and d8
  jniLibs/<abi>/*.so      (optional) native libs, packaged uncompressed
```

## How it works (the 5 stages)

1. **aapt2 compile** — resources in `res/` are compiled to a flat zip.
2. **aapt2 link** — links resources against `android.jar`, merges the manifest,
   stamps `--version-code/--version-name`, and generates `R.java`.
3. **javac** — compiles `R.java` + your `java/` sources against `android.jar`
   (plus any `libs/*.jar`).
4. **d8** — dexes all classes (plus `libs/*.jar`) into `classes.dex`.
5. **package → zipalign → apksigner** — dex (and `jniLibs/`) are zipped into the
   APK, 4-byte aligned, then signed with v1+v2 schemes. The build fails loudly if
   `apksigner verify` or the badging check doesn't pass.

## Examples

- `examples/webview/` — wrap a website (or a local `assets/www` page) as an APK.
  The seed of the **web2apk** idea: URL in, APK out. See its README.

## Limitations

- **Simple apps only.** No Gradle plugins, no build variants/flavors, no
  resource shrinking, no R8/ProGuard, no Kotlin compiler (prebuilt Kotlin jars in
  `libs/` work — Kotlin *sources* do not compile here).
- **Library AARs:** if you add an AAR, you must compile its `res/` with
  `aapt2 compile` yourself and pass `--extra-packages` at link time, or the
  library's `R` class goes missing at runtime (`NoClassDefFoundError`). KMP
  artifacts (e.g. androidx datastore) ship Android classes only in their
  `-android` AAR's `classes.jar` — the plain jar on Maven is metadata-only.
- **Manifest:** never hand-declare Firebase's `FirebaseCommonRegistrar` (or other
  auto-registered components) in `AndroidManifest.xml` — Firebase registers them
  internally and duplicates crash the app at startup.
- One ABI packaging per build for native libs is up to you (`jniLibs/` layout).

## License

MIT — see [LICENSE](LICENSE).

## Credits

Built from a real-world manual aapt2/d8 pipeline used to ship production apps
(Huba, BillBanao, Entwine, Cipher Racing). Created by cipher / R&R Labs.
