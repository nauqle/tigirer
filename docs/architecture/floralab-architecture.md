# FloraLab: Cyber Harvest — Mimari

> **Durum:** FAZ 1 (çekirdek veri mimarisi, genetik motoru, katmanlı bitki çizimi) uygulandı ve doğrulandı.
> FAZ 2–5 yalnızca plandır; aşağıda "planlı" diye işaretlenenler henüz yoktur.
> **Motor:** Godot 4.7.2 · GDScript (statik tipli) · GL Compatibility oluşturucu · Android dikey 1080×1920.
> **Tasarım kaydı:** `design/game-brief.md` (şablonun `minimal` kipi: ayrı GDD yok, kısa özet ve bu belge).
> **Sapmalar ve açık sorular:** bu belgenin 9. ve 10. bölümleri.

## 1. Fazlar ve durum

| Faz | Kapsam | Durum |
|---|---|---|
| 1 | `PlantGene` Resource, Mendel çaprazlama, %5 mutasyon, katmanlı `PlantInstance`, `SignalBus` | **Var, testli, ekran görüntülü** |
| 2 | Hidroponik ızgara, saksılar, `TimeManager`, büyüme evreleri, su/ışık çarpanları, kaydırarak hasat | Planlı |
| 3 | Dinamik borsa (arz-talep), haber etkinlikleri, envanter, VIP siparişler | Planlı |
| 4 | Otomatik sulama/ışık matrisi, hasat dronu durum makinesi, yeni kat açma | Planlı |
| 5 | Mobil arayüz, Seed-Dex, şifreli `SaveManager`, çevrimdışı kazanç | Planlı |

## 2. `res://` klasör şeması

`✔` = FAZ 1'de var · `○` = planlı (henüz yok). Kod kökü Godot'ta `src/`'dir (`.claude/docs/directory-structure.md`).

