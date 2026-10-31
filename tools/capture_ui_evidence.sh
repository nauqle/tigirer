#!/usr/bin/env bash
# Arayüz görsel kanıtını (production/qa/evidence/ui-polish/) baştan üretir: her ekran Türkçe ve İngilizce, 1080x1920; ayrıca uzun ekran (1080x2400),
# en büyük yazı, renk körlüğü paleti ve hareketi azalt. Sahne: src/dev/ui_showcase.tscn (durumu yalnızca oyun komutlarıyla hazırlar).
#
#   bash tools/capture_ui_evidence.sh            # hepsi
#   bash tools/capture_ui_evidence.sh en-market  # adı bu metinle başlayanlar
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="production/qa/evidence/ui-polish"
SCENE="res://src/dev/ui_showcase.tscn"
FILTER="${1:-}"
shot() { # çıktı_adı boyut seçenekler...
  local name="$1" size="$2"
  shift 2
  if [ -n "$FILTER" ] && [[ "$name" != "$FILTER"* ]]; then return 0; fi
  CAPTURE_SIZE="$size" bash tools/capture_screenshot.sh "$SCENE" "$OUT/$name.png" --frames=75 -- "$@"
}
mkdir -p "$OUT"
for lang in tr en; do
  for scenario in farm lab market dex upgrades settings goals; do
    shot "$lang-$scenario" 1080x1920 --scenario="$scenario" --lang="$lang"
  done
done
shot tr-intro 1080x1920 --scenario=intro --lang=tr
shot en-intro 1080x1920 --scenario=intro --lang=en
shot tr-toasts 1080x1920 --scenario=toasts --lang=tr
shot en-toasts 1080x1920 --scenario=toasts --lang=en
shot tr-offline 1080x1920 --scenario=offline --lang=tr
shot tr-fresh-start 1080x1920 --scenario=fresh --lang=tr
shot tr-tall-farm 1080x2400 --scenario=farm --lang=tr
shot en-tall-market 1080x2400 --scenario=market --lang=en
shot tr-largest-text-market 1080x1920 --scenario=market --scale=3 --lang=tr
shot en-largest-text-upgrades 1080x1920 --scenario=upgrades --scale=3 --lang=en
shot en-largest-text-lab 1080x1920 --scenario=lab --scale=3 --lang=en
shot tr-colorblind-farm 1080x1920 --scenario=farm --colorblind --lang=tr
shot en-reduced-motion-farm 1080x1920 --scenario=farm --reduce-motion --lang=en
