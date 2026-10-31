# FloraLab: Cyber Harvest — Mimari

> **Durum:** FAZ 1–5 uygulandı (genetik, çiftlik, ekonomi, otomasyon, mobil arayüz, Seed-Dex, şifreli kayıt, çevrimdışı kazanç) ve üstüne **cila turu**:
> tasarım dili (`design/design-language.md`), yeni yazı tipleri + ikon seti, Türkçe/İngilizce, hareket dili, hedef sistemi, FLORA kurgusu.
> Android release APK dışa aktarıldı ve paket/imza/açılış denetimi yapıldı (gerçek cihazda denenmedi: bkz. bölüm 15).
> **Motor:** Godot 4.7.2 · GDScript (statik tipli) · GL Compatibility oluşturucu · Android dikey 1080×1920.
> **Tasarım kaydı:** `design/game-brief.md` (şablonun `minimal` kipi: ayrı GDD yok, kısa özet ve bu belge).
> **Sapmalar ve açık sorular:** bu belgenin 14. ve 15. bölümleri.

## 1. Fazlar ve durum

| Faz | Kapsam | Durum |
|---|---|---|
| 1 | `PlantGene` Resource, Mendel çaprazlama, %5 mutasyon, katmanlı `PlantInstance`, `SignalBus` | **Var, testli, ekran görüntülü** |
| 2 | Hidroponik ızgara (başta `TileMapLayer`, şimdi 2.5D sahne: bölüm 7.5), saksılar, `TimeManager`, büyüme evreleri, su/ışık çarpanları, kaydırarak hasat, ses/parçacık | **Var, testli, ekran görüntülü** (bölüm 8) |
| 3 | Dinamik borsa (arz-talep), haber olayları, envanter, VIP siparişler, çaprazlama maliyeti | **Var, testli** (bölüm 9) |
| 4 | Sulama/UV matrisi, hasat dronu durum makinesi, yeni kat açma | **Var, testli, ekran görüntülü** (bölüm 10) |
| 5 | Mobil arayüz, Seed-Dex, şifreli `SaveManager`, çevrimdışı kazanç, ayarlar, yerelleştirme | **Var, testli, ekran görüntülü** (bölüm 11) |

## 2. `res://` klasör şeması

Kod kökü Godot'ta `src/`'dir (`.claude/docs/directory-structure.md`). Aşağıdaki her dosya vardır.

