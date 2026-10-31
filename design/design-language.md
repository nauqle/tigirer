# FloraLab: Tasarım Dili — "Gece Serası"

Bu belge oyunun görsel, hareket, yazı ve ses kararlarının TEK kaynağıdır. Her değer kodda `UiTokens`, `UiTheme`, `UiMotion`, `UiFonts`,
`UiIcons` içinde yaşar; panel kodu renk, piksel, süre ya da metin SABİTLEMEZ. Bir görünüm kararını değiştirmek = bu belgede ve ilgili belirteçte
değiştirmek. Tasarım kaydı (ne, neden): `design/game-brief.md`. Mimari: `docs/architecture/floralab-architecture.md`.

## 1. Fikir

Terk edilmiş bir gökdelenin gece serası. Şehir aşağıda karanlık; kulenin içinde yalnızca UV lambaları, biyolüminesan bitkiler ve bakım yapay zekâsı
FLORA'nın ışığı yanıyor. Her ekran bu üç ışıktan birini taşır: **klorofil** (büyüme, eylem), **mor** (UV, mutasyon), **kehribar** (kredi).

| İlke | Anlamı | Kod/ekran karşılığı |
|---|---|---|
| **Işık hiyerarşidir** | Parlak olan önemlidir. Yüzeyler çizgiyle değil KADEMEYLE ayrılır; vurgu yalnızca anlamı olan şeyde yanar | `SURFACE_1..4`, `PrimaryButton` (ekranda tek) |
| **Bitki yıldızdır** | Arayüz bitkileri çerçeveler, onlarla yarışmaz. Bitki çizimi her ekranda aynı (`PlantPreview`) | Seed kartı, dex kartı, lab kavanozu |
| **Her şey tepki verir** | Dokunma, kazanç, keşif, hata: görsel + ses + titreşim üçlüsü | `FxButton`, `UiMotion`, `AudioService`, `HapticsService` |
| **Şekil renkten önce gelir** | Renk tek başına bilgi taşımaz (yükseliş/düşüş = ikon + renk) | `trend_up/down` ikonları, renk körlüğü paleti |
| **Sakin ama canlı** | Hareket ortamı yaşatır, dikkati çalmaz; hareketi azalt ile tamamen kapanır | ambient döngüler 2.4 sn+, pop 0.26 sn |

### Anti-slop denetim listesi (her ekran bunu geçmeden kapanmaz)
1. Ekranda **tek** birincil (klorofil dolgulu) eylem var mı? Fazlası "yeşil dilim duvarı"dır.
2. Her yüzey aynı turkuaz çerçeveli kart mı? Kademe/varyasyon (`Card`, `CardRaised`, `CardAccent`, `CardUv`) anlam taşıyor mu?
3. Metin sembol glifi (◆ ▲ ▼ ★ ✓) içeriyor mu? **İçermez**: ikon kullanılır (cihazın yedek fontu garanti değildir).
4. Sayı dile uygun biçimli mi (12.480 / 12,480)? Elle `%d` ile gömülen kredi var mı? (`UiFormat` kullan)
5. Boş durum, hata durumu ve en büyük yazı boyutu çizildi mi? Taşan/kırpılan metin var mı?
6. Animasyon süreleri `UiTokens.DUR_*` mı, hareketi azalt'ta kapanıyor mu?
7. Bu ekranda FLORA'nın sesi (kısa, kuru, somut) var mı, yoksa jenerik talimat metni mi?

## 2. Renk

Koyu "kömür-yeşili" zemin; metin kemik beyazı. Hiçbir yerde saf siyah/saf beyaz yok.

| Belirteç | Hex | Kullanım |
|---|---|---|
| `BG_DEEP` / `BG` | `#060b0a` / `#0a120f` | sahne zemini |
| `SURFACE_1` | `#101b17` | kart, sayfa |
| `SURFACE_2` | `#172722` | yükseltilmiş kart, düğme |
| `SURFACE_3` | `#20352d` | çip, ilerleme izi |
| `SURFACE_4` | `#2b463b` | anahtar izi |
| `HAIRLINE` | beyaz %9 | ince kenar |
| `TEXT` / `TEXT_MUTED` / `TEXT_DIM` | `#eef4e6` / `#9fb4a6` / `#68796f` | metin kademeleri |
| **`ACCENT` (klorofil)** | `#a6f04a` | büyüme, ana eylem, seçili, olumlu |
| `ACCENT_DARK` | `#12200a` | klorofil üstündeki metin |
| **`UV` (mor)** | `#a883ff` | UV ışığı, mutasyon, nadirlik üst katmanı |
| **`AQUA`** | `#4fcfff` | su, bilgi, FLORA |
| **`SAP` (kehribar)** | `#ffc35a` | kredi, ödül |
| **`BLOOM` (mercan)** | `#ff6f61` | olumsuz, uyarı, düşüş |

