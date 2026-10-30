# Son Fener — Oyun Tasarım Belgesi

> **Tür:** tek parmakla oynanan, dikey ekranlı savunma / hayatta kalma  
> **Platform:** Android (APK) · Android 7.0 ve üstü  
> **Dil:** Türkçe  
> **Süre:** hikâye modu tekrar denemelerle birlikte yaklaşık 15–25 dakika, sonrasında sınırsız “Sonsuz Gece”  
> **Tek cümlelik fikir:** *Işık gölgeyi yenmez; onu eve götürür.*

Gölge, gece ve geliştirme tabloları oyunun kaynak kodundan otomatik üretilmiştir; kodla belge arasında fark olamaz. Düz yazıdaki sayılar aynı değerlere dayanır.

---

## 1. Fikir

Sen, **Kandil Burnu**'nun fener bekçisisin. Her gece denizden sis yükselir; sisin içinden gölgeler çıkıp feneri söndürmek için kıyıya sürünür. Elindeki tek silah fenerin ışığıdır.

Parmağını ekranda gezdirerek ışığı yönlendirirsin. Ama ışık sınırsız değildir: yanarken enerji harcar, aşırı ısınırsa kapanır. Oyunun asıl becerisi **ritim**dir: doğru gölgeye, doğru anda, ışığı ne kadar yakacağını bilerek vur. Şafağa dayanabilirsen gece kazanılır.

Gölgeler öldüğünde yok olmaz, **kıvılcıma** dönüşür. Kıvılcım, unutulmuş bir anıdır; onu fenere vererek feneri güçlendirirsin. Mekanik ile hikâye aynı fikri anlatır: unutulanı hatırlamak, karanlığı yenmenin yoludur.

## 2. Oyun döngüsü

```
Prolog ─► Gece (50–75 sn) ─► Kıvılcım topla ─► Atölyede fenerini geliştir ─► Daha zor gece ─► … ─► 5. gece: Sis Ana ─► Epilog ─► Sonsuz Gece
```

1. **Gece:** Gölgeler kenarlardan gelir. Işığınla onları dağıtır, kıvılcımlarını toplarsın.
2. **Şafak:** Kazanırsan kıvılcımların ve bir şafak bonusu cebine girer. Kaybedersen toplananın yarısı kalır.
3. **Atölye:** Kıvılcımla altı özellikten birini geliştirirsin (bkz. 4.7).
4. **Sonraki gece:** Yeni bir gölge türü, daha sık dalgalar. 3. ve 5. gecede boss var.

## 3. Kontroller

| Eylem | Nasıl |
|---|---|
| Işığı yönlendir ve yak | Ekrana dokun, parmağını sürükle. Işın parmağının fenere göre yönüne döner; parmağını kaldırınca söner. |
| Parlama | Sağ alttaki **PARLAMA** düğmesine dokun. İkinci bir parmakla da basılabilir; ışın kesilmez. |
| Duraklat | Sağ üstteki **II** düğmesi ya da Android geri tuşu. Uygulamadan çıkınca oyun kendiliğinden durur. |

## 4. Kurallar

### 4.1 Fener ve ışın
- Fener ekranın tam ortasındadır. Gölgeler dört yönden de gelir.
- Işın, fenerden **620 birim** menzilli bir dilimdir (ekran genişliği 1000 birimdir). Başlangıçta **26°** genişliğindedir.
- Dilimin içine giren her gölge saniyede **Işık Gücü** kadar hasar alır (başlangıçta 40/sn). Zırhlı gölgelerde bu hasarın yalnızca %45'i, Sis Ana'da %85'i işler.
- Işıktaki gölge **%55 hızla** yürür; yani ışık yavaşlatır, sadece yakmaz.
- Işın parmağı çok hızlı izler (saniyede 10 radyan); amaç “nişan almayı” zorlaştırmak değil, **enerjiyi yönetmektir**.

### 4.2 Enerji ve aşırı ısınma
- Enerji deposu başlangıçta **100**'dür. Işın açıkken saniyede **24** harcanır; kapalıyken **Soğutma** değeri kadar (başlangıçta 26/sn) dolar.
- Enerji sıfırlanınca fener **ISINIR**: ışın kapanır ve enerji deposunun **%35**'ine dolana kadar açılamaz (parmağın basılı olsa bile).
- Başlangıç değerleriyle ışığı yaklaşık 4 saniye yakıp yaklaşık 4 saniye dinlendirmek gerekir. Oyun bu ritim üzerine kuruludur.

