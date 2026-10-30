#!/usr/bin/env bash
# Geçici birim test koşucusu sarmalayıcısı (gdUnit4 kurulana kadar; bkz. tests/README.md).
#
#   bash tools/run_tests.sh                 # tüm testler
#   bash tools/run_tests.sh --filter=genetics   # yolu "genetics" içeren test dosyaları
#
# Çıkış kodları gdUnit4 ile aynıdır: 0 geçti, 100 başarısız, 105 test dosyası yüklenemedi, 2 hiç test yok.
# Ek olarak: Godot çıktısında "SCRIPT ERROR" ya da "Parse Error" varsa çıkış kodu 1'dir. Godot bir çalışma
# zamanı hatasında testi sessizce bitirebilir; bu sarmalayıcı onu "geçti" saymaz.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
GODOT="${GODOT:-godot}"

# Sınıf önbelleği (.godot/global_script_class_cache.cfg) olmadan class_name çözülmez.
# Godot 4.7'de taze bir projedeki ilk içe aktarma bazen işini bitirip çıkışta çöker (139): bir kez daha dene.
"$GODOT" --headless --path . --import >/dev/null 2>&1 || "$GODOT" --headless --path . --import >/dev/null 2>&1

extra=()
[ "$#" -gt 0 ] && extra=(-- "$@")
output="$("$GODOT" --headless --path . -s res://tests/support/test_runner.gd "${extra[@]}" 2>&1)"
code=$?
printf '%s\n' "$output" | sed 's/\x1b\[[0-9;]*m//g' | grep -v "JAVA_TOOL"

if printf '%s\n' "$output" | grep -qE "SCRIPT ERROR|Parse Error|Failed to load script"; then
  echo "HATA: Godot çalışma sırasında betik hatası bildirdi (yukarıya bak)." >&2
  [ "$code" -eq 0 ] && code=1
fi
exit "$code"
