#!/usr/bin/env bash
# Godot + Android araç zincirini kurar. Ubuntu 24.04, root, internet erişimi (GitHub sürümleri,
# dl.google.com, apt) gerekir. Tekrar çalıştırılabilir: kurulu olanı atlar.
#
#   bash tools/setup-godot-android.sh
#
# Ortam değişkenleri (hepsi isteğe bağlı):
#   GODOT_VERSION   Godot sürümü (varsayılan 4.7.2; GitHub'daki "<sürüm>-stable" etiketi)
#   GODOT_DIR       Editörün kurulacağı klasör (varsayılan /opt/godot/<sürüm>)
#   ANDROID_HOME    Android SDK klasörü (varsayılan /opt/android-sdk)
#   BIN_LINK        "godot" komutunun bağlantısı (varsayılan /usr/local/bin/godot)
#   WITH_TEMPLATES  1: Android + Linux dışa aktarma şablonları, ~1,2 GB indirme (varsayılan 1)
#   WITH_XVFB       1: sanal ekran + yazılımsal OpenGL, ekran görüntüsü almak için (varsayılan 1)
#
# Kurulumdan sonra:
#   godot --headless --path <proje> --import
#   godot --headless --path <proje> --export-debug "Android" <proje>/build/oyun.apk
#   xvfb-run -a -s "-screen 0 1080x1920x24" godot --path <proje> --rendering-driver opengl3 -- --shot=/yol/ekran.png
#
# Android projesinde ETC2/ASTC doku sıkıştırması şarttır (project.godot, [rendering] bölümü):
#   textures/vram_compression/import_etc2_astc=true
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.7.2}"
TAG="${GODOT_VERSION}-stable"
GODOT_DIR="${GODOT_DIR:-/opt/godot/${GODOT_VERSION}}"
ANDROID_HOME="${ANDROID_HOME:-/opt/android-sdk}"
BIN_LINK="${BIN_LINK:-/usr/local/bin/godot}"
WITH_TEMPLATES="${WITH_TEMPLATES:-1}"
WITH_XVFB="${WITH_XVFB:-1}"
BASE="https://github.com/godotengine/godot/releases/download/${TAG}"
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
# Godot 4.7'nin şablonu Android 16 (API 36) hedefler; doküman 35'i yazar, ikisi de kurulur.
# 34: Son Fener (yerel Android projesi) için.
SDK_PACKAGES=(
  "platform-tools"
  "build-tools;34.0.0" "build-tools;35.0.1" "build-tools;36.0.0"
  "platforms;android-34" "platforms;android-35" "platforms;android-36"
  "cmake;3.10.2.4988404" "ndk;28.1.13356709"
)

say() { printf '\n== %s\n' "$*"; }
export DEBIAN_FRONTEND=noninteractive
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

download() { # url hedef
  curl -fL --retry 3 --retry-delay 5 -sS -o "$2" "$1"
}

verify_sha512() { # dosya adı (WORK içinde, SHA512-SUMS.txt ile aynı klasörde)
  local name="$1" want got
  want="$(awk -v f="$name" '$2==f || $2=="*"f {print $1}' "$WORK/SHA512-SUMS.txt")"
  [ -n "$want" ] || { echo "SHA512-SUMS içinde $name yok" >&2; return 1; }
  got="$(sha512sum "$WORK/$name" | awk '{print $1}')"
  [ "$want" = "$got" ] || { echo "SHA512 UYUŞMUYOR: $name" >&2; return 1; }
  echo "SHA512 doğru: $name"
}

# --------------------------------------------------------------------- temel paketler
say "Temel paketler"
if ! command -v unzip >/dev/null || ! command -v curl >/dev/null; then
  apt-get update -qq && apt-get install -y -qq --no-install-recommends unzip curl ca-certificates
fi