### 4.3 Fener yağı (can)
- Fener yağı can yerine geçer; başlangıçta **100**'dür ve her gece **tam dolu** başlar (onarım ücretsizdir).
- Fenere ulaşan gölge **yok olur** ve yağı türüne göre azaltır (bkz. 4.5). Fenere çarparak ölen gölge kıvılcım **bırakmaz**.
- Boss'lar fenere çarpmaz; yaklaşıp durur ve saniyede sabit miktarda yağ emerler.
- Yağ sıfıra inerse fener söner ve gece kaybedilir.

### 4.4 Parlama
- Feneri çevreleyen **440 birimlik** alandaki **tüm** gölgelere **Parlama gücü** kadar hasar verir (başlangıçta 90). **Zırhı yok sayar.**
- Gölgeleri **150 birim** geri iter (boss'ları yalnızca 30).
- Bekleme süresi başlangıçta **14 sn**'dir. Enerji harcamaz, ışından bağımsızdır.
- Parlama kalabalığı dağıtmak, zırhlıyı delmek ve boss'a darbe vurmak içindir; ne zaman kullanacağın bir karardır.

### 4.5 Gölgeler

| Gölge | Can | Hız (birim/sn) | Fenere çarpınca hasar | Kıvılcım | Işık çarpanı | Not |
|---|---:|---:|---:|---:|---:|---|
| Sürüngen | 40 | 55 | 8 | 1 | 1.0 | Temel gölge; düz yürür. |
| Koşucu | 22 | 125 | 6 | 1 | 1.0 | Hızlıdır, zikzak çizer. |
| Zırhlı | 180 | 36 | 20 | 4 | 45% | Işığa dayanıklı; Parlama zırhı deler. |
| Bölünen | 70 | 58 | 10 | 2 | 1.0 | Ölünce 2 Parçacık'a bölünür. |
| Parçacık | 18 | 95 | 4 | 1 | 1.0 | Bölünenin parçası; küçük ve çevik. |
| Kaptan Gölge | 600 | 30 | — | 40 | 1.0 | Boss. Fenerin 170 birim yakınında durur, saniyede 3.5 yağ emer, 7 sn'de bir 2 Koşucu çağırır. |
| Sis Ana | 1700 | 22 | — | 100 | 85% | Son boss. 190 birimde durur, saniyede 4.5 yağ emer; 7 sn'de bir (canı yarıdan azsa 5 sn) 2 Sürüngen (+1 Koşucu) çağırır. |

“Işık çarpanı”, ışının o gölgeye ne kadar işlediğidir. Parlama hasarı çarpandan etkilenmez.

### 4.6 Gece nasıl kazanılır / kaybedilir
- **Normal gece:** Süre dolunca şafak sökmesiyle kalan gölgeler erir; gece kazanılır.
- **Boss gecesi:** Boss belirli bir saniyede gelir. Gece, **boss yenilince** biter. Normal gölgeler süre dolana kadar gelmeye devam eder; süre bitse de boss yaşıyorsa gece uzar.
- **Kayıp:** Yağ sıfıra inerse gece kaybedilir. Hemen “Tekrar Dene” diyebilirsin; hikâye sahnesi yeniden oynatılmaz.

### 4.7 Kıvılcım ve atölye
- Her gölge ölünce türüne göre kıvılcım bırakır (bkz. tablo); kıvılcımlar kendiliğinden fenere akar.
- **Gece sonu ödülü:**
  - Kazanırsan: toplanan kıvılcım **+ şafak bonusu** (yalnızca o geceyi *ilk kez* kazanıyorsan): 1. gece 15, 2. gece 30, 3. gece 45, 4. gece 60, 5. gece 75.
  - Kaybedersen: toplanan kıvılcımın **yarısı** (aşağı yuvarlanır). Böylece her deneme ilerleme sağlar.
  - Önceki geceleri tekrar oynayabilirsin; kıvılcımlar tam gelir ama bonus verilmez.
- **Atölye:** Altı özellik, her biri 5 seviye.

| Geliştirme | Seviye 0 | 1 | 2 | 3 | 4 | 5 |
|---|---:|---:|---:|---:|---:|---:|
| Işık Gücü | 40 | 49 | 58 | 67 | 76 | 85 |
| Işın Genişliği | 26° | 32° | 38° | 44° | 50° | 56° |
| Enerji Deposu | 100 | 125 | 150 | 175 | 200 | 225 |
| Soğutma | 26 | 31 | 36 | 41 | 46 | 51 |
| Fener Yağı | 100 | 120 | 140 | 160 | 180 | 200 |
| Parlama | 90 (bekleme 14 sn) | 125 (bekleme 12.5 sn) | 160 (bekleme 11 sn) | 195 (bekleme 9.5 sn) | 230 (bekleme 8 sn) | 265 (bekleme 6.5 sn) |

Maliyet (kıvılcım): 1. seviye 10, 2. seviye 20, 3. seviye 34, 4. seviye 52, 5. seviye 76 — bir geliştirmeyi azami seviyeye çıkarmak toplam 192 kıvılcım.

### 4.8 Boss geceleri
- **3. gece — Kaptan Gölge:** 35. saniyede gelir. Fenerin 170 birim yakınında durup yağ emer; her 7 saniyede 2 Koşucu çağırır. Ana dersi: **Parlama ve ışığı boss'a odaklamak.**
- **5. gece — Sis Ana:** 22. saniyede gelir. 190 birimde durur, yağ emer; sürekli Sürüngen çağırır, canı yarıdan azsa daha sık ve Koşucu da ekleyerek. Ana dersi: **bütün öğrendiklerini aynı anda kullanmak.**
- Üstteki çubuk, boss yenildikçe dolar; boss gelene kadar altında “Kaptan Gölge geliyor · N sn” gibi bir sayaç görünür. Boss'un kendi can çubuğu da başının üstündedir.

### 4.9 Sonsuz Gece
- Final bittikten sonra menüde açılır. Süre sınırı yoktur; amaç **mümkün olduğunca uzun dayanmaktır**. En iyi süre kaydedilir.
- 20. saniyeden sonra Koşucu, 40.'tan sonra Bölünen, 60.'tan sonra Zırhlı karışır; 90. saniyeden sonra bazen çift gölge gelir. Doğma aralığı zamanla kısalır (en az 0,45 sn) ve gölgelerin canı zamanla artar.
- 60. saniyede ilk boss gelir, sonra her 75 saniyede bir yenisi (Kaptan Gölge ile Sis Ana dönüşümlü, her seferinde %50 daha dayanıklı).
- Kıvılcımların **tamamı** kaydedilir; kaybetsen bile. Bu mod, atölyeyi tamamlamak için tarla görevi görür.

### 4.10 Kayıt
İlerleme (açılan gece, kıvılcım, geliştirme seviyeleri, ses ayarı, Sonsuz Gece rekoru) cihazda otomatik saklanır. Menüdeki “İlerlemeyi sıfırla” iki dokunuşla onay ister.

## 5. Geceler

| Gece | Süre | Gölgeler (doğma aralığı, başlangıç→bitiş sn) | Boss |
|---|---:|---|---|
| 1. Gece · İlk Işık | 50 sn | Sürüngen: 2.8→1.8 sn aralıkla (0–50. sn) | — |
| 2. Gece · Fısıltılar | 60 sn | Sürüngen: 2.3→1.5 sn aralıkla (0–60. sn)<br>Koşucu: 4.5→2.6 sn aralıkla (8–60. sn) | — |
| 3. Gece · Sis Perdesi | 65 sn*  | Sürüngen: 2.4→1.7 sn aralıkla (0–65. sn)<br>Koşucu: 4.8→3 sn aralıkla (5–65. sn)<br>Zırhlı: 9→6.5 sn aralıkla (15–65. sn) | Kaptan Gölge (35. sn'de gelir) |
| 4. Gece · Bölünenler | 70 sn | Sürüngen: 2→1.3 sn aralıkla (0–70. sn)<br>Koşucu: 3.8→2.3 sn aralıkla (4–70. sn)<br>Zırhlı: 7.5→5 sn aralıkla (12–70. sn)<br>Bölünen: 5→3.2 sn aralıkla (6–70. sn) | — |
| 5. Gece · Sis Ana | 75 sn*  | Sürüngen: 2.1→1.5 sn aralıkla (0–75. sn)<br>Koşucu: 4→2.8 sn aralıkla (4–75. sn)<br>Zırhlı: 8→5.5 sn aralıkla (10–75. sn)<br>Bölünen: 5.5→3.8 sn aralıkla (6–75. sn) | Sis Ana (22. sn'de gelir) |

\* Boss gecelerinde süre yalnızca normal gölgelerin geliş süresidir; gece boss yenilince biter.

“Doğma aralığı” ilk değerden ikinci değere doğrusal azalır, her seferinde ±%20 rastgelelik eklenir.

## 6. Denge ve ekonomi

**Hedef eğri:** 1. ve 2. gece öğreticidir (geliştirmesiz de geçilir). 3. geceden itibaren atölyeye uğramak zorunludur. 5. gece, “makul” bir geliştirme setiyle bile zordur; asıl hedef, kaybedince alınan yarım kıvılcım ve Sonsuz Gece ile beslenerek geçmektir.

**Yöntem:** Oyunun mantığı Android'den bağımsız yazıldığı için bilgisayarda binlerce gece simüle edilebilir. Simülasyondaki oyuncu (bot) en yakın tehlikeyi hedefler, 0,35 sn'de bir hedef değiştirir ve kalabalık olunca Parlama atar. Aşağıdaki oranlar **her hücre için 40 deneme**dir.

| Gece | Geliştirmesiz | Az (70 kıv.)¹ | Orta (90 kıv.)² | İyi (248 kıv.)³ | Güçlü (384 kıv.)⁴ | Tam (1152 kıv.)⁵ |
|---|---|---|---|---|---|---|
| 1. gece | %100 | %100 | %100 | %100 | %100 | %100 |
| 2. gece | %100 | %100 | %100 | %100 | %100 | %100 |
| 3. gece | %0 | %50 | %85 | %100 | %100 | %100 |
| 4. gece | %0 | %60 | %95 | %100 | %100 | %100 |
| 5. gece | %0 | %0 | %0 | %70 | %100 | %100 |

¹ Işık Gücü 2, Işın Genişliği 2, Enerji Deposu 1 · ² Az + Soğutma 1, Fener Yağı 1 · ³ Işık Gücü 3, Işın Genişliği 3, diğerleri 2 · ⁴ Hepsi 3 · ⁵ Hepsi 5.

Sonsuz Gece'de aynı bot'un ortalama dayanma süresi (20 deneme):

| | Geliştirmesiz | Az | Orta | İyi | Güçlü | Tam |
|---|---|---|---|---|---|---|
| Süre | 95 sn | 108 sn | 121 sn | 170 sn | 197 sn | 390 sn |

**Kıvılcım akışı (ilk denemede kazanan oyuncu için yaklaşık):** 1. gece ≈ 19 + 15 bonus, 2. gece ≈ 39 + 30, 3. gece ≈ 107 + 45, 4. gece ≈ 136 + 60. Toplam 5. geceye girerken ≈ 450 kıvılcım; bu da “Güçlü” seti (384) almaya yeter.

> **Sınırlar:** Bot bir insan değildir. Kusursuz nişan alır ama parmağıyla hata yapmaz; gerçek oyuncunun sonuçları bunlardan farklı olacaktır. Bu tablolar zorluk eğrisinin *şeklini* doğrular, kesin başarı oranını vaat etmez. Oyun gerçek bir cihazda bir insanla henüz test edilmemiştir.

## 7. Senaryo

### 7.1 Dünya ve ton
**Kandil Burnu**, bir körfezin ucundaki küçük, hayali bir balıkçı kasabasıdır. Fener burada üç yüz yıldır yanar. Ton: **sakin, hüzünlü ama umutlu**. Korku yok, kayıp ve hatırlama var.

### 7.2 Karakterler
| Karakter | Rol |
|---|---|
| **Sen** | Yeni fener bekçisi. Adı ve cinsiyeti belirtilmez; metin “sen” diye hitap eder, herkes kendini koyabilsin diye. |
| **Usta Hızır** | Eski bekçi. Bir sabah kaybolur; geriye anahtarı ve yarım defterini bırakır. Defterin satırları oyuncuya yol gösterir. Finalde geri döner. |
| **Gölgeler** | Körfezde kaybolmuş denizcilerin ve unutulmuş adların gölgeleri. Kötü değiller; unutulmanın acısıdır. Kendi dilleri yoktur, fısıldarlar. |
| **Kaptan Gölge** | Eski bir geminin silueti, gölgelerin sözcüsü. Yenildiğinde konuşur ve “hatırla” diye yalvarır. |
| **Sis Ana** | Unutulmuşluğun kendisi: yüzyıllardır unutulan herkesin gölgesi. Yenilmez; yalnızca *hatırlanarak* dağılır. |

### 7.3 Ana fikir ve mekaniğin hikâyeyle bağı
- **Gölge = unutulmuş biri.** Işık onları yok etmez; kıvılcıma, yani *anıya* çevirir.
- **Kıvılcım = anı.** Atölyede kıvılcım harcamak, anıları fenere geri vermektir; fener bu yüzden güçlenir.
- **Fener yağı = kasabanın hatırlama gücü.** Gölgeler fenere ulaşırsa kasaba biraz daha unutur.
- **Sis Ana'yı yenmek = herkesi hatırlamak.** Bu yüzden son gecenin sonunda kıvılcımların tamamı fenerin camına bırakılır.

### 7.4 Akış
Prolog → 1. gece (giriş, oyun, çıkış) → … → 5. gece (giriş, boss, **epilog**). Çıkış sahneleri yalnızca geceyi *ilk kez* kazanınca gösterilir. Giriş sahneleri, henüz geçilmemiş bir geceyi atölyeden başlatırken gösterilir; “Tekrar Dene” ve önceki geceleri yeniden oynama sahneyi atlar.

### 7.5 Metinler

#### Prolog

**Sayfa 1**

> Kandil Burnu'nun feneri üç yüz yıldır hiç sönmedi.
>
> Gemiler onu uzaktan görür, denizciler ona bakarak eve yolunu bulurdu.

**Sayfa 2**

> Sonra bir sabah Usta Hızır ortadan kayboldu.
>
> Geriye yalnızca fenerin anahtarı ve yarım kalmış bir defter bıraktı.

**Sayfa 3**

> Defterin son sayfasında şu yazıyordu:
>
> “Sis uyanırsa ışığı söndürme. Gölgeler karanlıktan değil, unutulmaktan gelir.”
>
> Bu gece sis kasabaya iniyor. Fener artık senin.

#### 1. Gece · İlk Işık

*Gece başı:*

**Sayfa 1**

> Güneş battı. Denizden ince bir sis yükseliyor.
>
> Merdiveni çıkıp feneri yaktın. Gölgeler kıyıya doğru sürünüyor.
>
> Ekrana dokun ve parmağını kaydır: ışık parmağının gösterdiği yöne döner.

*Gece sonu (ilk kez kazanınca):*

**Sayfa 1**

> Sürüngenler ışıkta dağıldı ve geriye altın kıvılcımlar kaldı. Her biri küçük bir anı gibi parlıyor.
>
> Defterde yeni bir satır belirmiş:
> “Kıvılcımlar unutulmuş anılardır. Topla; fener daha parlak yansın.”
#### 2. Gece · Fısıltılar

*Gece başı:*

**Sayfa 1**

> Rüzgârda isimler fısıldanıyor: Selim… Nesrin… Cemal…
>
> Bu gece gölgeler daha hızlı. Işın enerji harcar; tükenirse ışık soğur ve bir süre yanmaz. Ritmini bul.

*Gece sonu (ilk kez kazanınca):*

**Sayfa 1**

> Fısıltılar kesildi. Defterin kenarında bir gemi listesi buldun; hepsi bu körfezde kaybolmuş.
>
> Adlar silik ama hâlâ okunuyor.
#### 3. Gece · Sis Perdesi

*Gece başı:*

**Sayfa 1**

> Sis kalınlaştı. Bazı gölgeler zırh gibi bir sisle sarılı; ışık onlara zor işliyor.
>
> Parlama düğmesi bu zırhı deler.
>
> Ufukta eski bir geminin silueti beliriyor: Kaptan Gölge.

*Gece sonu (ilk kez kazanınca):*

**Sayfa 1**

> Kaptan Gölge dağılırken son sözünü fısıldadı:
> “Bizi unuttular… Ama sen hâlâ buradasın.”
>
> Kaptanın pusulası kıvılcımlara karıştı. Onu fenerin yanına astın.
#### 4. Gece · Bölünenler

*Gece başı:*

**Sayfa 1**

> Bu gece gölgeler çoğalıyor. Bazıları ölünce iki küçük parçaya ayrılıyor.
>
> Kasabadan kimse kapısını açmıyor; yine de pencerelerde mum ışıkları görüyorsun.

*Gece sonu (ilk kez kazanınca):*

**Sayfa 1**

> Parçalar da dağıldı. Fenerin kapısına bir sepet ekmek ve bir not bırakılmış:
> “Bizi hatırlıyorsun, biz de seni.”
>
> Sis zayıflıyor. Ama kaynağı hâlâ denizin ortasında.
#### 5. Gece · Sis Ana

*Gece başı:*

**Sayfa 1**

> Son gece. Deniz çekiliyor, gökyüzü susuyor.
>
> Sis'in kalbi yaklaşıyor: Sis Ana. Yüzyıllardır unutulan herkesin gölgesi onda birikmiş.
>
> Onu yenmek yetmez; hatırlamak gerek.

*Gece sonu:* Doğrudan Epilog başlar.

#### Epilog

**Sayfa 1**

> Sis Ana dağılırken binlerce kıvılcıma ayrıldı. Her biri bir ad, bir yüz, bir ses…
>
> Hepsini fenerin camına bıraktın.

**Sayfa 2**

> Fener, kasabanın tarihinde ilk kez gündüz de yandı.
>
> Ufukta gemiler belirdi; yıllar önce kaybolanlar, dümenlerinde fener ışığıyla eve dönüyordu.

**Sayfa 3**

> Rıhtımda, gemilerden birinden inen yaşlı bir silüet el salladı: Usta Hızır.
>
> Defterin son sayfasına kendi satırını yazdın:
> “Işık gölgeyi yenmez; onu eve götürür.”

**Sayfa 4**

> SON FENER
>
> Tamamladın. Fener artık senin.
>
> İstersen “Sonsuz Gece” modunda ne kadar dayanabileceğini dene.

Oyunda tek bir son vardır. Epilogdan sonra menüde **Sonsuz Gece** açılır.

## 8. Görsel ve ses dili
- **Bakış:** Üstten, gece. Zemin koyu lacivert; fener ve ışın sıcak altın. Renk dili: *altın = umut/hatıra, koyu = unutulmuş*.
- **Gölgeler siyah silüettir; kenar rengi türünü söyler:** Sürüngen mavi (dikenli bacaklar), Koşucu pembe (kuyruklu), Zırhlı çelik mavisi (perçinli halka), Bölünen mor (çift küre), Kaptan Gölge turkuaz (diken tacı), Sis Ana mor (12 dokunaç, 5 göz). **Işıktaki gölgenin kenarı altına döner**; oyuncu neye vurduğunu görür.
- **Geri bildirim:** Öldürünce kıvılcımlar fenere akar; fenere darbede ekran sarsılır ve kenarlar kırmızıya çalar; Parlama genişleyen bir halka olarak görünür; fener çevresindeki halka enerjiyi gösterir; şafakta gökyüzü mordan turuncuya döner.
- **Ses:** Ses dosyası yoktur; kısa sesler çalışma anında üretilir (vuruş, dağılma, Parlama, darbe, boss, şafak, kayıp). Menüden kapatılabilir; titreşim de aynı ayara bağlıdır.

## 9. Teknik yapı
- **Dil / araç:** Java, Android SDK 34, minSdk 24, ek kütüphane yok (yalnızca Android platformu).
- **`core` paketi** (Android'e bağımlı değil): `World` (bir gecenin bütün mantığı), `ShadowType`, `Upgrades`, `Levels`, `SaveData`, `Story`. JVM'de test edilir.
- **Arayüz katmanı:** tek `View` üzerinde ekranlar (`MenuScreen`, `StoryScreen`, `ShopScreen`, `PlayScreen`, `HowToScreen`), çizim `Gfx`'te, ses `Sfx`'te.
- **Test:** birim testleri (oyun mantığı, kayıt, bot'la denge) ve Robolectric ile gerçek `Canvas` çizimi: her ekranın çökmeden çizildiği, menüden ilk geceye uzanan akışın çalıştığı ve ekran görüntüleri üretildiği testler.
