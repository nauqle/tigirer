#!/usr/bin/env bash
# Bir sahneyi GERÇEK çizimle (başsız değil) açar ve son kareyi PNG olarak kaydeder: "çalıştır ve gözle" kanıtı.
# Yöntem: .claude/docs/run-and-observe.md (Godot 4: --write-movie + --quit-after).
#
#   bash tools/capture_screenshot.sh <sahne.tscn> <çıkış.png> [--frames=N] [-- sahne seçenekleri...]
#
# Örnek (genetik laboratuvarı, tohumlu çaprazlama, 1080x1920):
#   bash tools/capture_screenshot.sh res://src/dev/genetics_lab.tscn production/qa/evidence/faz1-plant-instance/01.png -- --seed=3 --cross=1
#
# Notlar:
# - project.godot'taki window_*_override (540x960, masaüstü geliştirme penceresi) --write-movie'yi yarıya indirir;
#   çekim süresince depo köküne geçici bir override.cfg konur (git tarafından yok sayılır) ve çıkışta silinir,
#   böylece kare tam 1080x1920 olur.
# - Ekran yoksa (bulut/CI) xvfb-run kullanılır; yoksa mevcut ekran kullanılır.
# - Çizim sürücüsü opengl3: Android'in kullandığı GL Compatibility ile aynı yol.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"

usage() {
  sed -n '2,8p' "$0" >&2
  exit 2
}

[ "$#" -ge 2 ] || usage
scene="$1"
output="$2"
shift 2
frames=40
while [ "$#" -gt 0 ]; do
  case "$1" in
    --frames=*) frames="${1#--frames=}"; shift ;;
    --) shift; break ;;
    *) usage ;;
  esac
done

work="$(mktemp -d)"
cleanup() {
  rm -f override.cfg "$work"/*.png "$work"/*.wav 2>/dev/null || true
  rmdir "$work" 2>/dev/null || true
}
trap cleanup EXIT

printf '[display]\nwindow/size/window_width_override=0\nwindow/size/window_height_override=0\n' > override.cfg

command_line=("$GODOT" --path . --windowed --resolution 1080x1920 --rendering-driver opengl3
  --write-movie "$work/frame.png" --quit-after "$frames" "$scene")
if [ "$#" -gt 0 ]; then
  command_line+=(-- "$@")
fi

if [ -z "${DISPLAY:-}" ] && command -v xvfb-run >/dev/null 2>&1; then
  xvfb-run -a -s "-screen 0 1080x1920x24" "${command_line[@]}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "ERROR|recording movie" || true
else
  "${command_line[@]}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "ERROR|recording movie" || true
fi

last_frame="$(ls "$work"/frame*.png 2>/dev/null | sort | tail -1)"
if [ -z "$last_frame" ]; then
  echo "HATA: hiç kare üretilmedi (sahne yolu doğru mu? Godot çökmüş olabilir)." >&2
  exit 1
fi
mkdir -p "$(dirname "$output")"
cp "$last_frame" "$output"
echo "kaydedildi: $output"
