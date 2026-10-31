# FloraLab: Cyber Harvest: release APK

| Alan | Değer |
|---|---|
| Dosya | `FloraLab-CyberHarvest-1.2.0.apk` |
| Paket / sürüm | `com.tigirer.floralab` · 1.2.0 (kod 3) |
| Mimari / Android | arm64-v8a · minSdk 24 (Android 7+) |
| İzinler | yok |
| İmza | release anahtarı (APK Signature Scheme v2 + v3). Anahtar deposu depoda YOK ve geçici kapta üretildi: mağaza yayını/güncelleme zinciri için kendi anahtarınla yeniden imzala |
| SHA-256 | `2f63bc8eadb36729c5ce46fb89b6d594976a7b6ef1f11fa241b7665bacb3b72f` |

Kaynaktan üretmek: `README.md` → "FloraLab" bölümü (`godot --headless --export-release "Android Release" ...`).
Doğrulama kapsamı ve sınırlar (gerçek cihazda denenmedi): `docs/architecture/floralab-architecture.md` bölüm 13 ve 15.

**1.2.0 (2.5D çiftlik):** çiftlik artık gerçek 3D sahne (cam kutu, raflar, saksılar, akan sulama boruları, UV huzmeleri, 3D dronlar, perspektif kamera,
gün/gece ışığı); oynanış düzlemde aynı (dokun, kaydır). Bitki sanatı değişmedi. Karar ve gerekçe: `docs/architecture/floralab-architecture.md` §7.5.
**Cihazda kare hızı ve pil ölçülmedi** (yalnızca yazılım OpenGL'de çizildi); düşük sınıf cihazda 4×4 katta yavaş olabilir, ilk kısma önerileri aynı belgede (bölüm 15).
**1.1.0 (cila turu):** tasarım dili, yeni yazı tipleri, Türkçe + İngilizce, hedef sistemi ve FLORA açılışı, fiyat grafikleri, "Hasat" düğmesi, titreşim, sera uğultusu.
Önceki APK'lar git geçmişinde durur. İmza sertifikası (SHA-256 `4eacd394…62b5`) 1.0.0 ve 1.1.0 ile aynı: üzerine güncelleme olarak kurulur.