```text
res://
├── project.godot                         1080×1920, canvas_items + keep_width, dikey, Compatibility, 1 Autoload, ana sahne src/ui/main.tscn
├── export_presets.cfg                    Android (arm64-v8a): "Android" hata ayıklama imzalı, "Android Release" (imza bilgisi ortam değişkeninden)
│
├── src/                                  KOD KÖKÜ
│   ├── core/math/                        Oyunu bilmeyen yardımcılar: color_math.gd (dairesel ton), segment_math.gd (kaydırma çizgisi/daire kesişimi)
│   ├── gameplay/                         Oyun kuralları; veri odaklı, global durum yok
│   │   ├── events/signal_bus.gd          AUTOLOAD "SignalBus" (durumsuz; tüm olay sinyalleri)
│   │   ├── genetics/                     FAZ 1: plant_gene, genetics_engine, genetics_ruleset, plant_part_def, mutation_def,
│   │   │                                 plant_phenotype, breed_result, gene_codec (PlantGene <-> Dictionary, kayıt için)
│   │   ├── plants/                       plant_instance.gd/.tscn (katmanlı çizim)
│   │   ├── farm/                         FAZ 2: farm_config, growth_model (saf formüller), pot_state, floor_def, floor_state, farm_service,
│   │   │                                 time_manager, harvest_result, farm_signal_relay (servis sinyali -> SignalBus)
│   │   ├── economy/                      FAZ 3: economy_config, market_service, market_event_def, order_service, order, order_template_def,
│   │   │                                 inventory_service, seed_item, produce_stack, wallet_service, breeding_service
│   │   ├── automation/                   FAZ 4: automation_service (sulama/UV/dron/kat/lab UV satın alma), equipment_def, automation_config,
│   │   │                                 drone_agent (durum makinesi), drone_service
│   │   ├── dex/seed_dex.gd               FAZ 5: keşfedilen türler/çeşitler
│   │   ├── goals/                        goal_def (veri), goal_service (sıralı hedef zinciri, ilerleme, ödül, kayıt)
│   │   ├── save/                         FAZ 5: save_manager (şifreli, atomik), offline_progress, offline_report, game_settings
│   │   └── game/                         FAZ 5: game_session (kompozisyon kökü + komutlar), game_catalog (tüm veri), command_result
│   ├── ui/                               oyuncuya dönük arayüz (yalnızca gösterir; oyunu GameSession komutlarıyla değiştirir)
│   │   ├── main.gd / main.tscn           ana sahne: manzara, HUD, 5 sekme, alt gezinme, ayarlar/hedefler/açılış kartı, çevrimdışı özeti, bildirim
│   │   ├── common/                       TASARIM DİLİ: ui_tokens, ui_theme, ui_fonts, ui_icons, ui_motion, ui_format, localization, ui_kit;
│   │   │                                 bileşenler: fx_button, price_button, credit_tag, nav_bar, toggle_switch, segmented_control, progress_ring,
│   │   │                                 level_pips, price_chart, flora_bubble, seed_card, sheet_overlay, toast_layer, plant_preview, gene_summary,
│   │   │                                 goal_text, night_backdrop + skyline_layer (gün-gece manzarası), game_panel
│   │   ├── hud/hud_bar.gd                kredi (sayarak), gün çizgisi, hız, menü, itibar, hedef çipi, haber şeridi
│   │   ├── panels/                       farm, lab, market, dex, upgrades, goals_overlay, settings_overlay, intro_overlay, offline_popup
│   │   ├── farm/                         farm_view (görünüm penceresi, dokunuş, kat geçişi), farm_stage + farm_stage_parts (2.5D sahne), plant_atlas, pot_overlay (ekran uzayı göstergeler)
│   │   ├── fx/harvest_fx.gd              parçacık, yazı, halka dalgası, su sıçraması, HUD'a uçan sikkeler
│   │   └── audio/                        audio_service, haptics_service (titreşim), sfx_bank (kodla üretilen sesler)
│   └── dev/                              Geliştirici sahneleri (dışa aktarmada yok): genetics_lab, farm_dev, ui_showcase
│
├── assets/
│   ├── art/                              icon.svg (+ splash.png) · icons/ 42 SVG ikon · plants/{stems,leaves,fruits}/ 15 gri SVG parça
│   ├── fonts/                            Bricolage Grotesque + Nunito Sans (değişken, SIL OFL) ve lisansları
│   ├── data/                             veri odaklı içerik (kod değişmeden çoğaltılır)
│   │   ├── genetics/                     default_ruleset.tres · parts/ (15) · mutations/ (6) · seeds/ (4 başlangıç tohumu)
│   │   ├── farm/default_farm_config.tres · economy/default_economy_config.tres + events/ (9) + orders/ (9)
│   │   ├── automation/default_automation_config.tres · equipment/ (4) · floors/ (4 kat) · goals/ (15 hedef)
│   │   └── game_catalog.tres             GameCatalog: yukarıdakilerin tümünü toplar (betikle üretilir)
│   ├── i18n/{strings,content}.csv        keys,tr,en: arayüz metinleri ve oyun içeriği adları; derlenen *.translation git'te YOK (içe aktarmada üretilir)
│   └── shaders/                          canvas_plant_tint (bitki parlaması), skyline_windows (titreşen pencereler)
│
├── tests/                                kod kökünün DIŞINDA: unit/{core,genetics,farm,economy,automation,dex,save,ui}, integration/{genetics,plants,farm,economy,
│                                         automation,game,ui}, support/ (test_case, test_runner, *_fixtures), smoke/critical-paths.md
├── tools/                                run_tests.sh, capture_screenshot.sh, capture_ui_evidence.sh, setup-godot-android.sh, art/ (make_icons)
├── docs/architecture/                    bu belge
├── design/                               game-brief.md (tasarım kaydı) · design-language.md (tasarım dili)
└── production/qa/evidence/               retained ekran görüntüleri: faz1-plant-instance/, faz2-farm/, ui-polish/ (README + stamp.txt)
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
kurala uyar. Durum tutan hizmetler Autoload DEĞİLDİR: düz `RefCounted` sınıflardır ve `GameSession` (ana sahnenin altındaki
`Node`, kompozisyon kökü) onları kurup birbirine bağlar. Testler aynı hizmetleri küçük verilerle doğrudan kurar.

| Hizmet | Faz | Sorumluluğu |
|---|---|---|
| `TimeManager` | 2 | oyun saati, gün, hız çarpanı (0..5) |
| `FarmService` | 2 | katlar, saksılar, ekim/sulama/hasat, büyüme tikleri |
| `WalletService`, `InventoryService`, `MarketService`, `OrderService`, `BreedingService` | 3 | kredi/itibar, tohum+ürün stoku, borsa, VIP siparişler, çaprazlama |
| `AutomationService`, `DroneService` (+ `DroneAgent`) | 4 | sulama/UV/dron/kat satın alma, dron durum makineleri |
| `SeedDex`, `GameSettings`, `SaveManager`, `OfflineProgress` | 5 | keşif koleksiyonu, ayarlar, şifreli kayıt, çevrimdışı benzetim |
| `GameSession` | 5 | hepsini kurar; oyuncu KOMUTLARI (`CommandResult` döndürür); otomatik kayıt; duraklatınca/dönünce çevrimdışı |

## 4. SignalBus sözleşmesi

Sistemler birbirini bilmez; olayı buraya yayınlar, ilgilenen buradan dinler. Motor ve hizmetler kendi sinyallerini yayar;
köprü sınıfları (`FarmSignalRelay`, `GameSession`) bunları `SignalBus`'a aktarır; böylece hizmetler `SignalBus`'ı bilmeden
test edilir. Arayüz YALNIZCA `SignalBus`'ı dinler.

| Alan | Sinyaller |
|---|---|
| Genetik | `seed_crossbred`, `mutation_discovered` |
| Çiftlik | `plant_planted`, `plant_matured`, `pot_watered`, `plant_harvested`, `harvest_swipe_finished` |
| Ekonomi | `credits_changed`, `reputation_changed`, `inventory_changed`, `item_sold`, `prices_changed`, `market_event_started/ended`, `order_added/completed/expired` |
| Otomasyon | `equipment_purchased`, `floor_unlocked` |
| Oyun | `dex_discovery`, `game_saved`, `game_reloaded`, `offline_report_ready`, `day_changed`, `speed_changed`, `toast_requested`, `ui_tapped` |

Sinyalin tam imzası `src/gameplay/events/signal_bus.gd` içindedir (her sinyalin doc yorumu vardır).

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

### 7.5 2.5D çiftlik sahnesi (`FarmStage`)

**Karar: tam 3D değil, 2.5D.** Oyun düzlemde oynanır (dokun/kaydır, 3×2 ile 4×4 ızgara); mantık motordan bağımsızdır (`RefCounted` hizmetler),
görünüm katmanı değiştirilebilirdir. Bitki sanatı elle çizilmiş katmanlı vektör parçalarıdır ve genetik renk + parlama gölgelendiricisiyle birleşir
(15 SVG parça × renk × mutasyon). Tam 3D, bu hattı baştan yazmayı (15 parça için ağ üreticisi, yaprak/çiçek/gövde malzemeleri, kemik/rüzgâr), telefonda
serbest kamerayı (kaydırmada örtüşme, kamera yönetimi) ve düzlemde kusursuz olan dokunuş eşlemesini kaybetmeyi gerektirirdi; kazandırdığı derinlik algısını
2.5D zaten verir. Derinlik: gerçek geometri (kutu, raf, saksı), perspektif kamera (FOV 26°, 5° eğim, hafif süzülme), ışık (ortam + güneş + UV lambası ışığı).

```text
FarmView (Control)                          ← API değişmedi: pot_tapped, harvest_requested, swipe_*, show_floor, set_night, pot_local_position
├── SubViewportContainer → SubViewport (own_world_3d, transparent_bg, MSAA 2x)
│   └── FarmStage (Node3D)
│       ├── Camera3D · DirectionalLight3D · Environment (ortam ışığı; gece/gündüz buradan)
│       ├── PlantAtlas (SubViewport, saydam 2D)     tüm PlantInstance'lar tek dokuda, hücre başına bir bitki
│       └── Floor (Node3D, kat değişince baştan kurulur)
│           ├── kabuk: arka duvar (shader), tavan, 4 direk, ön cam (shader), dikey su yükselticisi
│           ├── bölme başına: raf levhası, sulama borusu (akan su shader'ı), UV çubuğu + OmniLight3D + saksı başına huzme
│           ├── saksı başına: torna profilli gövde + ağız halkası, su penceresi, temas gölgesi, halo bilboard, bitki dörtgeni
│           └── dronlar (gövde + dönen kanatlar + hasat parlaması), üs pedi
├── PotOverlay (Control, ekran uzayı)       büyüme/su çubukları, susuzluk damlası, hasada hazır halkası
└── fx katmanı (Control) + kaydırma izi (Line2D)   HarvestFx
```

- **Koordinatlar:** oyun düzlemi z = 0, birim = bir karo, x sağa, y yukarı. Bölme r: raf üstü `y = -(2r+2)`, saksı kökü `y = -(2r+1) - 0.644`.
- **Dönüşüm analitiktir** (`FarmStage.project`, `plane_point`): kameranın konumu ve FOV'undan hesaplanır; çizilmiş pencereye bağlı değildir, başsız testte aynıdır.
  Dokunuş: ekran → ışın → z = 0 düzlemi → eski `SegmentMath` dikdörtgen kesişimi (karo biriminde). Kamera süzülürken bile eşleme o anki kameradan hesaplanır.
- **Bitkiler (`PlantAtlas`):** `PlantInstance` sanatı ve gölgelendiricisi DEĞİŞMEDİ; hepsi tek saydam SubViewport'ta (4 sütun, hücre 288×448) çizilir, sahne her bitki için
  düz dörtgenle o hücreyi basar (kare başına tek 2D geçiş; bitki başına pencere yok). Halo toplamalı karışım kullandığından atlasta çizilemez (saydam hedefe yazılmaz):
  sahnede ayrı ışık bilboard'u (`spatial_plant_halo`) olarak bitkinin arkasına konur.
- **Renk uzayı (Compatibility'de bulundu):** gölgelendirilmemiş (unshaded) `ALBEDO` doğrudan gösterim değeri olarak yazılır (0.5 → 128); atlas dokusu `source_color` ile okunmaz, çeviri yapılmaz.
- **Sıralama:** toplamalı UV huzmesi bitkinin ÖNÜNDE çizilirse bitkiyi soldurur (mor ekleme); huzme nesne merkezi bitkinin arkasında tutularak önce çizilir (`BEAM_Z`).
- **Maliyet (SAYILAR ölçüldü, ZAMAN ölçülmedi):** gölge haritası yok (temas gölgesi bilboard), 4 OmniLight3D'ye kadar (bölme başına bir), kare başına bir 2D atlas geçişi.
  `ui_showcase --render-stats` (yazılım OpenGL'li Xvfb, 90. kare, arayüz dahil): 3×2 çiftlik **231 çizim çağrısı, 595 nesne, 18.7 bin üçgen, 53 MB doku belleği**;
  4×4 kule **288 / 660 / 25 bin / 62 MB**; karşılaştırma olarak 3D'siz pazar sekmesi 248 / 1045 / 17 bin / 30 MB. Yani çizim çağrısı sayısı 2D bir ekranla aynı sınıfta;
  asıl ek maliyet bellek (≈ +23-32 MB: atlas + MSAA'lı 3D hedef) ve 3D geçişin dolum hızı. Gerçek cihazda kare süresi ölçülmedi (bölüm 15). Sekme gizliyken hem 3D pencere hem atlas çizilmez.

## 8. Çiftlik kuralları (FAZ 2)

Tüm sayılar `assets/data/farm/default_farm_config.tres` (`FarmConfig`) içindedir; formüller `GrowthModel`'de saf ve durumsuzdur.

- **Büyüme** `growth` ∈ [0,1]; evre: Tohum (< `sprout_threshold` 0.25), Filiz, Olgun (≥ 1).
  `hız/sn = (1 / base_grow_seconds) × gen.büyüme_hızı × su_çarpanı × (1 + uv_seviyesi × uv_growth_bonus_per_level)`
  (taban 45 sn, UV başına +%50).
- **Su çarpanı** `smoothstep(water_growth_threshold 0.15, +water_growth_ramp 0.10, su)`: susuz bitki durur.
  Büyürken su azalır: `water_drain_per_second 0.012 × gen.su_tüketimi`; sulama borusu `irrigation_refill_per_second 0.25` ile doldurur.
- **Aşırı olgunlaşma** (Overgrowth): olgunlaştıktan `overgrowth_grace_seconds` (60) sonra dakikada %10 değer kaybı, en çok %50 (`overgrowth_min_factor`).
- **Hasat** verimi `base_yield_units` (2) × `gen.verim`; her hasat `seeds_returned_per_harvest` (1) tohum döndürür; dron hasadı aynı saksıya yeniden diker (`replant`).
- **Kaydırarak hasat** `FarmView`: parmağın çizgisi saksı dairesiyle `SegmentMath` kesişiminde olgun saksıyı BİR kez ister
  (kaydırma başına kümesi); kombo adımı başına +%5, en çok +%50 (`combo_bonus_*`).
- **Zaman** `TimeManager`: gün = 300 sn oyun saati; hız 1/2/5.
- **Çizim** `FarmView` → `FarmStage` (2.5D sahne, bölüm 7.5): cam kutu, raflar, saksılar, sulama borusu, UV lambası ve huzmeleri, dronlar; bitkiler
  `PlantAtlas`'tan basılan düz dörtgenler; su/büyüme çubukları (`PotOverlay`, ekran uzayı), `HarvestFx` (parçacık, kombo yazısı).
  "Hareketi azalt" açıkken kamera süzülmesi, salınım, parçacık ve akış kapanır.
- **Ses** `AudioService` olaylardan ses çalar; sesler `SfxBank`'te koddan üretilir (ses dosyası yok). Ek olarak sessiz, dikişsiz bir sera uğultusu döngüsü (`SfxBank.make_ambience`) ses ayarına bağlı çalar.

## 9. Ekonomi kuralları (FAZ 3)

Sayılar `assets/data/economy/default_economy_config.tres` (`EconomyConfig`), olaylar `events/*.tres` (9), sipariş şablonları `orders/*.tres` (9).

- **Başlangıç** 120 kredi; **çaprazlama** 40 kredi, 2 çocuk (`offspring_per_cross`); yeni tür keşfi +60, yeni çeşit +12 kredi (`SeedDex` bonusu).
- **Fiyat** `birim = ortalama_değer × eğilim × arz × olay_çarpanları`. Eğilim her 15 sn'de rastgele yürür (`price_volatility 0.05`, ortalamaya dönüş
  `price_reversion 0.12`, sınır 0.5–2.5). Satış arzı birim başına 0.02 düşürür (taban `supply_floor` 0.4); arz saniyede 0.002 toparlanır.
  Toplu satışta fiyat birimden birime iner (`MarketService.quote`).
- **Haber olayları** her 70–140 sn'de bir (en çok 2 eş zamanlı): belirli meyveye ya da mutasyona çarpan (örn. ×1.6 patlama, ×0.6 bolluk). Haber şeridi HUD'dadır.
- **VIP siparişler** 3 slot, 40 sn'de bir yenilenir, 420 sn süre; ödül = `adet × referans değer × 1.6 × şablon çarpanı × (1 + seviye × 0.05)`;
  itibar seviyesi = itibar ÷ 3, yüksek seviye daha zor şablonları açar. Teslim, uygun yığınlardan düşer.
- **Dürüstlük notu:** ekonomi insan oynatılarak değil benzetimle dengelendi (bölüm 14, karar 17).

## 10. Otomasyon kuralları (FAZ 4)

- **Ekipman** `assets/data/equipment/*.tres`: Otomatik Sulama (satır başına, 1 seviye), UV Lambası (satır başına, 2 seviye), Hasat Dronu (kat başına, 4 seviye,
  maliyet çarpanı 1.7), Laboratuvar UV Odası (genel, 3 seviye; yeni mutasyon olasılığını artırır). Maliyet = `cost × cost_growth^seviye` (yuvarlanmış; `EquipmentDef.cost_for_level`).
- **Katlar** `floors/floor_0..3.tres`: sırayla açılır (0 / 900 / 2600 / 7000 kredi); kilitli katta dron/büyüme yoktur.
- **Dron** `DroneAgent` AÇIK geçiş tablosu olan durum makinesidir: `IDLE → SEEKING → FLYING_TO → HARVESTING → RETURNING → IDLE`.
  Hedef saksı rezerve edilir (iki dron aynı bitkiye gitmez); hasat `drone_harvest_seconds` 0.7, hız 2.6 (ızgara birimi/sn). Dron, hasadı `FarmService.harvest(..., replant=true)` ile yapar.

## 11. Oyun oturumu, arayüz ve tasarım dili

**Düğüm ağacı (`src/ui/main.tscn`).** Arayüz DEĞİŞTİRİLEBİLİR bir kökün (`Ui`) altında kurulur; dil değişince bu kök atılıp yeni dille yeniden kurulur
(etkin sekme ve açık ayarlar korunur). Manzara, `GameSession`, ses ve titreşim kökün dışındadır.

```text
Main (Control)
├── NightBackdrop · GameSession (Node) · AudioService · HapticsService
└── Ui (Control)
    ├── SafeArea (MarginContainer)               güvenli alan (çentik/sistem çubuğu) kenar boşlukları
    │   └── Column (VBoxContainer)
    │       ├── HudBar                           kredi (sayarak) · gün çizgisi · hız · menü · itibar · hedef çipi · haber
    │       ├── Content (Control)                FarmPanel · LabPanel · MarketPanel · DexPanel · UpgradesPanel (yalnızca biri görünür)
    │       └── NavBar                           5 sekme, ikon + etiket, dikkat rozeti
    └── ToastLayer · SettingsOverlay · GoalsOverlay · OfflinePopup · IntroOverlay
```

**Kural:** arayüz oyunu DEĞİŞTİRMEZ; `GameSession` komutlarını (`plant_seed`, `harvest_pot`, `harvest_floor`, `sell`, `fulfil_order`, `crossbreed`, `buy_*`, `unlock_floor`, ...)
çağırır, dönen `CommandResult` (`ok`, `message_key`, `args`) bildirim olur. Tüm metin `tr("ANAHTAR")` ile gelir; oyun verisi (.tres) de çeviri ANAHTARI tutar.

**Tasarım dili** (`design/design-language.md`): belirteçler `UiTokens`, tema `UiTheme`, yazı tipleri `UiFonts` (Bricolage Grotesque başlık/sayı, Nunito Sans gövde; SIL OFL),
ikonlar `UiIcons` (42 SVG, kredi renkli), hareket `UiMotion` (süreler `UiTokens.DUR_*`, hareketi azalt'ta hiçbir animasyon oynamaz), sayı biçimi `UiFormat` (dile duyarlı).
Hiçbir panel renk/piksel/süre sabitlemez. Ekran başına tek birincil (klorofil) düğme kuralı ve anti-slop listesi belgededir.

**Yerelleştirme:** `strings.csv` (arayüz) ve `content.csv` (oyun içeriği) `keys,tr,en`. `Localization.apply` dili seçer; ilk açılışta sistem dili (`GameSettings.default_language`: Türkçe ise
Türkçe, değilse İngilizce), ayarlardan değişir. `localization_keys_test` şunları denetler: koddaki her anahtar tabloda, her satır iki dilde dolu, `%d/%s` işaretçileri iki dilde aynı,
oyun verisindeki her anahtar çözülüyor, metinde yedek-font sembol glifi yok, paketlenen yazı tipleri her metin karakterini içeriyor.

**Hedefler ve kurgu:** `GoalService` (15 hedef, `assets/data/goals/`): sıralı zincir, ilerleme tüm hedeflere birikir, ödül cüzdana yazılır, kayıtta tutulur. HUD çipi etkin hedefi, `GoalsOverlay`
tümünü gösterir. **FLORA** (kulenin bakım yapay zekâsı) ipuçlarını (`FloraBubble`) ve ilk açılış kartını (`IntroOverlay`, bir kez) söyler.

**Erişilebilirlik:** yazı boyutu 4 kademe (×0.9 / ×1.0 / ×1.2 / ×1.4), renk körlüğü paleti (mavi/turuncu, şekille destekli), hareketi azalt, 84 px dokunma hedefi, titreşim ayarı, "Hasat" tek dokunuş düğmesi,
kontrast testle korunur (`ui_tokens_contrast_test`: bilgi taşıyan her renk WCAG AA), Android geri tuşu (pencere kapat → çiftliğe dön → çift basışla çık).

**Kayıt (`SaveManager`):** durum sözlüğü → JSON → `{checksum: SHA-256, payload}` → `FileAccess.open_encrypted_with_pass` (AES). Yazma atomik:
`.tmp`'ye yaz, doğrula, taşı; öncekini `.bak` yap. Okuma bozuk/sağlaması tutmayan dosyada yedeğe düşer. Otomatik kayıt 20 sn'de bir, uygulama duraklatılınca
ve kapanırken. **Dürüst sınır:** anahtar uygulamanın içindedir; şifreleme elle düzenlemeyi CAYDIRIR, gerçek güvenlik değildir.

## 12. Çevrimdışı ilerleme

`OfflineProgress.apply(farm, automation, away_seconds)` oyuncu yokken geçen süreyi (en çok `offline_max_hours` 8 sa) **kaba adımlarla** (5 sn) çiftlik
hizmetine işletir: bitkiler büyür, susuz kalan durur, olgunlar aşırı olgunlaşır. Dron hasadı kapasiteyle sınırlıdır:
`hak = dron × dt / offline_drone_cycle_seconds` (4 sn). Çevrimdışı hasat verimi `offline_yield_factor` (0.5) ile çarpılır (aktif oyun hep daha kazançlıdır).
Sonuç `OfflineReport` (hasat sayısı/birimi/değeri, bekleyen olgun, aşırı olgun, kaybedilen değer, tavan aşıldı mı) olur ve `OfflinePopup` ile gösterilir;
60 sn'den kısa uzaklıkta rapor çıkmaz. Dönüşte piyasa (`MarketService.tick`) ve siparişler (`OrderService.tick`) benzetilen süre kadar TEK çağrıyla ilerletilir (piyasa trend adımı çağrı başına sınırlıdır); oyun saati de ilerler.

## 13. Test ve doğrulama

- Koşucu: `bash tools/run_tests.sh [--filter=...]` (gdUnit4 stili çıkış kodları: 0 geçti, 100 başarısız, 105 yükleme hatası,
  2 test yok; Godot çıktısında `SCRIPT ERROR` varsa 1). gdUnit4 kurulumu kullanıcı onayı bekliyor (bkz. 15); test dosyaları gdUnit4'e geçişte adlandırmayı korur.
  Şu an **433 test** geçiyor (birim: genetik, çiftlik, ekonomi, otomasyon, Seed-Dex, kayıt, arayüz yardımcıları; entegrasyon: gerçek veri + gerçek sahneler,
  `Main` arayüzü: dokunuş, kaydırma, satış, sipariş, çaprazlama, satın alma, ayarlar, dil değişimi, rozetler, bildirim birleştirme, hedefler, açılış kartı, geri tuşu, uzun ekran, en büyük yazı iki dilde).
- İstatistiksel testler tohumlu RNG ile deterministiktir. Testlerin gerçekten bir şey yakaladığı **mutasyon testiyle** (kodu bilerek bozup testin kırıldığını
  görerek) doğrulandı: FAZ 1 (`PlantInstance` 35/35), FAZ 2 (38/38), FAZ 3–4 (5 sağ kalan yeni testlerle kapatıldı ve yeniden çalıştırılarak doğrulandı) ve FAZ 5 mantığı
  (`OfflineProgress`, `SeedDex`, `SaveManager`, `GameSettings`: 46 mutant; ilk turda 15 sağ kaldı, yeni testlerle 44'ü yakalandı). Kalan ikisi: `op_budget_carry_unbounded`
  EŞDEĞER mutanttır (`minf(budget, 1.0)` döngüden sonra zaten < 1 olan değeri değiştirmez); `sm_no_verify` (yazılan dosyayı geri okuyup doğrulama) dosya sistemi
  hatası enjekte edilmeden sınanamaz ve savunma amaçlı bırakıldı. Cila turunun mantığı (`GoalService`, `MarketService` fiyat geçmişi, `AutomationService.cheapest_purchase_cost`, `GameSession.harvest_floor`, `UiFormat`) 25 mutantla denendi: ilk turda 13'ü yakalandı, 12'si sağ kaldı; 7'si gerçek test boşluğuydu ve yeni testlerle kapatıldı (hepsi yeniden koşularak doğrulandı), `g_current_first_done` sonsuz döngüye girip zaman aşımına uğradı (yakalanmış sayıldı). Kalan 4'ü eşdeğer ya da savunma amaçlı: `g_no_cap`, `g_load_no_clamp`, `g_progress_of_uncapped` (hedef sınırı üç katmanda uygulanıyor: yazma, yükleme, okuma; biri kalkınca diğer ikisi gözlenebilir davranışı aynı tutar) ve `m_history_not_detached` (Godot paketli dizileri yazmada kopyalar [COW], dönen dizi değiştirilse bile kaynak değişmez; `duplicate()` savunma amaçlı). 2.5D çiftlik sahnesi (`FarmStage`, `FarmView` dokunuş/isabet, `PlantAtlas`, saksı ağı) 26 mutantla denendi: ilk turda 19'u yakalandı; 6'sı gerçek test boşluğuydu (isabet sınır testleri sabitlerin kendisine bağlıydı ve mutasyonla birlikte kayıyordu; kamera kayması, kare boyutu sınırı ve hareketi azalt anında yeniden uygulama sınanmıyordu) ve mutlak sayılarla yazılan testlerle kapatılıp yeniden koşularak doğrulandı (6/6). Kalan 1'i eşdeğer: `_sync_halo`'daki "parlak değilse gizle" koruması, parlama gücü 0 olduğunda zaten aynı sonucu verir. `PotOverlay` (ekran uzayı 2D çizim) ve gölgelendiriciler mutasyonla sınanmadı: görsel kanıtla doğrulanır. `GameSession` geri kalanı ve arayüz için sistematik mutasyon turu yapılmadı (`Main` entegrasyon testleri var).
- Görsel kanıt: `production/qa/evidence/` altında `faz1-plant-instance/`, `faz2-farm/`, `ui-polish/` (her birinde README ve `stamp.txt`). Yeniden üretmek için:
  `bash tools/capture_screenshot.sh <sahne.tscn> <çıkış.png> [--frames=N] -- <seçenekler>` (`CAPTURE_SIZE=1080x2400` ile uzun ekran),
  arayüz setinin tamamı (iki dil, üç boyut/ölçek, renk körlüğü, hareketi azalt) için `bash tools/capture_ui_evidence.sh`.
- Ayrıştırma denetimi: şablonun `godot-parse-check.gd` betiği (`src/` ve `tests/` altındaki tüm betikler temiz).
- Android: `godot --headless --export-release "Android Release" build/floralab-1.1.0.apk` (imza bilgisi `GODOT_ANDROID_KEYSTORE_RELEASE_*` ortam
  değişkenlerinden; anahtar deposu depoda YOK). Denetim: `apksigner verify` (v2+v3 geçerli), `aapt2 dump badging` (paket `com.tigirer.floralab`, sürüm 1.1.0/2,
  minSdk 24, arm64-v8a, izin yok, `debuggable` değil), paket içeriği (testler/geliştirici sahneleri yok, betikler derlenmiş, çeviri var) ve aynı ön ayardan `--export-pack`
  ile üretilen `.pck`'nın başsız açılıp 35 oyun saniyesi çalışması (şifreli otomatik kayıt yazıldı, hata yok). **Gerçek bir Android cihazda/emülatörde çalıştırma yapılmadı.**

## 14. Kararlar ve sapmalar

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
| 13 | Hizmetler `RefCounted`, `GameSession` kompozisyon kökü | Autoload yok (karar 1); testler hizmetleri sahnesiz kurar. Açık soru 2 çözüldü: `TimeManager`/`SaveManager` Autoload DEĞİL |
| 14 | Arayüz oyunu yalnızca komutla değiştirir (`CommandResult`) | şablon `ui-code.md`; mesaj anahtarı + argüman, metin arayüzde `tr()` ile |
| 15 | Yerelleştirme: tek sütunlu CSV (`tr`), yedek dil `tr` | derlenen `.translation` git'te yok (`.gitignore`), içe aktarmada üretilir: temiz klonda `godot --headless --import` gerekir. CSV'deki bir metni değiştirince yeniden içe aktarmayı unutmak ekran görüntüsünde eski metni gösterir (bir kez yaşandı) |
| 16 | Çevrimdışı benzetim kaba adım (5 sn) + kapasiteli dron hasadı + verim çarpanı 0.5 | ilk sürümde 1,5 sa ≈ 805 dron hasadı (~◆21k) çıktı: çok cömert. Dron hakkı `dron × dt / 4 sn`, çevrimdışı verim ×0.5, büyüme 45 sn, verim 2 |
| 17 | Ekonomi dengesi benzetimle ayarlandı, insan oynatılmadı | fiyat/maliyet sayıları veridedir (`*.tres`); gerçek oyuncu testinden sonra yeniden ayarlanmalı |
| 18 | Kayıt şifrelemesi caydırıcıdır | AES anahtarı uygulamanın içinde; sağlama toplamı + atomik yazma + `.bak` asıl değerdir (bozulma/yarım yazma koruması) |
| 19 | Yakalama aracı görüntü alanını da ayarlar | `--write-movie` kareyi pencereye değil projenin viewport boyutuna göre yazar; 1080×2400 çekimi kırpılıyor ve arayüz hatalı sanılıyordu |
| 20 | Sekme yazısı ölçeğin %30'unu izler, "Laboratuvar" → "Lab" | en büyük yazıda beş sekme 1067 px istiyordu (alan 1032); taşma tüm sütunu sağa itiyordu. Gerileme testi var |
| 21 | Release ön ayarı: `exclude_filter` ile testler/belgeler/geliştirici sahneleri dışarıda | APK 26,9 MB; derlenmiş betikler (`.gdc`) |
| 22 | Release imzası ortam değişkenlerinden, anahtar deposu depoda yok | kimlik bilgisi sızıntısı olmasın. Anahtar deposu geçici kapta üretildi: güncelleme zinciri için kullanıcı kendi anahtarını üretip yeniden imzalamalı |
| 23 | Tasarım dili belgesi + belirteçler: "Gece Serası" | "AI slop"u (tek tip turkuaz kart, her düğme birincil, sembol glifli metin) kural olarak yasaklamak için; ekran başına tek birincil düğme, kademeyle ayrışan yüzeyler. `design/design-language.md` |
| 24 | Yazı tipleri: Bricolage Grotesque + Nunito Sans (değişken, OFL), paketlenir | cihazın varsayılan fontuna bağımlılık yok; Türkçe İ/ı/Ğ/ğ/Ş/ş testle doğrulanır. Sembol glifleri (◆▲▼★✓) yasak, SVG ikon kullanılır (yedek font garantisi yok) |
| 25 | Oyun verisi (.tres) çeviri ANAHTARI tutar, `tr()` gösterimde | iki dil aynı veriyle; kayıtta eski düz metin (anahtar olmayan) olduğu gibi görünür (geriye uyum). `content.csv` ayrı dosya: tasarımcı içeriği arayüzden ayrı düzenler |
| 26 | Dil değişince arayüz kökü baştan kurulur | panellerin her statik etiketini yeniden çevirmek yerine tek yol; durum `GameSession`'dadır, kayıp yok. Sistem dili yalnızca ilk açılışta okunur |
| 27 | `PriceButton`: içerik satırı + `custom_minimum_size` eşitlemesi | `Button` kendi `get_minimum_size`'ını yerel kodda tanımlar, betik sanal metodu çağrılmaz; en büyük yazıda düğmeler çöküyordu (testle yakalandı, `main_screens_test`) |
| 28 | Hedefler veri odaklı ve sıralı; ilerleme tüm hedeflere birikir | oturum hedefsiz kalmasın ("Player goal" tamamlanmışlık); sıradaki hedef önceden tamamsa art arda tamamlanır |
| 29 | `HapticsService` ayrı düğüm, titreşim enjekte edilebilir | ayardaki "Titreşim" anahtarı önceden hiçbir şey yapmıyordu; artık olaydan (hasat, ödül, hata) darbe çıkar |
| 30 | Pazar fiyat geçmişi `MarketService`'te (meyve başına son 24 endeks örneği, kayda dahil) | mini grafikler gerçek veriyi çizer; ekonomi kuralları değişmedi |
| 31 | Çiftlik görünümü 2.5D: Node3D sahne + perspektif kamera, bitkiler atlas dörtgeni | tam 3D bitki üretimi 15 parçalık sanat hattını baştan yazdırırdı ve düzlemdeki kusursuz dokunuş eşlemesini bozardı; derinlik geometri, kamera ve ışıktan gelir. Mantık katmanına dokunulmadı |
| 32 | Ekran <-> düzlem dönüşümü kameradan analitik hesaplanır | `Camera3D.unproject_position` çizilmiş pencereye ve kamera durumuna bağlı; analitik hesap başsız testlerde deterministik ve birim testlenebilir (gidiş-dönüş, 4 kat boyutu × 4 en-boy oranı) |
| 33 | Bitkiler tek ortak `PlantAtlas` SubViewport'unda | `PlantInstance` sanatı/gölgelendiricisi aynı kalır; bitki başına 16 pencere yerine kare başına tek 2D geçiş. Halo atlasta çizilemez (toplamalı karışım), sahnede ayrı bilboard |
| 34 | Gerçek gölge haritası yok, temas gölgesi bilboard; ortam + güneş + 1 OmniLight/UV satırı | mobil Compatibility bütçesi; gölge geçişi ve çoklu ışık maliyeti ölçülmeden eklenmedi |

## 15. Açık sorular ve bilinen sınırlar

1. **gdUnit4:** üçüncü taraf eklentinin kurulup çalıştırılmasına izin veriyor musun? Şimdilik kendi koşucum (aynı çıkış kodları) kullanılıyor;
   `project.yaml` → `commands.test` bilerek gdUnit4'ü gösterir (`project-coherence.sh` tek bir "DIFFERS" bildirir: beklenen ve belgelenmiş fark).
2. **Gerçek cihaz:** APK paket/imza/başsız açılış olarak doğrulandı; bir Android cihazda dokunma hissi, performans, güvenli alan (çentik) ve geri tuşu denenmedi.
   **2.5D sahnenin cihazdaki kare hızı ve pil maliyeti ölçülmedi** (yalnızca yazılım OpenGL'li Xvfb'de çizildi); 4×4 katta düşük sınıf cihazda ağır olabilir.
   Gerekirse ilk kısmalar: MSAA'yı kapatmak, `SubViewport` çözünürlüğünü küçültmek, OmniLight'ları kaldırmak, atlas hücresini küçültmek.
3. **Performans bütçeleri** (`project.yaml`) bilinçli olarak boş: hedef cihaz sınıfı belirlenince doldurulacak.
4. **Sanat:** SVG parçalar yer tutucu kalitede ama oyun içi kullanıma uygun; elle çizilmiş sanat gelirse `PlantPartDef.texture` değişir, kod değişmez.
5. **Dil:** Türkçe ve İngilizce; yeni dil = iki CSV'ye sütun + `GameSettings.LANGUAGES` + `project.godot` çeviri listesi. İngilizce metinlerin dil bilgisi/ton denetimi ana dili İngilizce olan biri tarafından yapılmadı.
6. **Ses:** sesler kodla üretilen yer tutucu seslerdir (efektler + alçak sera uğultusu); ses tasarımcısı eli değmedi, müzik yok.
7. **Mutasyon testi kapsamı:** FAZ 1–5 mantık sınıfları mutasyonla doğrulandı (bölüm 13); `GameSession` (komut katmanı) ve arayüz panelleri için sistematik mutasyon turu yok: bunlar entegrasyon testleriyle (`game_session_flow_test`, `main_screens_test`) ve ekran görüntüleriyle sınandı.
8. **Ekonomi/denge:** insan oynatması yok (karar 17). Çevrimdışı dönüşte piyasa/siparişler tek tikle ilerler (ayrıntılı çevrimdışı piyasa benzetimi yok).
9. **Güncelleme imzası:** release anahtar deposu depoda yok (karar 22); mağaza yayını için kendi anahtarınla imzalamak gerekir.