# ------------------------------------------------------------------------------- JDK
say "JDK"
java_major() {
  command -v java >/dev/null || { echo 0; return; }
  java -XshowSettings:properties -version 2>&1 | awk -F' = ' '/java.specification.version/ {print $2; exit}'
}
if [ "$(java_major)" -lt 17 ] 2>/dev/null; then
  apt-get update -qq && apt-get install -y -qq --no-install-recommends openjdk-17-jdk-headless
fi
JAVA_HOME_DIR="${JAVA_HOME:-$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")}"
echo "JDK $(java_major) → $JAVA_HOME_DIR"

# ------------------------------------------------------------------------ Android SDK
say "Android SDK ($ANDROID_HOME)"
SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
if [ ! -x "$SDKMANAGER" ]; then
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  download "$CMDLINE_TOOLS_URL" "$WORK/cmdline-tools.zip"
  mkdir "$WORK/cmdline-tools"
  env -u UNZIP unzip -q "$WORK/cmdline-tools.zip" -d "$WORK/cmdline-tools"
  rm -rf "$ANDROID_HOME/cmdline-tools/latest"
  mv "$WORK/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
  chmod -R +x "$ANDROID_HOME/cmdline-tools/latest/bin"
fi
yes | "$SDKMANAGER" --licenses >/dev/null 2>&1 || true
"$SDKMANAGER" --install "${SDK_PACKAGES[@]}" 2>&1 | tr '\r' '\n' | grep -vE 'JAVA_TOOL|^\[' | tail -3 || true
for p in build-tools/36.0.0 platforms/android-36 ndk/28.1.13356709 platform-tools; do
  [ -e "$ANDROID_HOME/$p" ] || { echo "EKSİK Android bileşeni: $p" >&2; exit 1; }
done
if [ -d /etc/profile.d ] && [ -w /etc/profile.d ]; then
  printf 'export ANDROID_HOME=%s\n' "$ANDROID_HOME" > /etc/profile.d/android-sdk.sh
fi

# Godot'un APK imzalamak için kullandığı debug anahtarı (Android'in standart debug anahtarı)
KEYSTORE="$HOME/.android/debug.keystore"
if [ ! -f "$KEYSTORE" ]; then
  mkdir -p "$HOME/.android"
  keytool -genkeypair -keystore "$KEYSTORE" -storepass android -alias androiddebugkey -keypass android \
    -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US" >/dev/null 2>&1
  echo "debug anahtarı üretildi: $KEYSTORE"
fi

# --------------------------------------------------------------- sanal ekran (isteğe bağlı)
if [ "$WITH_XVFB" = "1" ]; then
  say "Sanal ekran ve yazılımsal OpenGL"
  apt-get update -qq
  apt-get install -y -qq --no-install-recommends xvfb xauth x11-utils libgl1-mesa-dri libglx-mesa0 libegl1 \
    libxcursor1 libxi6 libxrandr2 libxinerama1 libxkbcommon0 libfontconfig1
fi

# ------------------------------------------------------------------------- Godot editör
say "Godot $GODOT_VERSION editörü ($GODOT_DIR)"
GODOT_BIN="$GODOT_DIR/Godot_v${TAG}_linux.x86_64"
if [ ! -x "$GODOT_BIN" ]; then
  download "$BASE/SHA512-SUMS.txt" "$WORK/SHA512-SUMS.txt"
  download "$BASE/Godot_v${TAG}_linux.x86_64.zip" "$WORK/Godot_v${TAG}_linux.x86_64.zip"
  verify_sha512 "Godot_v${TAG}_linux.x86_64.zip"
  mkdir -p "$GODOT_DIR"
  env -u UNZIP unzip -q -o "$WORK/Godot_v${TAG}_linux.x86_64.zip" -d "$GODOT_DIR"
  chmod +x "$GODOT_BIN"
  rm -f "$WORK/Godot_v${TAG}_linux.x86_64.zip"
fi
mkdir -p "$(dirname "$BIN_LINK")"
ln -sf "$GODOT_BIN" "$BIN_LINK"
"$GODOT_BIN" --headless --version 2>&1 | grep -v JAVA_TOOL | head -1

