#!/usr/bin/env bash
# FAZ 5 arayüz kanıtını (production/qa/evidence/faz5-ui/) baştan üretir: her ekran 1080x1920, ayrıca uzun ekran (1080x2400),
# en büyük yazı ve renk körlüğü paleti. Sahne: src/dev/ui_showcase.tscn (durumu yalnızca oyun komutlarıyla hazırlar).
#
#   bash tools/capture_faz5_evidence.sh
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="production/qa/evidence/faz5-ui"
SCENE="res://src/dev/ui_showcase.tscn"
shot() { # çıktı_adı boyut seçenekler...
  local name="$1" size="$2"
  shift 2
  CAPTURE_SIZE="$size" bash tools/capture_screenshot.sh "$SCENE" "$OUT/$name.png" -- "$@"
}
mkdir -p "$OUT"
shot 01-fresh-start 1080x1920 --scenario=fresh
shot 02-farm 1080x1920 --scenario=farm
shot 02-lab 1080x1920 --scenario=lab
shot 02-market 1080x1920 --scenario=market
shot 02-dex 1080x1920 --scenario=dex
shot 02-upgrades 1080x1920 --scenario=upgrades
shot 02-settings 1080x1920 --scenario=settings
shot 02-offline 1080x1920 --scenario=offline
shot 03-tall-farm 1080x2400 --scenario=farm
shot 04-tall-market 1080x2400 --scenario=market
shot 05-large-text-market 1080x1920 --scenario=market --scale=3
shot 06-colorblind-farm 1080x1920 --scenario=farm --colorblind