```text
res://
├── project.godot                         ✔ 1080×1920, canvas_items + keep_width, Compatibility, 1 Autoload
├── export_presets.cfg                    ✔ Android (arm64-v8a, hata ayıklama imzalı; kimlik bilgisi içermez)
│
├── src/                                  KOD KÖKÜ
│   ├── core/                             Oyunu bilmeyen genel yardımcılar (oyun koduna bağımlı OLAMAZ)
│   │   └── math/color_math.gd            ✔ dairesel ton matematiği (wrap/mesafe/ortalama/lerp)
│   ├── gameplay/                         Oyun kuralları; veri odaklı, durum global tutulmaz
│   │   ├── events/
│   │   │   └── signal_bus.gd             ✔ AUTOLOAD "SignalBus" (yalnızca sinyal bildirir)
│   │   ├── genetics/                     ✔ FAZ 1 çekirdeği (sahne ağacından bağımsız)
│   │   │   ├── plant_gene.gd             ✔ class_name PlantGene : Resource  (genotip)
│   │   │   ├── genetics_engine.gd        ✔ class_name GeneticsEngine         (çaprazla / ifade et / denetle)
│   │   │   ├── genetics_ruleset.gd       ✔ class_name GeneticsRuleset : Resource (tüm sayılar burada)
│   │   │   ├── plant_part_def.gd         ✔ class_name PlantPartDef : Resource (gövde/yaprak/meyve tanımı)
│   │   │   ├── mutation_def.gd           ✔ class_name MutationDef : Resource  (mutasyon tanımı)
│   │   │   ├── plant_phenotype.gd        ✔ class_name PlantPhenotype : RefCounted (ifade edilen görünüm)
│   │   │   └── breed_result.gd           ✔ class_name BreedResult : RefCounted (çocuk + yeni mutasyon)
│   │   ├── plants/
│   │   │   ├── plant_instance.gd         ✔ class_name PlantInstance : Node2D (katmanlı çizim)
│   │   │   └── plant_instance.tscn       ✔
│   │   ├── farm/                         ○ FAZ 2: grid (TileMapLayer), saksı, TimeManager, büyüme evresi, kaydırarak hasat
│   │   ├── economy/                      ○ FAZ 3: borsa, haber olayları, envanter, VIP sözleşmeleri
│   │   ├── automation/                   ○ FAZ 4: sulama/ışık matrisi, dron durum makinesi, kat açma
│   │   └── save/                         ○ FAZ 5: SaveManager, Seed-Dex verisi, çevrimdışı kazanç
│   ├── ui/                               ○ FAZ 5: dikey mobil arayüz (şu an yok)
│   └── dev/                              Geliştirici araçları (oyuncuya gösterilmez)
│       ├── genetics_lab.gd               ✔ iki tohumu çaprazla, çocuğa dokun, mutasyon bildirimi
│       └── genetics_lab.tscn             ✔ ŞU AN ana sahne (run/main_scene)
│
├── assets/
│   ├── art/
│   │   ├── icon.svg                      ✔
│   │   └── plants/{stems,leaves,fruits}/ ✔ 15 gri tonlu SVG parça (renk `modulate` ile gelir)
│   ├── data/
│   │   └── genetics/                     ✔ veri odaklı içerik (kod değişmeden çoğaltılır)
│   │       ├── default_ruleset.tres      ✔ GeneticsRuleset: %5, kalıtım, aralıklar + tüm listeler
│   │       ├── parts/*.tres              ✔ 15 PlantPartDef (4 gövde, 5 yaprak, 6 çiçek/meyve)
│   │       ├── mutations/*.tres          ✔ 6 MutationDef
│   │       └── seeds/*.tres              ✔ 4 başlangıç tohumu (PlantGene)
│   │   (○ economy/, equipment/, floors/, orders/ — FAZ 2–4 verisi)
│   ├── shaders/
│   │   └── canvas_plant_tint.gdshader    ✔ parlama + parıltı (bitki başına ShaderMaterial)
│   └── (○ audio/, fonts/, ui/, vfx/)
│
├── tests/                                Test kökü (kod kökünün DIŞINDA; Godot için tests/unit|integration)
│   ├── unit/{core,genetics}/             ✔ saf mantık testleri
│   ├── integration/{genetics,plants}/    ✔ gerçek veri + gerçek sahne
│   ├── support/                          ✔ test_case.gd, test_runner.gd (geçici koşucu), genetics_fixtures.gd
│   └── smoke/critical-paths.md           ✔
│
├── tools/                                ✔ run_tests.sh, setup-godot-android.sh        (.gdignore'lu)
├── docs/architecture/                    ✔ bu belge                                    (.gdignore'lu)
├── design/game-brief.md                  ✔ tasarım kaydı                                (.gdignore'lu)
└── production/qa/evidence/               ✔ retained ekran görüntüleri (faz1-plant-instance/)
```

Godot'un görmediği (`.gdignore`) klasörler: `design/`, `docs/`, `production/`, `tools/`, `studio-tests/`,
`LICENSES/` ve depoda duran önceki Android uygulaması (`app/`, `gradle/`, `releases/`).

**Katman kuralı.** `src/core` → hiçbir şeye bağımlı değil. `src/gameplay` → `src/core`'a bağımlı olabilir,
arayüze (`src/ui`) ASLA doğrudan bağlanmaz; haberleşme `SignalBus` ile. `src/dev` her şeyi kullanabilir ama
hiçbir şey `src/dev`'e bağımlı olamaz.

## 3. Autoload listesi

`project.godot` → `[autoload]`:

| Ad | Yol | Durum tutar mı? | Faz |
|---|---|---|---|
| `SignalBus` | `res://src/gameplay/events/signal_bus.gd` (`*` = tekil olarak etkin) | **Hayır**, yalnızca sinyal | 1 ✔ |

**Neden tek Autoload?** Şablon kuralı: oyun durumu için global singleton yok, bağımlılık enjeksiyonu var
(`.claude/rules/gameplay-code.md`). `SignalBus` durumsuzdur; sinyal bildirimi dışında hiçbir veri tutmaz, bu yüzden
kurala uyar. Durum tutan hizmetler (**planlı, öneri**) Autoload yerine ana sahnede (composition root) kurulup
kullanan düğümlere `@export` ile verilir:

