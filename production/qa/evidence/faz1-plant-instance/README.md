# FAZ 1: katmanlı bitki çizimi ve genetik laboratuvarı: görsel kanıt

Kapsanan iş: `PlantInstance` (gövde + yaprak + çiçek/meyve katmanları, genetik renk, mutasyon parlaması, büyüme evreleri),
`canvas_plant_tint.gdshader`, `SignalBus` olayları ve onları bir araya getiren geliştirici laboratuvarı
(`src/dev/genetics_lab.tscn`). Hikâye dosyası yok (`minimal` kip): tasarım kaydı `design/game-brief.md`,
mimari `docs/architecture/floralab-architecture.md`.

Run result: OBSERVED — Laboratuvar 1080x1920'de iki ebeveyn ve sekiz çocuğu çerçevenin içinde çiziyor; bilgi yazıları okunur ve düğmelerle çakışmıyor; mutasyon bandı, parlayan halo ve ★ etiketi görünüyor — `production/qa/evidence/faz1-plant-instance/02-lab-mutation-adopted.png`

## Görüntüler

Hepsi gerçek çizimle (başsız değil), GL Compatibility, 1080×1920, `--write-movie` son karesi (40. kare). Çekim tohumludur:
`01` aynı komutla yeniden çekildiğinde bayt bayt aynı çıktı.

| Dosya | Ne gösteriyor | Komut (`bash tools/capture_screenshot.sh res://src/dev/genetics_lab.tscn <dosya> -- …`) |
|---|---|---|
| `01-lab-carrier-cross.png` | İki aynı "Siber Taşıyıcı" ebeveyn (görünüşte sarmaşık gövde/eğrelti/yıldız çiçek, çekinik siber alelleri gizli taşıyor) ve sekiz çocuk: gövde, çiçek ve ton ayrışması gözle görülüyor. Durum satırı: "olasılık %5" | `--seed=3 --cross=1` |
| `02-lab-mutation-adopted.png` | UV bonusu açık (+%20), çaprazlamada **Biyolüminesan** mutasyonu çıktı: başlık bandı `SignalBus.mutation_discovered` ile açıldı; parlayan çocuk (5. sıra) dokunmanın karşılığı olarak **Ebeveyn A** yapıldı: halo, "★ Biyolüminesan · nesil 1" | `--seed=11 --cross=1 --bonus --adopt=5` |
| `03-lab-growth-035.png` | Aynı bitkiler filiz evresinde (büyüme %35): uzamış gövde, yalnızca ilk yaprak, meyve yok | `--seed=3 --cross=1 --growth=0.35` |
| `04-lab-growth-000.png` | Tohum evresi (büyüme %0): yalnızca kısa gövde sapı | `--seed=3 --cross=1 --growth=0.0` |

## Ne görüldü, ne bulunup düzeltildi

Gözle bakmanın bulduğu, testlerin bulamayacağı kusurlar (kaldırılmadan önce görülüp düzeltildi):

1. İlk çekimde iki saf ebeveynin çocukları birbirinin aynısıydı (Mendel'e göre doğru: F1 tekdüze). Laboratuvarın varsayılanı
   iki taşıyıcıya çevrildi; böylece ayrışma ilk bakışta görülüyor.
2. Alt sıra çocuklar ekranın altından taşıyordu: yerleşim 1080×1920 çerçevesine sığdırıldı.
3. Ebeveyn bilgi yazıları üst üste biniyor, B'nin yazısı sağdan kesiliyordu ve düğmeleri örtüyordu: yazılar sarılır hale
   getirildi, yerleşim 6 satıra yer ayıracak şekilde kaydırıldı (en kötü durum: B'nin 5 satırlı yazısı `01` ve `02`'de görülüyor).

## Bu görüntüler neyi kapsar, neyi kapsamaz

- **Kapsar:** yerleşim, taşma/kırpılma, katmanların varlığı ve konumu, renk, okunabilirlik, mutasyonun görsel işaretleri
  (halo, ★), büyüme evrelerinin görünümü.
- **Kapsamaz:** zamanlama ve his. Rüzgâr salınımı, "pop" animasyonu, parlama nabzı ve parıltı bandı hareket eder; tek bir kare
  bunları göstermez. Bunlar için `--write-movie` kare dizisi ya da elle bakış gerekir (Visual/Feel'in insan yarısı).
  Gerçek bir Android cihazda çalıştırma da yapılmadı (yalnızca APK dışa aktarma ve paket denetimi).

## Damga

`stamp.txt`, bu kanıtın baktığı dosyaların özetidir (`bash .claude/scripts/review-receipts.sh hash …`). Bu dosyalardan biri
sonradan değişirse kanıt koddan eski sayılır ve görüntüler yeniden çekilmelidir:

```bash
bash .claude/scripts/review-receipts.sh hash src/gameplay/plants/plant_instance.gd src/gameplay/plants/plant_instance.tscn \
  assets/shaders/canvas_plant_tint.gdshader src/dev/genetics_lab.gd src/dev/genetics_lab.tscn src/gameplay/events/signal_bus.gd > production/qa/evidence/faz1-plant-instance/stamp.txt
```
