# FAZ 2: hidroponik çiftlik: görsel kanıt

Kapsanan iş: `FarmView` (TileMapLayer ızgarası, saksı katmanı, büyüme/su çubukları, UV lambaları), kaydırarak hasat ve kombo
bildirimleri (`HarvestFx`), `DroneLayer` (hasat dronları), `CityBackdrop`. Hikâye dosyası yok (`minimal` kip): tasarım kaydı
`design/game-brief.md`, mimari `docs/architecture/floralab-architecture.md`.

Run result: OBSERVED — tek katlı çiftlik 1080x1920'de çiziliyor; saksılar büyüme evrelerine göre (tohum, filiz, olgun) farklı
görünüyor, su/büyüme çubukları saksının altında okunuyor, kaydırmayla hasatta "KOMBO ×2/×3" ve "+N" yazıları çıkıyor, dron
ızgaranın üstünde görünüyor — `production/qa/evidence/faz2-farm/02-swipe-combo.png`

## Görüntüler

Gerçek çizimle (başsız değil), GL Compatibility, 1080×1920, `--write-movie` son karesi.
Komut: `bash tools/capture_screenshot.sh res://src/dev/farm_dev.tscn <dosya> [--frames=N] -- …`

| Dosya | Ne gösteriyor | Seçenekler |
|---|---|---|
| `01-stages.png` | Altı saksı, farklı büyüme evrelerinde; sulama borusu ve UV lambaları | `--stages --irrigation --uv=1` |
| `02-swipe-combo.png` | Otomatik kaydırma üç bitkiyi biçti: "KOMBO ×2", "KOMBO ×3", +25/+17/+22 kazanç yazıları, parçacık patlaması | `--stages --irrigation --autoswipe=30` (70 kare) |
| `03-automation-drones.png` | Hasat dronu ızgaranın üstünde, çift hızda; bir saksı dron tarafından biçilip yeniden ekildi (+20) | `--stages --irrigation --drones=2 --speed=3` (120 kare) |

## Bu görüntüler neyi kapsar, neyi kapsamaz

- **Kapsar:** yerleşim, katmanların varlığı, evre görünümleri, çubukların okunabilirliği, kombo/kazanç yazıları.
- **Kapsamaz:** hareket ve his (dron uçuşu, parçacık, salınım): tek kare. Dev sahnesinin üstündeki boş şerit (başlık yazısı)
  bilinçli: asıl oyun yerleşimi için `faz5-ui/` görüntülerine bakın. Gerçek Android cihazda çalıştırma yapılmadı.

## Damga

```bash
bash .claude/scripts/review-receipts.sh hash src/ui/farm/farm_view.gd src/ui/farm/farm_tiles.gd src/ui/farm/pot_overlay.gd \
  src/ui/farm/drone_layer.gd src/ui/fx/harvest_fx.gd src/dev/farm_dev.gd src/dev/farm_dev.tscn > production/qa/evidence/faz2-farm/stamp.txt
```
