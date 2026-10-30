# Game Brief: FloraLab: Cyber Harvest

<!-- Şablon: .claude/docs/templates/game-brief.md. `minimal` düzeyde bu belge TÜM tasarım kaydıdır.
     Motor ayrıca project.yaml'dadır, burada tekrarlanmaz. Kaynak: proje sahibinin ilk konsept metni.
     "(öneri)" ile işaretli satırlar sahibi tarafından VERİLMEMİŞTİR; onay bekler. -->

**One-sentence pitch:** Terk edilmiş bir gökdelenin katlarında hidroponik bir dikey çiftlik kur; prosedürel genetikle bitki çaprazla, parmağını kaydırarak tatmin edici (ASMR) bir hasat yap ve nadir mutasyonlarını canlı bir borsada sat.

## Core loop
- Saksıya tohum dik; su ve UV ışıkla bitki **Tohum → Filiz → Olgun** evrelerinden geçer.
- Olgun bitkiyi **parmağını kaydırarak biç** (veya hasat dronu topla) → meyve ve tohum envantere girer.
- Ürünü **dinamik borsada** ya da **VIP siparişlerde** sat → parayla saksı, boru, UV lambası, dron ve yeni gökdelen katı al.
- İki tohumu **çaprazla**: ebeveyn genleri aktarılır, %5 ihtimalle nadir mutasyon çıkar → yeni görünüm ve değer → **Seed-Dex**'e kayıt → daha iyi bitki.

## Player goal & fail state — what "working" looks like
- Hedef: Seed-Dex'i doldurmak (keşfedilen her yeni kombinasyon kayıtlıdır), gökdelenin katlarını canlandırmak, en değerli mutasyonları üretmek.
- Fail state yoktur (rahat / idle tycoon). Bir oturum, oyuncu **en az bir yeni kombinasyon keşfedip ya da bir sipariş teslim ettiğinde** tamamlanmış hisseder (öneri).

## MVP — what must exist to be the game
- Katmanlı prosedürel bitki: gövde + yaprak + çiçek/meyve parçaları, genetik renk ve parlama (FAZ 1)
- Mendel çaprazlama, baskın/çekinik parçalar, %5 mutasyon, kalıtım (FAZ 1)
- Hidroponik ızgara, büyüme evreleri, su/ışık çarpanları, parmak kaydırarak toplu hasat (FAZ 2)
- Dinamik borsa (arz-talep, haber olayları), envanter, VIP sözleşmeler (FAZ 3)
- Otomatik sulama/ışık, hasat dronu durum makinesi, yeni kat açma (FAZ 4)
- Dikey mobil arayüz, Seed-Dex, şifreli kayıt, çevrimdışı kazanç (FAZ 5)

## Out of scope — not building this
<!-- Hepsi öneri: sahibi onaylamalı ya da değiştirmeli. -->
- Çok oyunculu ve çevrimiçi özellikler (liderlik tablosu, bulut kayıt) (öneri)
- Gerçek parayla satın alma ve reklam (öneri)
- 3D grafik: oyun 2D/2.5D katmanlı sprite ile yapılır (sahibinin konsepti)
- Elle çizilmiş bitki sanatı: bitki parçaları vektör (SVG) ve prosedürel olarak birleşir (öneri)

## Build order
1. **FAZ 1: Çekirdek veri mimarisi ve genetik motoru.** En riskli ve en eğlenceli kısım: bitkiler gerçekten çeşitli ve güzel görünüyor mu, çaprazlama keşfetmek heyecan veriyor mu?
2. **FAZ 2: Hidroponik ızgara ve büyüme döngüsü** (saksı, TimeManager, evreler, swipe hasat)
3. **FAZ 3: Ekonomi, dinamik borsa ve siparişler**
4. **FAZ 4: Otomasyon ve dikey kat inşası**
5. **FAZ 5: Mobil arayüz, Seed-Dex ve kayıt sistemi**

---
**Who it's for / what they feel:** Kısa oturumlarda tatmin edici hasat ve "yeni bir şey keşfettim" hissi arayan mobil idle/tycoon oyuncuları.

**Art & audio direction:** Neon-cyber hidroponik: koyu gökdelen arka planı, parlayan bitkiler, vektör (SVG) parçalardan prosedürel birleşim; ASMR hasat sesleri ve parçacıkları (ses tasarımı FAZ 2'de).

**Reference game:** [Sahibi doldurmalı. Genetik çeşitlilik hissinin kaynağı olarak sahibin aklında bir oyun varsa buraya yazılır.]
