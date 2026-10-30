# Test Infrastructure

**Engine**: Godot 4.7.2 (GDScript)
**Test framework (şu an)**: kendi küçük koşucumuz: `tests/support/test_runner.gd` + `tests/support/test_case.gd`
**Hedef framework**: gdUnit4 (şablonun standardı), bkz. aşağıdaki "gdUnit4 neden henüz yok"
**Setup date**: 2026-10-30

## Çalıştırma

```bash
bash tools/run_tests.sh                    # tüm testler
bash tools/run_tests.sh --filter=genetics  # yolu "genetics" içeren dosyalar
```

Çıkış kodları gdUnit4'ünkilerle aynı: `0` geçti, `100` başarısız, `105` test dosyası yüklenemedi, ek olarak `2` hiç
test bulunamadı (sıfır test bir "geçti" değildir). Godot çıktısında `SCRIPT ERROR` / `Parse Error` varsa çıkış kodu `1`'dir.

## Dizin düzeni

```
tests/
  unit/           # İzole birim testleri (formüller, durum makineleri, mantık), sistem başına bir alt klasör
  integration/    # Sistemler arası ve kayıt/yükleme testleri
  smoke/          # /smoke-check kapısı için kritik yol listesi
  support/        # Geçici koşucu ve test tabanı (gdUnit4 gelince silinir)
production/qa/
  evidence/       # Ekran görüntüleri ve elle test onay kayıtları
```

## Adlandırma

`.claude/rules/test-standards.md` ile aynı: dosya `[sistem]_[özellik]_test.gd`, fonksiyon `test_[senaryo]_[beklenen]`,
her testte açık arrange / act / assert bölümleri.

## gdUnit4 neden henüz yok

Şablonun test komutu (`commands.test` in `project.yaml`) gdUnit4'ün koşucusunu çalıştırır ve
`.claude/skills/test-setup` onu editörün Asset Store'undan kurmayı anlatır. Bu çalışma ortamında gdUnit4'ü
GitHub'dan (`godot-gdunit-labs/gdUnit4`, v6.2.2, MIT) çekip depoya eklemek ve **kodunu çalıştırmak**, ortamın izin
denetleyicisi tarafından "Code from External" gerekçesiyle reddedildi. Dolanılmadı. Karar projenin sahibinindir.

- Onaylanırsa: addon `addons/gdUnit4/` altına kurulur, eklenti `project.godot` içinde etkinleştirilir, testler
  `extends GdUnitTestSuite` ile yeniden yazılır (doğrulamalar `assert_that(...)` biçimine çevrilir), CI iş akışı eklenir.
- Bu arada `project-coherence.sh` şu satırı **beklenen fark** olarak bildirir: `commands.test` gdUnit4'ün olmayan koşucusunu
  gösteriyor. `commands.test` bu farkı gizlemek için değiştirilmedi.