# ------------------------------------------------------------- dışa aktarma şablonları
if [ "$WITH_TEMPLATES" = "1" ]; then
  say "Dışa aktarma şablonları (Android + Linux x86_64)"
  TPL_DIR="$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.stable"
  if [ "$(cat "$TPL_DIR/version.txt" 2>/dev/null || true)" = "${GODOT_VERSION}.stable" ] && [ -f "$TPL_DIR/android_debug.apk" ]; then
    echo "şablonlar zaten kurulu: $TPL_DIR"
  else
    [ -f "$WORK/SHA512-SUMS.txt" ] || download "$BASE/SHA512-SUMS.txt" "$WORK/SHA512-SUMS.txt"
    download "$BASE/Godot_v${TAG}_export_templates.tpz" "$WORK/Godot_v${TAG}_export_templates.tpz"
    verify_sha512 "Godot_v${TAG}_export_templates.tpz"
    # İndirilen paket güvenilmez veri sayılır: yalnızca düz dosya adlarına izin verilir.
    python3 -I - "$WORK/Godot_v${TAG}_export_templates.tpz" "$TPL_DIR" <<'PY'
import os, re, sys, zipfile
tpz, dest = sys.argv[1], sys.argv[2]
name_ok = re.compile(r'^templates/([A-Za-z0-9._-]+)$')
want = re.compile(r'^(android_.*|linux_(debug|release)\.x86_64|version\.txt)$')
os.makedirs(dest, exist_ok=True)
count = 0
with zipfile.ZipFile(tpz) as z:
    for info in z.infolist():
        m = name_ok.match(info.filename)
        if info.is_dir() or not m or not want.match(m.group(1)):
            continue
        out = os.path.join(dest, m.group(1))
        with z.open(info) as src, open(out, "wb") as dst:
            while True:
                chunk = src.read(1 << 20)
                if not chunk:
                    break
                dst.write(chunk)
        if m.group(1).startswith("linux_"):
            os.chmod(out, 0o755)
        count += 1
print("%d şablon dosyası çıkarıldı → %s" % (count, dest))
PY
    rm -f "$WORK/Godot_v${TAG}_export_templates.tpz"
  fi
fi

# --------------------------------------------------------- Godot düzenleyici ayarları
say "Godot düzenleyici ayarları"
MAJMIN="$(echo "$GODOT_VERSION" | cut -d. -f1,2)"
SETTINGS="$HOME/.config/godot/editor_settings-${MAJMIN}.tres"
if [ ! -f "$SETTINGS" ]; then
  "$GODOT_BIN" --headless --quit >/dev/null 2>&1 || true   # ayar dosyasını Godot'a ürettir
fi
[ -f "$SETTINGS" ] || { echo "Godot ayar dosyası oluşmadı: $SETTINGS" >&2; exit 1; }
python3 -I - "$SETTINGS" "$ANDROID_HOME" "$JAVA_HOME_DIR" "$KEYSTORE" <<'PY'
import re, sys
path, sdk, jdk, keystore = sys.argv[1:5]
values = {
    "export/android/android_sdk_path": sdk,
    "export/android/java_sdk_path": jdk,
    "export/android/debug_keystore": keystore,
    "export/android/debug_keystore_user": "androiddebugkey",
    "export/android/debug_keystore_pass": "android",
}
text = open(path, encoding="utf-8").read()
for key, val in values.items():
    line = '%s = "%s"' % (key, val)
    pat = re.compile(r'^' + re.escape(key) + r' = .*$', re.M)
    text = pat.sub(lambda m: line, text) if pat.search(text) else text.rstrip("\n") + "\n" + line + "\n"
open(path, "w", encoding="utf-8").write(text)
print("Android ayarları yazıldı:", path)
PY

say "Hazır"
echo "godot: $BIN_LINK → $GODOT_BIN"
echo "ANDROID_HOME: $ANDROID_HOME"