**Renk körlüğü kipi** (kırmızı-yeşil ayrımına dayanmaz): iyi = `#5cc8ff` mavi, kötü = `#ffa31a` turuncu, vurgu = mavi. `UiTokens.palette(colorblind)`.
**Nadirlik:** sıradan (soluk) < seyrek (klorofil) < nadir (aqua) < mutant (mor + parıltı). Eşikler `UiTokens.UNCOMMON_VALUE / RARE_VALUE` (yalnızca sunum).

## 3. Tipografi

İki aile, ikisi de **SIL OFL** (lisanslar `assets/fonts/`), ikisi de değişken (`wght` ekseni), Türkçe ve İngilizce karakterlerin TAMAMINI içerir
(`tests/unit/ui/localization_keys_test.gd` her metin karakterini yazı tipinde doğrular).

| Rol | Yazı tipi | Ağırlık | Ölçek (taban 30 px) |
|---|---|---|---|
| Sayı, başlık, ekran adı | **Bricolage Grotesque** | 700–800 | Display 2.0×, Title 1.5×, Heading 1.2× |
| Gövde, düğme | **Nunito Sans** | 500–780 | 1.0× (Small 0.82×, Micro 0.68×) |
| Küçük başlık (overline) | Nunito Sans, 3 px harf aralığı | 780 | 0.68×, BÜYÜK HARF |

Kullanıcı yazı ölçeği 0.9 / 1.0 / 1.2 / 1.4. Alt gezinme yazısı ölçeğin yalnızca %30'unu izler (beş sekme sığmalı). Satır içi sembol yok: kredi simgesi
`{c}` işaretiyle ikon olarak çizilir (`UiKit.credit_text`).

## 4. Boşluk, yarıçap, yükseklik

8 noktalı ızgara: 8 / 16 / 24 / 32 / 48. Yarıçap: 14 (küçük), 22 (düğme/kart içi), 30 (kart), 40 (sayfa), hap. Yükseklik gölgeyle değil önce KADEMEYLE,
sonra yumuşak gölgeyle (`CardRaised`, `Toast`, `Sheet`) verilir. Dokunma hedefi en az 84 px (`UiTokens.TOUCH_MIN`).

## 5. Bileşenler

| Bileşen | Kural |
|---|---|
| `FxButton` | basınca 0.955 ölçek + yaylanma, ses olayı; **ekranda tek `PrimaryButton`** |
| `PriceButton` | [ikon] metin [kredi ikonu tutar]; kredi yetmiyorsa soluk ve pasif; yetiyorsa `BuyButton` (klorofil çerçeve) |
| `CreditTag` | renkli öz kristali + sayı; artışta sayarak yükselir ve sıçrar |
| `NavBar` | ikon + etiket, seçili = klorofil yumuşak hap + yaylanan ikon; dikkat rozeti nabız atar |
| `ToggleSwitch` / `SegmentedControl` | ayar satırının tamamı dokunma hedefi; yaylanan topuz |
| `SeedCard`, `FloraBubble`, `PriceChart`, `ProgressRing`, `LevelPips` | `src/ui/common/` |
| `SheetOverlay` | alttan açılan sayfa (ayarlar, hedefler); karartmaya dokun = kapat |
| Kart varyasyonları | `Card` (varsayılan) · `CardRaised` (öne çıkan) · `CardAccent` (etkin/hazır) · `CardUv` (mutasyon/UV) · `CardWarn` (kayıp) |

## 6. Hareket

Süre ve eğri yalnızca `UiTokens` / `UiMotion` üzerinden. Eğriler: giriş = OUT, ödül/pop = BACK-OUT (en çok %12 aşım), ortam = SINE in-out.

| Ad | Süre | Nerede |
|---|---|---|
| `DUR_PRESS` | 0.09 sn | düğme basma |
| `DUR_QUICK` | 0.16 sn | sekme geçişi, solma |
| `DUR_BASE` | 0.26 sn | pop-in, sayfa kayması |
| `DUR_SLOW` | 0.45 sn | sayaç, halka, sayfa girişi |
| `DUR_AMBIENT` | 2.4 sn | nabız, ışıltı, paralaks (38 sn) |

Kalıplar: **pop-in** (yeni öğe), **stagger** (liste, 45 ms arayla), **count-up** (kredi), **bump** (kazanç), **shake** (reddedilen eylem), **pulse** (dikkat).
**Hareketi azalt:** `UiMotion.reduce_motion` açıkken hiçbir animasyon oynamaz (öğeler doğrudan son durumuna konur); paralaks, pencere titreşimi, kıvılcım böcekleri,
parçacıklar, boru akışı ve ışıltılar kapanır. İçerik kaybolmaz.

