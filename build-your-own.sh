#!/usr/bin/env bash
#
# Build your own copy of this watch face with YOUR logo.
# Works on any Linux distro and on Windows via WSL (run it inside the WSL/Linux shell).
#
#   1) Put your logo at:  assets/logo.png   (PNG; white-on-transparent looks best,
#                         but plain dark-on-white art works too. Leave it out for a blank slot.)
#   2) Run:               ./build-your-own.sh
#   3) Sideload:          copy the two .prg files from bin/ to GARMIN/Apps/ on the watch.
#
# Requirements (the script checks and tells you what's missing):
#   - Connect IQ SDK with the "venu445mm" device installed
#       https://developer.garmin.com/connect-iq/sdk/  (use the SDK Manager to add the device)
#   - python3 + Pillow      (pip install pillow)
#   - openssl  and  java    (java is needed by the Connect IQ compiler)
#
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

DEVICE="venu445mm"                     # Venu 4 45mm (454x454) — the size this face is designed for
say() { printf '%s\n' "$*"; }
die() { printf '\n[ERROR] %s\n' "$*" >&2; exit 1; }

# ---- 1. prerequisites -------------------------------------------------------
command -v python3 >/dev/null || die "python3 not found. Install Python 3."
python3 - <<'PY' 2>/dev/null || die "Python 'Pillow' not found. Install it:  python3 -m pip install pillow"
import PIL  # noqa
PY
command -v openssl >/dev/null || die "openssl not found. Install it (package: openssl)."
command -v java    >/dev/null || die "java not found. Install a JRE/JDK (the Connect IQ compiler needs Java)."

# ---- 2. locate the Connect IQ SDK ------------------------------------------
MONKEYC=""
if [ "${CIQ_SDK_HOME:-}" != "" ] && [ -x "$CIQ_SDK_HOME/bin/monkeyc" ]; then
  MONKEYC="$CIQ_SDK_HOME/bin/monkeyc"
else
  # newest SDK under the standard install location
  MONKEYC="$(ls -d "$HOME"/.Garmin/ConnectIQ/Sdks/*/bin/monkeyc 2>/dev/null | sort -V | tail -1 || true)"
fi
[ -n "$MONKEYC" ] && [ -x "$MONKEYC" ] || die \
"Connect IQ SDK not found.
   Install it from https://developer.garmin.com/connect-iq/sdk/ and add the '$DEVICE' device
   via the SDK Manager, then re-run. If installed in a custom path, set CIQ_SDK_HOME, e.g.:
     export CIQ_SDK_HOME=\$HOME/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-x.y.z"
say "Using SDK compiler: $MONKEYC"

DEVDIR="$HOME/.Garmin/ConnectIQ/Devices/$DEVICE"
[ -d "$DEVDIR" ] || say "[warn] device '$DEVICE' not found at $DEVDIR — if the build fails, add it in the SDK Manager."

# ---- 3. signing key (generate once if absent) ------------------------------
KEY="$ROOT/developer_key.der"
if [ ! -f "$KEY" ]; then
  say "Generating a developer signing key (one-time): developer_key.der"
  tmp="$(mktemp)"
  openssl genrsa -out "$tmp" 4096 >/dev/null 2>&1
  openssl pkcs8 -topk8 -inform PEM -outform DER -nocrypt -in "$tmp" -out "$KEY" >/dev/null 2>&1
  rm -f "$tmp"
  [ -f "$KEY" ] || die "key generation failed (check openssl)."
fi

# ---- 4. composite your logo onto the dial ----------------------------------
if [ -f "$ROOT/assets/logo.png" ]; then say "Logo: assets/logo.png"; else
  say "[note] assets/logo.png not found — building with an empty logo slot."; fi
python3 tools/place_logo.py

# ---- 5. package both faces -------------------------------------------------
mkdir -p bin
say "Packaging (with date widget)…"
cp -f resources/drawables/dial_widget.png resources/drawables/dial.png
"$MONKEYC" -d "$DEVICE" -f monkey_widget.jungle -o bin/FieldInverted-Widget.prg -y "$KEY"
say "Packaging (plain '3', no widget)…"
cp -f resources/drawables/dial_plain.png  resources/drawables/dial.png
"$MONKEYC" -d "$DEVICE" -f monkey_plain.jungle  -o bin/FieldInverted-Plain.prg  -y "$KEY"

say ""
say "Done. Built:"
ls -1 "$ROOT"/bin/*.prg
say ""
say "Sideload: connect the watch (MTP), then copy a .prg into  GARMIN/Apps/  and restart the face."