| Hizmet (öneri) | Faz | Sorumluluğu |
|---|---|---|
| `TimeManager` | 2 | oyun saati, hız çarpanı, büyüme evresi tikleri |
| `FarmFloor` / grid servisi | 2 | saksı yerleşimi, hücre durumu |
| `Inventory`, `Market`, `OrderBoard` | 3 | stok, fiyat dalgalanması, VIP sözleşmeleri |
| `AutomationController`, `DroneAgent` | 4 | sulama/ışık matrisi, dron durum makinesi |
| `SaveManager`, `SeedDex` | 5 | şifreli kayıt, keşfedilen tohumlar, çevrimdışı kazanç |

> Karar bekliyor: `TimeManager` / `SaveManager`'ı klasik Autoload yapmak istersen tek satırlık bir değişikliktir;
> bunun bedeli şablonun "global durum yok" kuralından ve testlerde enjeksiyon kolaylığından vazgeçmektir.

## 4. SignalBus sözleşmesi

Sistemler birbirini bilmez; olayı buraya yayınlar, ilgilenen buradan dinler. Motor (`GeneticsEngine`) **sinyal
yayınlamaz**: çağıran sahne/servis yayınlar (motor saf kalır, test edilebilir).

| Sinyal | Ne zaman | Yayınlayan (şimdi) | Dinleyen (şimdi) |
|---|---|---|---|
| `seed_crossbred(parent_a, parent_b, child)` | her çaprazlamada | `genetics_lab.gd` | — (Seed-Dex, FAZ 5) |
| `mutation_discovered(child, mutation_id)` | çaprazlamada YENİ mutasyon çıkınca | `genetics_lab.gd` | `genetics_lab.gd` (başlık bandı) |

Planlı sinyaller (henüz tanımlı değil; ihtiyaç doğdukça eklenir): `plant_harvested`, `market_price_changed`,
`order_completed`, `floor_unlocked`, `game_saved`. Sinyal eklemek `signal_bus.gd`'ye bir satırdır.

## 5. Veri modeli (özel `Resource` sınıfları)

| Sınıf | Tür | Rol | Kaydedilir mi? |
|---|---|---|---|
| `PlantGene` | Resource | Genotip: her lokusta tam iki alel; soy bilgisi (`uid`, `generation`, `parent_uids`) | evet (`.tres`/JSON) |
| `GeneticsRuleset` | Resource | Tüm genetik sayıları + parça/mutasyon listeleri | hayır (içerik) |
| `PlantPartDef` | Resource | Parça: kimlik, katman, doku, çapa, baskınlık, taban değer, gövde bağlantıları | hayır (içerik) |
| `MutationDef` | Resource | Mutasyon: ağırlık, çarpanlar, parlama, parıltı, meyve boyaması, `excludes` | hayır (içerik) |
| `PlantPhenotype` | RefCounted | İfade edilen görünüm/özellik; her seferinde hesaplanır | hayır |
| `BreedResult` | RefCounted | Çocuk + yeni/miras mutasyon (arayüz bildirimi için) | hayır |

`PlantGene` alanları:

| Alan | Tür | Anlamı |
|---|---|---|
| `stem_alleles`, `leaf_alleles`, `fruit_alleles` | `Array[StringName]` (2) | parça kimlikleri (ayrık lokus) |
| `growth_alleles`, `water_alleles`, `value_alleles` | `PackedFloat32Array` (2) | sayısal çarpan alelleri (1.0 = nötr) |
| `hue_alleles` | `PackedFloat32Array` (2) | ton, [0,1) dairesel |
| `mutations` | `Array[StringName]` | nadir özellik kimlikleri (alel çifti değil, liste) |
| `uid`, `display_name`, `generation`, `parent_uids` | — | kimlik ve soy ağacı |

Yeni parça / mutasyon / tohum eklemek **kod değil veri** değişikliğidir: ilgili klasöre bir `.tres` bırakıp
`default_ruleset.tres`'in listesine eklenir. `GeneticsRuleset.validate()` ve
`tests/integration/genetics/genetics_default_data_test.gd` tutarlılığı (kimlik, katman, doku, aralık) denetler.