## 7. İkonografi

42 SVG, 48 px ızgara, 3.5 çizgi, yuvarlak uç; tek renk beyaz (tema renginden boyanır), yalnızca `credit` renkli (öz kristali). Üretici: `tools/art/make_icons.py`.
Yeni ikon = betiğe satır + `UiIcons.NAMES` listesine ad (test dosyayla karşılaştırır). Metin içinde ikon: `{c}` işareti.

## 8. Arka plan ve oyun saati

`NightBackdrop` oyun saatini (`TimeManager.day_progress`) izler: gece → şafak → gündüz → alacakaranlık → gece. Ay/güneş yay çizer; yıldızlar geceleyin;
iki katman paralaks silüet; pencereler `skyline_windows` gölgelendiricisinde kendi hızında titreşir; alçak sis; kenar karartması metni korur. HUD gün ikonu
(gün/ay) ve ince gün çizgisi aynı evreyi gösterir. Çiftlik ızgarası geceleyin hafif soğuk, gündüz hafif sıcak tonlanır.

## 9. Geri bildirim

- **Bildirim (toast):** HUD'un altında, en çok 3 hap; aynı metin art arda gelirse "×N" olur. Anlam ikonla (tik, ışıltı, ok) ve renkle.
- **Ses:** olaydan (SignalBus) `AudioService` seçer; UI doğrudan ses çalmaz. Arka planda çok alçak (efektlerin en az 15 dB altında), dikişsiz 8 sn'lik bir sera uğultusu döner (`SfxBank.make_ambience`);
  ses kapatılınca susar, açılınca yeniden başlar. Uğultu müzik değildir: melodi yok, dikkat çekmez.
- **Titreşim:** `HapticsService`: hasat (komboyla uzar), ödül, hata, mutasyon. Ayardan kapanır.
- **Kredi akışı:** hasatta sikkeler HUD'a uçar, HUD'da "+N" yükselir.

## 10. Yazım sesi (TR / EN)

**FLORA**: kulenin bakım yapay zekâsı. Sakin, kuru, somut; en çok iki kısa cümle; ünlem yok (ödül anları hariç); sayıyla konuşur, süsle değil.
Kurgu: şehir yıllar önce karardı, kule hâlâ nefes alıyor; sera yeniden canlanıyor; müşteriler kafe, çiçekçi, galeri, genetik enstitüsü.

| Kural | TR | EN |
|---|---|---|
| Düğme = fiil | "Sula", "Hasat", "Teslim et" | "Water", "Harvest", "Deliver" |
| Başlık kısa | "Çaprazlama", "Fiyat tablosu" | "Crossbreed", "Price board" |
| Sayı biçimi | 12.480 · 1,60 · %45 | 12,480 · 1.60 · 45% |
| İpucu = durum + eylem | "Bir saksı kurumak üzere. Dokun, sulayalım." | "A pot is running dry. Tap it and I'll water it." |

Çeviri anahtarı kuralı: oyun verisi (`.tres`) çeviri ANAHTARI tutar (`PART_*`, `MUT_*`, `EVT_*`, `ORD_*`, `GOAL_*` ...); metin `assets/i18n/content.csv` ve `strings.csv`
(ikisi de `keys,tr,en`). Yeni dil = iki CSV'ye sütun + `GameSettings.LANGUAGES` + `project.godot` çeviri listesi. Biçim işaretçileri iki dilde aynı olmalıdır (test).

## 11. Erişilebilirlik

Ölçeklenebilir yazı (4 kademe), renk körlüğü paleti (şekille destekli), hareketi azalt, 84 px dokunma hedefi, tek elle kullanım (alt gezinme, eylemler başparmak
bölgesinde), kaydırması zor oyuncular için "Hasat" düğmesi (tek dokunuşla toplu hasat), titreşim ayarı.

**Kontrast (ölçüldü, test korur):** `TEXT` yüzeylerde ≥ 11.6:1; `TEXT_MUTED` ≥ 5.9:1; klorofil/kehribar/aqua ≥ 7.3:1; mor ve mercan ≥ 4.6:1 (hepsi WCAG AA). `TEXT_DIM` AA'nın
altındadır (2.8–4.1:1): YALNIZCA pasif ve dekoratif öğelerde (kilit ikonu, devre dışı düğme) kullanılır, bilgi taşımaz. Renk körlüğü paleti de ≥ 6.5:1.

## 12. Kod eşlemesi

`UiTokens` (renk, boşluk, yarıçap, süre, nadirlik) → `UiTheme` (tür varyasyonları, yazı tipleri) → `UiKit` (kurucular) → bileşenler (`src/ui/common/`) → paneller
(`src/ui/panels/`). Dosya listesi: mimari belge, bölüm 2.
