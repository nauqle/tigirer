# Arayüz cila turu: görsel kanıt

Kapsanan iş: tasarım dili ("Gece Serası", `design/design-language.md`), yeni yazı tipleri ve ikon seti, Türkçe + İngilizce, gün-gece manzarası, yeniden
tasarlanan HUD / gezinme / çiftlik / lab / pazar / Seed-Dex / geliştir / ayarlar / hedefler / açılış kartı / çevrimdışı özeti. Hikâye dosyası yok
(`minimal` kip): tasarım kaydı `design/game-brief.md` ve `design/design-language.md`, mimari `docs/architecture/floralab-architecture.md`.

Run result: OBSERVED — tüm ekranlar iki dilde 1080x1920 ve 1080x2400'de çiziliyor; en büyük yazıda (×1.4) metin ve düğmeler ekran genişliğine sığıyor;
renk körlüğü paleti mavi/turuncu; hareketi azalt açıkken çiftlik sabit; metin sembol glifi (◆ ▲ ▼ ★ ✓) hiçbir yerde yok (görüntülerdeki üçgen, yıldız ve onay işaretleri SVG ikonudur) — `production/qa/evidence/ui-polish/tr-farm.png`

## Görüntüler

Gerçek çizimle (başsız değil), GL Compatibility, `--write-movie` 75. karesi. Hepsini baştan üretir: `bash tools/capture_ui_evidence.sh [önek]`
(sahne `src/dev/ui_showcase.tscn`; durumu yalnızca oyun komutlarıyla hazırlar, arayüz `Main`'dir).

| Dosya | Ne gösteriyor |
|---|---|
| `tr-farm`, `en-farm` | Çiftlik: cam çerçeveli ızgara, akan sulama damlacıkları, olgun bitkide halka + ışıltı, FLORA ipucu, Sula/Hasat/Ekim, tohum tepsisi, hedef çipi |
| `tr-lab`, `en-lab` | Lab: iki ebeveyn "kavanozu", DNA simgesi, çaprazlama düğmesi (fiyat çipli), FLORA ipucu |
| `tr-market`, `en-market` | Pazar: fiyat tablosu (mini grafik + yüzde), borsa haberleri, ürün satırları, VIP sipariş biletleri |
| `tr-dex`, `en-dex` | Seed-Dex: tamamlanma halkası, nadirlik çerçeveli kartlar, kilitli yer tutucular |
| `tr-upgrades`, `en-upgrades` | Geliştir: lab UV odası, kat kartları, seviye noktaları, "tamam" rozetleri, alınabilir/alınamaz düğme ayrımı |
| `tr-settings`, `en-settings` | Ayarlar alt sayfası: dil seçici, anahtarlar, yazı boyutu, nasıl oynanır |
| `tr-goals`, `en-goals` | Hedefler sayfası: tamamlanan, etkin (ilerleme çubuğu), kilitli hedefler ve ödülleri |
| `tr-intro`, `en-intro` | FLORA açılış kartı |
| `tr-toasts`, `en-toasts` | Geri bildirim: haber, yeni tür ve hedef bildirimleri (diğer karelerde bildirimler bilerek temizlenir) |
| `tr-offline` | Çevrimdışı özeti: sayarak yükselen kazanç |
| `tr-fresh-start` | Yeni oyun |
| `tr-tall-farm`, `en-tall-market` | 1080×2400 uzun ekran |
| `tr-largest-text-market`, `en-largest-text-upgrades`, `en-largest-text-lab` | en büyük yazı (×1.4) |
| `tr-colorblind-farm` | renk körlüğü paleti |
| `en-reduced-motion-farm` | hareketi azalt |

## Ne görüldü, ne bulunup düzeltildi

1. **Eski görünüm "AI slop"tu:** her yüzey aynı turkuaz çerçeveli kart, her satın alma düğmesi aynı parlak yeşil dilim, kredi `◆` metin glifi, varsayılan font, ikon yok.
   Tasarım dili belgesi ve belirteçler yazıldı; ekran başına tek birincil düğme kuralı getirildi.
2. **Yazı/font hataları:** metinde cihazın yedek fontuna bağımlı sembol glifleri vardı (Android'de çarpı/kutu çıkabilir). Glifler kaldırıldı, ikon ve `{c}` kredi işareti kullanılıyor; paketlenen yazı
   tiplerinin her karakteri testle doğrulanıyor (Türkçe İ ı Ğ ğ Ş ş dahil).
3. **Bildirimler:** aynı bildirim üç kez üst üste yığılıyordu ("Yeni varyant keşfedildi!" ×3); artık tek hap "×N".
4. **Fiyatlı düğmeler en büyük yazıda çöküyordu** (`Button` kendi en az boyutunu yerel kodda tanımlar, betik sanal metodu çağrılmaz). `PriceButton` genişliği içerikten eşitliyor;
   gerileme testi `test_market_rows_and_buttons_stay_inside_the_screen_at_the_largest_text_in_both_languages` (düzeltmeden önce başarısız görüldü: düğme 56 px).
5. **Ayarlar'daki "Titreşim" anahtarı hiçbir şey yapmıyordu:** `HapticsService` eklendi (hasat, ödül, hata, mutasyon).
6. **Kaydırması zor oyuncular için yol yoktu:** "Hasat" düğmesi (tek dokunuşla toplu hasat, kombo ödülüyle).
7. **Oturum hedefsizdi:** 15 hedefli sıralı zincir, HUD çipi, hedefler sayfası ve FLORA açılış kartı.
8. **Görüntülerden bulunan iki kusur:** (a) HUD'daki yüzen "+N" kazancı, sayı hâlâ sayarken sayının üstüne biniyordu ("+4000" ile "4.160" iç içe); `CreditTag.final_width()` ile yan tarafa konuyor
   (`credit_tag_test.gd`, düzeltmeden önce başarısız görüldü). (b) Pazar'daki haber kartı etkin olayı hem ayrıntılı satırla hem "geçmiş" listesinde iki kez gösteriyordu;
   geçmiş artık yalnızca bitmiş olayları anıyor (`test_the_news_card_shows_an_active_headline_once_not_again_as_history`, düzeltmeden önce başarısız görüldü).
9. **Sessiz oyun:** efektlerin altında çok alçak, dikişsiz bir sera uğultusu döngüsü eklendi (ses ayarına bağlı; `audio_service_ambience_test.gd`). Görüntüde görünmez.

## Bu görüntüler neyi kapsar, neyi kapsamaz

- **Kapsar:** yerleşim, taşma/kırpılma, okunabilirlik, iki dil, üç boyut/ölçek, palet, nadirlik çerçeveleri, ikonlar, yazı tipleri.
- **Kapsamaz:** hareketin hissi (pop, sayaç, paralaks, titreşen pencereler, parçacıklar tek karede görünmez), ses, titreşim, gerçek cihazın güvenli alanı ve performansı,
  İngilizce metnin ana dili İngilizce olan biri tarafından redaksiyonu. Gösterim sahnesi durumu hazırlarken oluşan bildirim ve "+N" yüzenlerini temizler
  (`ToastLayer.clear`, `HudBar.clear_floats`); bildirimler yalnızca `*-toasts` karelerinde görünür.

## Damga

```bash
bash .claude/scripts/review-receipts.sh hash src/ui/main.gd src/ui/common/ui_tokens.gd src/ui/common/ui_theme.gd src/ui/common/ui_kit.gd src/ui/common/price_button.gd \
  src/ui/common/nav_bar.gd src/ui/common/night_backdrop.gd src/ui/hud/hud_bar.gd src/ui/panels/farm_panel.gd src/ui/panels/lab_panel.gd src/ui/panels/market_panel.gd \
  src/ui/panels/dex_panel.gd src/ui/panels/upgrades_panel.gd src/ui/panels/settings_overlay.gd src/ui/panels/goals_overlay.gd src/ui/farm/farm_view.gd \
  src/ui/common/credit_tag.gd src/ui/common/toast_layer.gd src/ui/audio/audio_service.gd src/ui/audio/sfx_bank.gd src/dev/ui_showcase.gd > production/qa/evidence/ui-polish/stamp.txt
```
