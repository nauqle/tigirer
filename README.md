# Son Fener

Tek parmakla oynanan, Türkçe, dikey ekranlı bir Android savunma oyunu.

Kandil Burnu'nun fener bekçisisin. Her gece denizden sis yükselir ve gölgeler feneri söndürmek için kıyıya sürünür. Parmağınla ışığı yönlendir, enerjini yönet, şafağa dayan. Gölgeler dağılınca geriye kıvılcımlar, yani unutulmuş anılar kalır; onlarla fenerini güçlendir.

<p>
  <img src="docs/screenshots/menu.png" width="180" alt="Ana menü">
  <img src="docs/screenshots/kaptan-golge.png" width="180" alt="3. gece: Kaptan Gölge">
  <img src="docs/screenshots/sis-ana.png" width="180" alt="5. gece: Sis Ana">
  <img src="docs/screenshots/atolye.png" width="180" alt="Atölye">
  <img src="docs/screenshots/safak.png" width="180" alt="Şafak">
</p>

> Ekran görüntüleri, oyunun gerçek çizim koduyla test ortamında üretilmiştir (bkz. [Test](#test)).

## Kurulum

1. [`releases/SonFener-1.0.apk`](releases/SonFener-1.0.apk) dosyasını Android telefonuna indir (Android 7.0 ve üstü).
2. Dosyaya dokun. Android sorarsa o kaynaktan (tarayıcı ya da dosya yöneticisi) **bilinmeyen uygulama yüklemeye izin ver**.
3. Yükle ve **Son Fener**'i aç.

APK, Android'in otomatik test (debug) anahtarıyla imzalıdır; Play Store için değildir. Aynı uygulamanın başka bir makinede derlenmiş sürümünü üstüne yüklemek “imza uyuşmuyor” hatası verebilir. Böyle olursa önce eskisini kaldır.

## Nasıl oynanır

- **Ekrana dokun ve sürükle:** Işın parmağının yönüne döner. Parmağını kaldırırsan söner.
- **Işın enerji harcar.** Enerji bitince ışık ısınır, soğuyana kadar yanmaz.
- **Işıktaki gölgeler yavaşlar ve erir.** Fenere ulaşan gölge yağı azaltır; yağ biterse fener söner.
- **PARLAMA** (sağ alt): çevredeki bütün gölgelere vurur, geri iter ve zırhı deler.
- Şafağa dayan. 3. ve 5. gecede boss'u yen. Kıvılcımları atölyede harca.

Bütün kurallar, gölge/gece/geliştirme tabloları ve hikâyenin tamamı: **[docs/GAME_DESIGN.md](docs/GAME_DESIGN.md)**

## Derleme

Gereksinimler: JDK 17 veya üstü, Android SDK (platform `android-34`, build-tools `34.0.0`).

```bash
echo "sdk.dir=/Android/SDK/yolu" > local.properties   # ya da ANDROID_HOME ayarla
./gradlew assembleRelease
# çıktı: app/build/outputs/apk/release/app-release.apk
```

## Test

```bash
./gradlew testDebugUnitTest
```

- **Oyun mantığı** (`World`, kayıt, geliştirmeler) JVM'de test edilir.
- **Denge testleri**, bilgisayarın oynadığı bir bot'la geceleri yüzlerce kez oynar ve zorluk eğrisinin bozulmadığını doğrular.
- **Ekran testleri** (Robolectric, gerçek `Canvas`): her ekranı çizer, menüden ilk geceye uzanan akışı ve kazanma/kaybetme sonuçlarını dener; ekran görüntülerini `app/build/shots/` altına yazar. İlk çalıştırmada Robolectric, Android 14 paketini Maven'dan indirir.

## Proje yapısı

```
app/src/main/java/com/tigirer/sonfener/
  core/        Android'den bağımsız oyun mantığı (World, ShadowType, Upgrades, Levels, SaveData, Story)
  *Screen.java Menü, hikâye, atölye, oyun ve nasıl oynanır ekranları
  Gfx.java     Çizim yardımcıları (arka plan, fener, ışın, gölgeler)
  Sfx.java     Çalışma anında üretilen ses efektleri
app/src/test/  Birim, denge ve ekran testleri
docs/          Tasarım belgesi ve ekran görüntüleri
releases/      Derlenmiş APK
```

## Durum ve bilinen sınırlar

- Oyun **gerçek bir Android cihazda veya emülatörde çalıştırılmadı.** Doğrulama: birim testleri, bot simülasyonları, gerçek `Canvas` ile ekran çizimi ve APK'nın paket/imza kontrolü. **Ses ve titreşim gerçek donanımda denenmedi**; hata olursa sessizce devre dışı kalacak şekilde yazıldı.
- Denge bot'la ayarlandı; bir insanla test edilmedi. Sayılar yol göstericidir.
- Yalnızca dikey ekranı destekler.
