# FAZ 5: mobil arayüz: görsel kanıt

Kapsanan iş: `Main` (HUD, beş sekme, ayarlar, çevrimdışı özeti, bildirimler), `FarmPanel`, `LabPanel`, `MarketPanel`, `DexPanel`,
`UpgradesPanel`, `UiTheme` (yazı ölçeği, renk körlüğü paleti). Hikâye dosyası yok (`minimal` kip): tasarım kaydı
`design/game-brief.md`, mimari `docs/architecture/floralab-architecture.md`.

Run result: OBSERVED — tüm ekranlar 1080x1920 ve 1080x2400'de çiziliyor: HUD, sekme çubuğu ve içerik ekranın içinde; en büyük
yazıda sekme çubuğu ve pazar paneli genişliğe sığıyor; renk körlüğü paleti mavi/turuncu — `production/qa/evidence/faz5-ui/05-large-text-market.png`

## Görüntüler

Gerçek çizimle (başsız değil), GL Compatibility, `--write-movie` son karesi. Hepsini baştan üretir: `bash tools/capture_faz5_evidence.sh`
(sahne `src/dev/ui_showcase.tscn`; durumu yalnızca oyun komutlarıyla hazırlar, UI'nin kendisi `Main`'dir).

| Dosya | Boyut | Ne gösteriyor |
|---|---|---|
| `01-fresh-start.png` | 1080×1920 | Yeni oyun: az kredi, boş çiftlik, ipucu satırı |
| `02-farm.png` | 1080×1920 | Çiftlik: kat seçici, "Hepsini Sula/Boşlara Ek", büyüme evreleri, tohum şeridi |
| `02-lab.png` | 1080×1920 | Laboratuvar: iki ebeveyn önizlemesi, özellik özeti, çaprazla düğmesi (+ "Yeni tür keşfedildi" bildirimleri) |
| `02-market.png` | 1080×1920 | Pazar: borsa haberleri, ürünler ve satış düğmeleri, VIP siparişler |
| `02-dex.png` | 1080×1920 | Seed-Dex: tamamlanma çubuğu, keşfedilen tür kartları, "?" yer tutucular |
| `02-upgrades.png` | 1080×1920 | Geliştir: sulama/UV/dron/kat satın alma, yetmeyen krediyle devre dışı düğmeler |
| `02-settings.png` | 1080×1920 | Ayarlar: ses, yazı boyutu, renk körlüğü, hareketi azalt, sıfırla (iki basışlı onay) |
| `02-offline.png` | 1080×1920 | Çevrimdışı özeti: 90 dk uzaklık, dron hasadı, bekleyen/aşırı olgun bitkiler |
| `03-tall-farm.png` | 1080×2400 | Uzun ekran: çiftlik alanı büyür, sekme çubuğu ekranın içinde |
| `04-tall-market.png` | 1080×2400 | Uzun ekranda pazar |
| `05-large-text-market.png` | 1080×1920 | En büyük yazı (×1.4): yatay taşma yok, sekme etiketleri sığıyor |
| `06-colorblind-farm.png` | 1080×1920 | Renk körlüğü paleti (mavi iyi / turuncu kötü), kırmızı-yeşile dayanmıyor |

## Ne görüldü, ne bulunup düzeltildi

Gözle bakmanın bulduğu, testlerin bulamayacağı kusurlar (hepsi düzeltildi):

1. Bildirimler dar bir harf sütunu gibi çiziliyordu (`set_anchors_preset` boyut vermez): `set_anchors_and_offsets_preset`.
2. Ayar düğmeleri soluk/devre dışı görünüyordu (toggle stili): düz düğme + tema varyasyonu geçişi.
3. En büyük yazıda sekme çubuğu 1067 px istiyordu (1032 px alan): tüm içerik sağa taştı. Sekme yazısı ölçeğin yalnızca %30'unu
   izliyor, etiketler kırpılabilir, "Laboratuvar" sekmesi "Lab" oldu. Gerileme testi:
   `test_the_largest_text_size_keeps_every_tab_button_inside_the_screen_width` (düzeltmeden önce başarısız görüldü: 1091 > 1080).
4. "Uzun ekran çekimi kırpılıyor" şüphesi: kusur arayüzde değil çekim aracındaydı (`--write-movie` kareyi pencereye değil projenin
   görüntü alanı boyutuna göre yazar). `tools/capture_screenshot.sh` artık görüntü alanını da `CAPTURE_SIZE`'a çekiyor.

## Bu görüntüler neyi kapsar, neyi kapsamaz

- **Kapsar:** yerleşim, taşma/kırpılma, okunabilirlik, üç ekran boyutu/ölçeği, renk körlüğü paleti.
- **Kapsamaz:** dokunma hissi, animasyon zamanlaması, gerçek cihazın güvenli alan/çentik değerleri (`_apply_safe_area` mobilde
  `DisplayServer.get_display_safe_area` okur; masaüstünde sabit boşluk kullanıldı), gerçek Android çalıştırması.
  Bildirimlerin pazar/laboratuvar üstüne binmesi geçici bildirim şeridinin doğal görünümüdür (süreleri dolunca kaybolur).

## Damga

```bash
bash .claude/scripts/review-receipts.sh hash src/ui/main.gd src/ui/main.tscn src/ui/common/ui_theme.gd src/ui/common/ui_kit.gd \
  src/ui/hud/hud_bar.gd src/ui/panels/farm_panel.gd src/ui/panels/lab_panel.gd src/ui/panels/market_panel.gd \
  src/ui/panels/dex_panel.gd src/ui/panels/upgrades_panel.gd src/ui/panels/settings_overlay.gd src/ui/panels/offline_popup.gd \
  src/dev/ui_showcase.gd src/dev/ui_showcase.tscn > production/qa/evidence/faz5-ui/stamp.txt
```