## 6. Genetik kuralları

Tüm sayılar `default_ruleset.tres`'tedir; kodda genetik sabiti yoktur.

### 6.1 Çaprazlama (`GeneticsEngine.crossbreed`)

1. **Ayrışma:** her lokusta çocuk, her ebeveynin iki aleinden birini eşit olasılıkla (½) alır.
2. **Bağımsız dağılım:** lokuslar birbirinden bağımsızdır (7 lokus).
3. **Sayısal alel sapması:** seçilen alel `a` için `a' = clamp(a + N(0, σ), alt, üst)`, `σ = quant_drift × (üst − alt)`.
   Varsayılan `quant_drift = 0.04` → büyüme σ = 0.08, su σ = 0.064, değer σ = 0.14.
4. **Ton sapması:** `h' = wrap(h + N(0, hue_drift))`, varsayılan `hue_drift = 0.01` (≈ 3,6°).
5. **Mutasyon mirası:** ebeveynde olan her mutasyon için `p = 1 − (1 − q)^k` (`q = mutation_inherit_chance = 0.5`,
   `k` = o mutasyonu taşıyan ebeveyn sayısı: 1 → %50, 2 → %75). Çocuk `max_mutations` (3) sınırında durur.
6. **Yeni mutasyon:** `u ~ U[0,1)`; `u < clamp(mutation_chance + bonus, 0, 1)` ise (varsayılan **%5**), çocukta olmayan ve
   çocuktakilerle `excludes` bakımından uyumlu mutasyonlar arasından `weight` ile ağırlıklı seçim.
   Zar HER ZAMAN atılır (rastgele akış sınırın dolu olmasına göre kaymaz). `bonus` UV lambası gibi dış etkenler içindir (FAZ 4).
7. **Kimlik:** `uid` 12 onaltılık hane; `generation = max(ebeveyn nesilleri) + 1`; `parent_uids = [a.uid, b.uid]`.

Motor saftır: rastgelelik (`RandomNumberGenerator`) ve kurallar (`GeneticsRuleset`) dışarıdan verilir; aynı tohum aynı çocuğu üretir.

### 6.2 İfade (`GeneticsEngine.express` → `PlantPhenotype`)

| Özellik | Kural |
|---|---|
| Parça (gövde/yaprak/meyve) | iki alelden **baskınlığı büyük** olan görünür; eşitse kimliği alfabetik küçük olan. Çekinik yalnızca homozigotta çıkar. |
| Büyüme, su, değer | `lerp(küçük alel, büyük alel, quant_dominance)` (0.5 = ortalama); sonra mutasyon çarpanları çarpılır. |
| Ton | iki ton aleinin **dairesel ortalaması** (`ColorMath.mix_hues`). |
| Pazar değeri | `meyve.base_value × değer × Π mutasyon.value_multiplier` |
| Meyve tonu | `wrap(ton + Σ mutasyon.fruit_hue_shift)` |
| Parlama | mutasyonların **en güçlüsünün** gücü ve rengi; parıltı = en büyük `shimmer` |
| Meyve boyaması | alfası > 0 olan ilk (kimliğe göre sıralı) mutasyonun `tint_override`'ı (örn. Altın) |

