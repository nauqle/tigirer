# Godot ortamı (bulut oturumları için)

Bu belge, bu depoda **Godot 4.7.2** ile oyun yapmak için gereken araç zincirini, neyin gerçekten denendiğini ve neyin denenmediğini kaydeder.

> Bulut oturumları geçicidir: oturum bitince kurulan araçlar silinir. Her yeni oturumda tek komut yeterlidir:
>
> ```bash
> bash tools/setup-godot-android.sh
> ```
>
> Sıfırdan kurulumda yaklaşık 2,5 GB indirir (tahminen 5–10 dakika; parçaları ölçüldü, bütünü ölçülmedi). Kurulu olanı atlar, tekrar çalıştırılabilir (ikinci çalıştırma 10 saniye sürdü).

## Kurulanlar

| Bileşen | Sürüm | Not |
|---|---|---|
| Godot editörü | 4.7.2 (kararlı) | `/opt/godot/4.7.2`, `godot` komutu. İndirme SHA512 ile doğrulanır. |
| Dışa aktarma şablonları | 4.7.2 | Yalnızca Android ve Linux x86_64 (~570 MB). |
| Android SDK | platform 34/35/36, build-tools 34.0.0/35.0.1/36.0.0, platform-tools, CMake 3.10.2, NDK r28b | Godot dokümanı 35.0.1'i ister; 4.7'nin şablonu API 36 hedefler, o yüzden ikisi de kurulur. |
| JDK | 17 veya üstü | Ortamda 21 var; yoksa betik OpenJDK 17 kurar. |
| Sanal ekran | Xvfb + Mesa (yazılımsal OpenGL) | Ekran görüntüsü almak için. GPU yok. |

Godot 4.7, benim eğitim bilgimden daha yenidir (4.4/4.5 civarı). Kod yazarken sürümler arası farklar için resmî dokümana (docs.godotengine.org) bakılır; bu ortamda erişilebilir.

## Bu oturumda gerçekten denenenler

Hepsi küçük bir deneme projesiyle denendi. **APK dışa aktarma** ayrıca, betikle sıfırdan kurulmuş temiz bir ortamda da yeniden denendi. Diğerleri bu oturumda elle kurduğum, aynı sürümdeki kurulumda koştu.

| Ne | Sonuç |
|---|---|
| Editör başsız çalışıyor (`--headless`) | Evet |
| Projeyi içe aktarma ve çalıştırma, betik çıktısı | Evet |
| Android **debug APK** dışa aktarma ve imzalama | Evet. arm64-v8a, targetSdk 36, v2+v3 imza geçerli, ~28 MB |
| Sanal ekranda çizim ve ekran görüntüsü | Evet. OpenGL Compatibility, `llvmpipe` (yazılımsal) |
| Dokunma olayı gönderip oyun koduna ulaştığını görme | Evet |
| GDScript sözdizimi ve tür denetimi (`--check-only`) | Evet. Hatalı dosyada sıfırdan farklı çıkış kodu verir |

## Denenmedi / bilinen sınırlar

- **Gerçek Android cihaz veya emülatör yok.** APK'nın telefonda açıldığı doğrulanmadı.
- **Ses doğrulanamaz.** Ortamda ses kartı yok, Godot sessiz sürücüye düşer.
- **Vulkan denenemez** (GPU yok). Projeler `gl_compatibility` ile kurulmalı.
- **Release/AAB ve Gradle yolu denenmedi.** Yalnızca Gradle'sız debug APK denendi. Play Store için AAB gerekirse ayrıca sınanmalı.
- Betiğin JDK 17'yi `apt` ile kurma dalı denenmedi (ortamda JDK 21 vardı).

## Tarifler

**Android APK (başsız):**

```bash
godot --headless --path <proje> --import
godot --headless --path <proje> --export-debug "Android" <proje>/build/oyun.apk
```

Gerekenler: projede `export_presets.cfg` içinde bir "Android" ön ayarı ve `project.godot` içinde, [rendering] bölümünde:

```
textures/vram_compression/import_etc2_astc=true
```

Bu satır olmazsa dışa aktarma "ETC2/ASTC required" hatasıyla durur.

**Ekran görüntüsü (sanal ekran):** oyuna bir `--shot=` argümanı okutup birkaç kare sonra görüntüyü kaydettirmek yeterli:

```gdscript
# birkaç kare sonra
await RenderingServer.frame_post_draw
get_viewport().get_texture().get_image().save_png(shot_path)
get_tree().quit()
```

```bash
xvfb-run -a -s "-screen 0 1080x1920x24" godot --path <proje> --rendering-driver opengl3 --resolution 540x960 -- --shot=/yol/ekran.png
```

**Dokunma testi:** `SceneTree` betiğiyle olay gönderilir. Olay konumları *pencere pikseli*dir; başsız modda pencere sahtedir ve oyunun ölçeklemesi uygulanır. Mantıksal koordinatı vermek için pencereye çevirmek gerekir:

```gdscript
extends SceneTree
func _initialize() -> void:
	# ... test edilecek düğümü root'a ekle ...
	await process_frame            # ağaç hazır olmadan push_input hata verir
	var to_window := root.get_final_transform()
	var e := InputEventScreenTouch.new()
	e.pressed = true
	e.position = to_window * Vector2(540, 960)   # mantıksal konum
	root.push_input(e)
	await process_frame
	quit(0)
```

```bash
godot --headless --path <proje> --script res://touch_test.gd
```

**Sözdizimi ve tür denetimi:** `godot --headless --path <proje> --check-only --script res://dosya.gd`
