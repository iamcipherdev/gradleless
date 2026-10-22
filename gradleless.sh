#!/bin/bash
# =============================================================================
# gradleless — Gradle-free Android APK builder
# Builds a signed APK from a simple project dir using only aapt2 + d8.
# No Gradle. No Android Studio. No network.
#
# Usage:
#   gradleless.sh --src <project-dir> --out <app.apk> [options]
#
# Options:
#   --name NAME            App label shown on device        (default: Gradleless)
#   --package PKG          Application id, e.g. com.example.app
#                                                    (default: com.example.gradleless)
#   --version-code N       Integer version code             (default: 1)
#   --version-name X       Version name string              (default: 1.0)
#   --min-sdk N            minSdkVersion                    (default: 24)
#   --target-sdk N         targetSdkVersion                 (default: 34)
#   --keystore PATH        Signing keystore (auto-created debug key if missing)
#   --ks-pass PASS         Keystore password                (default: android)
#   --key-pass PASS        Key password                     (default: android)
#   --key-alias ALIAS      Key alias                        (default: androiddebugkey)
#   --keep-tmp             Don't delete the temp build dir (for debugging)
#
# Project layout (<project-dir>):
#   AndroidManifest.xml    (may use {{PACKAGE}} / {{APP_NAME}} placeholders)
#   java/                  Java sources (package dirs mirror the package id)
#   res/                   Android resources
#   assets/                (optional) bundled assets
#   libs/*.jar             (optional) extra jars for javac + d8
#   jniLibs/<abi>/*.so    (optional) native libraries, packaged uncompressed
#
# Env overrides:
#   JAVA_HOME   must point at a JDK 17+   (default: ~/workspace/tools/jdk-17.0.20.1+1)
#   ANDROID_BT  build-tools dir           (default: ~/Android/sdk/build-tools/34.0.0)
#   ANDROID_JAR android.jar               (default: ~/Android/sdk/platforms/android-34/android.jar)
# =============================================================================
set -e

# ---------- defaults ----------
SRC=""; OUT=""
APP_NAME="Gradleless"; PACKAGE="com.example.gradleless"
VCODE=1; VNAME="1.0"; MINSDK=24; TARGETSDK=34
KEYSTORE="$HOME/.gradleless/debug.keystore"
KS_PASS="android"; KEY_PASS="android"; KEY_ALIAS="androiddebugkey"
KEEP_TMP=0

# ---------- arg parsing ----------
while [ $# -gt 0 ]; do
  case "$1" in
    --src)          SRC="$2"; shift 2;;
    --out)          OUT="$2"; shift 2;;
    --name)         APP_NAME="$2"; shift 2;;
    --package)      PACKAGE="$2"; shift 2;;
    --version-code) VCODE="$2"; shift 2;;
    --version-name) VNAME="$2"; shift 2;;
    --min-sdk)      MINSDK="$2"; shift 2;;
    --target-sdk)   TARGETSDK="$2"; shift 2;;
    --keystore)     KEYSTORE="$2"; shift 2;;
    --ks-pass)      KS_PASS="$2"; shift 2;;
    --key-pass)     KEY_PASS="$2"; shift 2;;
    --key-alias)    KEY_ALIAS="$2"; shift 2;;
    --keep-tmp)     KEEP_TMP=1; shift;;
    -h|--help)      sed -n '2,40p' "$0"; exit 0;;
    *) echo "gradleless: unknown argument: $1" >&2; echo "try: gradleless.sh --help" >&2; exit 1;;
  esac
done

fail() { echo "gradleless: ERROR: $1" >&2; exit 1; }

[ -n "$SRC" ] || fail "missing --src <project-dir>"
[ -n "$OUT" ] || fail "missing --out <app.apk>"
[ -d "$SRC" ] || fail "source dir not found: $SRC"
[ -f "$SRC/AndroidManifest.xml" ] || fail "no AndroidManifest.xml in $SRC"
[ -d "$SRC/res" ] || fail "no res/ dir in $SRC"

# Validate package id looks sane (aapt2 rejects garbage late; fail fast instead)
case "$PACKAGE" in
  *[!a-zA-Z0-9._]*|""|.*|*..*|*.) fail "bad --package '$PACKAGE' (use like com.example.app)";;
esac
case "$VCODE" in ''|*[!0-9]*) fail "--version-code must be an integer, got '$VCODE'";; esac

# ---------- environment ----------
: "${JAVA_HOME:=$HOME/workspace/tools/jdk-17.0.20.1+1}"
: "${ANDROID_BT:=$HOME/Android/sdk/build-tools/34.0.0}"
: "${ANDROID_JAR:=$HOME/Android/sdk/platforms/android-34/android.jar}"
export PATH="$JAVA_HOME/bin:$PATH"

[ -x "$JAVA_HOME/bin/javac" ] || fail "javac not found under JAVA_HOME=$JAVA_HOME (need JDK 17+)"
for t in aapt2 d8 zipalign apksigner; do
  [ -x "$ANDROID_BT/$t" ] || fail "$t not found in ANDROID_BT=$ANDROID_BT"
done
[ -f "$ANDROID_JAR" ] || fail "android.jar not found: $ANDROID_JAR"

# ---------- staging ----------
B="$(mktemp -d /tmp/gradleless_XXXXXX)"
mkdir -p "$B/gen" "$B/classes" "$B/dex"
if [ "$KEEP_TMP" -eq 0 ]; then
  trap 'rm -rf "$B"' EXIT
else
  echo "gradleless: keeping temp dir: $B"