**Seed-Dex anahtarları:** `morph_id = "gövde|yaprak|meyve"` (tür); `signature = morph_id|hNN|mut1,mut2`
(`hNN` = ton dilimi, `hue_buckets = 24` → 15°'lik dilimler). "Yeni kombinasyon" = daha önce görülmemiş `signature`.

### 6.3 Ayar düğmeleri (`GeneticsRuleset`)

| Alan | Varsayılan | Etkisi |
|---|---|---|
| `mutation_chance` | 0.05 | çaprazlama başına yeni mutasyon olasılığı |
| `mutation_inherit_chance` | 0.5 | ebeveyn başına mutasyon geçiş olasılığı |
| `max_mutations` | 3 | bir bitkideki en çok mutasyon |
| `quant_dominance` | 0.5 | sayısal özelliklerde ifade (0.5 = ortalama) |
| `quant_drift` / `hue_drift` | 0.04 / 0.01 | gamet sapması; seçilimle ilerlemenin kaynağı |
| `growth_range` / `water_range` / `value_range` | 0.5–2.5 / 0.4–2.0 / 0.5–4.0 | sayısal alel aralıkları |
| `hue_buckets` | 24 | Seed-Dex ton dilimi sayısı |

### 6.4 İçerik (FAZ 1 başlangıç verisi)

| Katman | Parçalar (baskınlık sırası: büyük → küçük) |
|---|---|
| Gövde (4) | Sarmaşık (3) › Kamış (2) › Bambu (1) › Siber Boru (0) |
| Yaprak (5) | Eğrelti (3) › Oval (2) = Dikenli (2) › Geniş (1) › Devre (0) |
| Çiçek/meyve (6) | Meyve Salkımı (3) › Yıldız Çiçek (2) = Yumru (2) › Lale (1) = Bakla (1) › Siber Küre (0) |

Çekinik uçlar (Siber Boru, Devre, Siber Küre) en nadir/en değerli olacak şekilde seçildi: Siber Küre taban değeri 30
(diğerleri 8–14). **Mendel örneği:** "Siber Taşıyıcı" tohumu (gövde `vine/cyber`, yaprak `fern/circuit`, meyve `star/orb`,
ton aleli 0.52/0.93) iki taşıyıcının çaprazında üç lokus için de ¼ olasılıkla çekinik homozigot (tam siber bitki) çıkar
ve ton 1:2:1 ayrışır; testler bunu tohumlu RNG ile istatistiksel olarak doğrular.

| Mutasyon | Ağırlık | Etki |
|---|---|---|
| Kuraklığa Dayanıklı | 30 | su ×0.5 |
| Hiper Büyüme | 30 | büyüme ×1.6 |
| Biyolüminesan | 30 | değer ×1.5, parlama 1.0 (halo) |
| Kimera | 15 | değer ×1.4, meyve tonu +0.5 (tamamlayıcı); **Altın ile bir arada olamaz** |
| Kristalize | 12 | değer ×2, parıltı 1.0 |
| Altın | 8 | değer ×3, meyve altın renge zorlanır, parıltı 0.6 |

## 7. Görsel katman

### 7.1 `PlantInstance` düğüm ağacı (`plant_instance.tscn`)

```text
PlantInstance (Node2D, plant_instance.gd)      ← konum = bitkinin TABANI (gövde çapası)
├── Halo   (Sprite2D, %Halo)                   ← ortak radyal doku + ADD karışımı; yalnızca parlayan mutasyonda görünür
└── Rig    (Node2D, %Rig)                      ← rüzgâr salınımı ve "pop" animasyonu bunu döndürür/ölçekler
    ├── Stem   (Sprite2D, %Stem)               ← gövde dokusu, ofset = −çapa, boy büyümeyle ölçeklenir
    ├── Leaves (Node2D, %Leaves)               ← yaprak havuzu
    │   └── Sprite2D × N                       ← kodla eklenir; N = gövdenin yaprak bağlantı sayısı (şimdi 3)
    └── Fruit  (Sprite2D, %Fruit)              ← çiçek/meyve; gövdenin meyve bağlantısında
```

Katmanlar **gen kimliklerinden** kurulur: `gene` → `GeneticsEngine.express()` → parça kimlikleri →
`ruleset.get_part(id).texture`. `gene`, `ruleset` ya da `growth` atandığında görünüm kendiliğinden güncellenir;
`visuals_rebuilt` sinyali yeniden kurulumu duyurur. Genel API: `gene`, `ruleset`, `growth`, `rebuild()`,
`play_pop()`, `get_phenotype()`.

### 7.2 Renk ve parlama hattı

| Katman | Boya (`modulate`) |
|---|---|
| Meyve/çiçek | `from_hsv(fruit_hue, 0.80, 1.0)`; mutasyon boyaması varsa (Altın) o renk |
| Yaprak | `from_hsv(lerp_hue(yeşil 0.36, ton, 0.30), 0.65, 0.95)`: yeşilden genetik tona %30 çekilir |
| Gövde | yaprak tonunda, `from_hsv(…, 0.35, 0.70)` |
| Parlama/parıltı | tüm katmanlar bitkiye özel **tek** `ShaderMaterial` paylaşır (`canvas_plant_tint.gdshader`): `glow_color`, `glow_strength`, `shimmer`, `phase` |
| Halo | tüm bitkilerce paylaşılan radyal doku + `CanvasItemMaterial` (ADD); renk/şeffaflık bitkiye göre `modulate` ile |

Bitki başına bir malzeme: parlayan bir bitki komşusunu parlatmasın (testte doğrulanır). Gölgelendirici: parça başına
1 doku okuması, dallanma yok; renk `mediump`, `TIME` ile ilgili hesap `highp`.

### 7.3 Büyüme eğrisi (`growth` ∈ [0,1], tamamı `PlantInstance` dışa aktarımı)

| Evre | Değer | Görünüm |
|---|---|---|
| Tohum | 0 | gövde en kısa ve ince (`stem_min_scale` 0.18, `stem_min_width_scale` 0.55), yaprak ve meyve yok |
| Filiz | ~0.25–0.6 | gövde uzar (`stem_full_at` 0.6'da tam boy); yapraklar sırayla belirir (`leaf_start_at` 0.25 → `leaf_full_at` 0.8, `leaf_pop_span` 0.15) |
| Olgun | ≥ 0.85 | çiçek/meyve belirir (`fruit_start_at` 0.85); parlayan mutasyonun halosu `halo_start_at` 0.3'ten itibaren büyür |

FAZ 2'de `TimeManager` bu değeri sürer; `PlantInstance` değeri yalnızca alır (durumsuz görünüm).

### 7.4 Geliştirici laboratuvarı (`genetics_lab.tscn`)

```text
GeneticsLab (Control, genetics_lab.gd)         ← ŞU AN ana sahne; --cross --seed --bonus --growth --adopt seçenekleri
├── (arka plan: TextureRect, degrade)
├── (başlık, alt başlık, mutasyon bandı: Label — banner SignalBus.mutation_discovered ile açılır)
├── EBEVEYN A/B: PlantInstance + Label + "TOHUMU DEĞİŞTİR" Button            (×2)
├── "ÇAPRAZLA ×8" Button · "UV BONUS" Button · büyüme HSlider · durum Label
└── Çocuklar (×8): PlantInstance + Label + saydam Button (dokun → ebeveyn yap)
```

Arayüz kodla kurulur (geliştirici aracı; oyuncuya dönük arayüz FAZ 5'te `src/ui/`'da, yerelleştirilmiş metinle).

## 8. Test ve doğrulama

- Koşucu: `bash tools/run_tests.sh [--filter=...]` (gdUnit4 stili çıkış kodları: 0 geçti, 100 başarısız, 105 yükleme hatası,
  2 test yok). gdUnit4 kurulumu kullanıcı onayı bekliyor (bkz. 10); test dosyaları gdUnit4'e geçişte aynı adlandırmayı korur.
- Birim: `tests/unit/` (genetik kalıtım, ifade, mutasyon, veri, ton matematiği). Entegrasyon: `tests/integration/`
  (varsayılan veri, `PlantInstance` gerçek sahnede).
- İstatistiksel testler tohumlu RNG ile deterministiktir. Testlerin gerçekten bir şey yakaladığı **mutasyon testiyle**
  (kodu bilerek bozup testin kırıldığını görerek) doğrulandı.
- Görsel kanıt: `production/qa/evidence/faz1-plant-instance/` (1080×1920, `--write-movie` ile gerçek çizim).
  Yeniden üretmek için: `bash tools/capture_screenshot.sh <sahne.tscn> <çıkış.png> -- <sahne seçenekleri>`.
- Ayrıştırma denetimi: şablonun `godot-parse-check.gd` betiği. Android: `godot --headless --export-debug "Android"`.

## 9. Kararlar ve sapmalar

| # | Karar | Gerekçe / sapma |
|---|---|---|
| 1 | Tek Autoload `SignalBus` (durumsuz) | şablonun "global oyun durumu yok" kuralı; servisler enjekte edilir |
| 2 | `GeneticsEngine` saf + enjekte RNG/kural seti, sinyali çağıran yayınlar | deterministik testler, sahne bağımsızlığı |
| 3 | Diploid alel modeli (parça: baskınlık; sayısal: karışık; ton: dairesel ortalama) | gerçek Mendel davranışı, taşıyıcı/çekinik sürprizleri, seçilimle ilerleme |
| 4 | Gri SVG parça + `modulate` + bitki başına `ShaderMaterial`, ortak halo | 120 parça kombinasyonu için tek sanat seti; bitki başına tek malzeme |
| 5 | **GL Compatibility** oluşturucu | Android'de en geniş cihaz kapsamı; şablonun 2D varsayılanı (Forward+) yerine bilinçli seçim |
| 6 | Tipli `Dictionary` kullanılmadı (`GeneticsRuleset` dizinleri) | Godot 4.3 uyumu: tipli sözlük 4.4'te geldi. Tipli `Array`/`Resource` dizileri kullanıldı |
| 7 | `duplicate_deep` yerine elle `PlantGene.copy()` | `duplicate_deep` 4.5+; 4.3 uyumlu derin kopya |
| 8 | Geçici kendi test koşucusu | gdUnit4 üçüncü taraf kod; çalıştırma izni verilmedi, kullanıcı kararı bekliyor |
| 9 | `window_*_override` 540×960 | masaüstünde geliştirme penceresi küçük kalsın; Android'de etkisiz, temel çözünürlük 1080×1920 |
| 10 | `export_presets.cfg`, `.godot/global_script_class_cache.cfg`, `.uid`, `.import` izlenir | şablonun `.gitignore` tasarımı; anahtar/şifre içermez (hata ayıklama imzası) |
| 11 | Hedef Godot sürümü 4.7.2; kod 4.3+ API'leriyle uyumlu yazıldı | kullanıcı "4.3+" istedi; şablon 4.7.2'yi sabitliyor. **Doğrulandı:** resmi Godot 4.3.stable (SHA512 doğrulamalı) ile tüm testler geçti ve laboratuvar sahnesi 4.7.2 ile aynı görünümle çizildi (2026-10-30). 4.4–4.7'ye özgü API kullanılmadı (tipli `Dictionary`, `duplicate_deep` vb.) |
| 12 | `project.godot` → `debug/gdscript/warnings/untyped_declaration=2` (HATA) | "her yerde statik tip" kuralı disiplinle değil derleyiciyle zorlanır: tipsiz bildirim betiği derlenemez yapar. `tests/unit/core/source_static_typing_test.gd` hem ayarı hem `src/` altındaki her betiğin derlendiğini denetler. `addons/` varsayılan olarak muaftır (üçüncü taraf kod) |

## 10. Açık sorular

1. **gdUnit4:** üçüncü taraf eklentinin kurulup çalıştırılmasına izin veriyor musun? Şimdilik kendi koşucum (aynı çıkış kodları) kullanılıyor.
2. **`TimeManager` / `SaveManager` Autoload mu, enjekte hizmet mi?** (bkz. bölüm 3).
3. **Performans bütçeleri** (`project.yaml`) bilinçli olarak boş: hedef cihaz sınıfı belirlenince doldurulacak.
4. **Sanat yönü:** SVG parçalar yer tutucu kalitede ama oyun içi kullanıma uygun; elle çizilmiş sanat gelirse `PlantPartDef.texture` değişir, kod değişmez.
5. **Yerelleştirme:** laboratuvar metinleri Türkçe sabit (geliştirici aracı). Oyuncuya dönük metin FAZ 5'te `tr()` ile.
6. **Ses/parçacık:** ASMR hasat efektleri FAZ 2'de (swipe-to-harvest ile birlikte).