fi

# Copy project so placeholder substitution never touches the original
cp -r "$SRC/." "$B/stage/"
chmod -R u+w "$B/stage"

# Substitute {{PACKAGE}} / {{APP_NAME}} placeholders if the template uses them
sed_escape() { printf '%s' "$1" | sed -e 's/[&\/\\]/\\&/g'; }
PKG_ESC="$(sed_escape "$PACKAGE")"; NAME_ESC="$(sed_escape "$APP_NAME")"
if grep -rq '{{PACKAGE}}\|{{APP_NAME}}' "$B/stage" 2>/dev/null; then
  grep -rl '{{PACKAGE}}\|{{APP_NAME}}' "$B/stage" | while IFS= read -r f; do
    sed -i "s/{{PACKAGE}}/$PKG_ESC/g; s/{{APP_NAME}}/$NAME_ESC/g" "$f"
  done
  echo "gradleless: substituted placeholders (package=$PACKAGE, name=$APP_NAME)"
fi
S="$B/stage"

echo "gradleless: building $APP_NAME ($PACKAGE) v$VNAME ($VCODE) -> $OUT"

# ---------- 1. aapt2 compile + link ----------
echo "== [1/5] aapt2 compile =="
"$ANDROID_BT/aapt2" compile --dir "$S/res" -o "$B/compiled.zip"

echo "== [2/5] aapt2 link =="
LINK_ARGS="-o $B/base.apk -I $ANDROID_JAR --manifest $S/AndroidManifest.xml"
LINK_ARGS="$LINK_ARGS --min-sdk-version $MINSDK --target-sdk-version $TARGETSDK"
LINK_ARGS="$LINK_ARGS --version-code $VCODE --version-name $VNAME --java $B/gen"
if [ -d "$S/assets" ] && [ -n "$(ls -A "$S/assets" 2>/dev/null)" ]; then
  LINK_ARGS="$LINK_ARGS -A $S/assets"
fi
# shellcheck disable=SC2086
"$ANDROID_BT/aapt2" link $LINK_ARGS "$B/compiled.zip"

# ---------- 2. javac -> d8 ----------
echo "== [3/5] javac =="
CP="$ANDROID_JAR"
if ls "$S"/libs/*.jar >/dev/null 2>&1; then
  for j in "$S"/libs/*.jar; do CP="$CP:$j"; done
  echo "gradleless: extra jars on classpath: $(ls "$S"/libs/*.jar | wc -l)"
fi
JAVA_FILES="$(find "$B/gen" "$S/java" -name '*.java' 2>/dev/null)"
[ -n "$JAVA_FILES" ] || fail "no .java sources found (need java/ dir or generated R.java)"
# shellcheck disable=SC2086
javac -encoding UTF-8 -nowarn -cp "$CP" -d "$B/classes" $JAVA_FILES

echo "== [4/5] d8 (dex) =="
D8_INPUTS="$(find "$B/classes" -name '*.class')"
if ls "$S"/libs/*.jar >/dev/null 2>&1; then
  D8_INPUTS="$D8_INPUTS $(ls "$S"/libs/*.jar)"
fi
# shellcheck disable=SC2086
"$ANDROID_BT/d8" --lib "$ANDROID_JAR" --min-api "$MINSDK" --output "$B/dex" $D8_INPUTS

# ---------- 3. package + align + sign ----------
echo "== [5/5] package, align, sign =="
(cd "$B/dex" && zip -q -j ../base.apk classes.dex)
if [ -d "$S/jniLibs" ] && [ -n "$(ls -A "$S/jniLibs" 2>/dev/null)" ]; then
  # APKs expect lib/<abi>/*.so ; accept the Gradle-style jniLibs/ layout
  mkdir -p "$B/libstage/lib"
  cp -r "$S"/jniLibs/. "$B/libstage/lib/"
  (cd "$B/libstage" && zip -q -0 -r "$B/base.apk" lib)
  echo "gradleless: packaged native libs from jniLibs/"
fi
"$ANDROID_BT/zipalign" -f -p 4 "$B/base.apk" "$B/aligned.apk"

if [ ! -f "$KEYSTORE" ]; then
  echo "gradleless: creating debug keystore at $KEYSTORE"
  mkdir -p "$(dirname "$KEYSTORE")"
  keytool -genkeypair -keystore "$KEYSTORE" -alias "$KEY_ALIAS" -keyalg RSA \
    -keysize 2048 -validity 10950 -storepass "$KS_PASS" -keypass "$KEY_PASS" \
    -dname "CN=gradleless-debug, OU=gradleless, O=gradleless, C=US" 2>/dev/null \
    || fail "keytool failed to create keystore"
fi
mkdir -p "$(dirname "$OUT")"
"$ANDROID_BT/apksigner" sign --ks "$KEYSTORE" --ks-pass "pass:$KS_PASS" \
  --ks-key-alias "$KEY_ALIAS" --key-pass "pass:$KEY_PASS" \
  --v1-signing-enabled true --v2-signing-enabled true \
  --out "$OUT" "$B/aligned.apk"

# ---------- verify ----------
echo "== verify =="
"$ANDROID_BT/apksigner" verify "$OUT" \
  || fail "apksigner verify FAILED for $OUT"
echo "gradleless: signature OK"
"$ANDROID_BT/aapt" dump badging "$OUT" | grep -E "^(package|launchable-activity):" \
  || fail "aapt dump badging found no package/launchable-activity"
ls -la "$OUT"
echo "GRADLELESS_OK: $OUT"
