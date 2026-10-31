extends Node
## Oyun genelindeki olay merkezi (EventBus), Autoload olarak "SignalBus" adıyla yüklenir.
## Sistemler birbirini doğrudan bilmez; olayı buraya yayınlar, ilgilenen buradan dinler (gevşek bağlılık).
##
## Bu sınıf DURUM TUTMAZ: yalnızca sinyal bildirir. (Şablon kuralı: oyun durumu için global singleton yok;
## durum tutan servisler `GameSession`'da kurulup enjekte edilir. Bkz. docs/architecture/floralab-architecture.md.)
## Servisler kendi sinyallerini yayınlar; `GameSession` onları buraya iletir. Arayüz ve ses yalnızca buradan dinler.
##
## Uygular: design/game-brief.md, "Modülerlik ve sinyaller" mimari kuralı (proje sahibi konsepti).
##
## [codeblock]
## # Yayınlama (örn. çaprazlamayı yapan sistem):
## SignalBus.seed_crossbred.emit(parent_a, parent_b, child)
## # Dinleme (örn. ses servisi):
## SignalBus.plant_harvested.connect(_on_plant_harvested)
## [/codeblock]
## Not: Autoload betiğine `class_name` verilmez (adı çakışır).

# --- Genetik (FAZ 1) ---

## İki tohum çaprazlandı ve bir çocuk üretildi.
signal seed_crossbred(parent_a: PlantGene, parent_b: PlantGene, child: PlantGene)

## Bir çaprazlamada YENİ bir mutasyon ortaya çıktı (arayüz "MUTASYON!" bildirimi gösterir).
signal mutation_discovered(child: PlantGene, mutation_id: StringName)

# --- Çiftlik (FAZ 2) ---

## Saksıya tohum dikildi.
signal plant_planted(floor_index: int, pot_index: int)

## Bitki olgunlaştı, hasada hazır.
signal plant_matured(floor_index: int, pot_index: int)

## Saksı elle sulandı.
signal pot_watered(floor_index: int, pot_index: int)

## Bitki hasat edildi (sonuç; `combo_step` içinde).
signal plant_harvested(result: HarvestResult)

## Bir kaydırma bitti: kaç bitki biçildi ve toplam değer.
signal harvest_swipe_finished(count: int, total_value: float)

## Arayüzde bir düğmeye dokunuldu (ses/titreşim bunu dinler).
signal ui_tapped

## Oyuncuya kısa bir mesaj göster (anahtar `tr()` ile çevrilir).
signal toast_requested(message_key: String, args: Array)

# --- Ekonomi (FAZ 3) ---

## Kredi bakiyesi değişti (yeni bakiye).
signal credits_changed(credits: int)

## İtibar değişti (yeni toplam).
signal reputation_changed(reputation: int)

## Envanter (tohum ya da ürün) değişti.
signal inventory_changed

## Ürün satıldı: yığın imzası, adet, kazanılan kredi.
signal item_sold(signature: StringName, quantity: int, credits: int)

## Borsa fiyatları değişti.
signal prices_changed

## Bir haber olayı başladı / bitti.
signal market_event_started(event_def: MarketEventDef)
signal market_event_ended(event_def: MarketEventDef)

## VIP sipariş açıldı / teslim edildi / süresi doldu.
signal order_added(order: Order)
signal order_completed(order: Order)
signal order_expired(order: Order)

# --- Otomasyon ve katlar (FAZ 4) ---

## Donanım satın alındı (tür, kat, hedef satır ya da -1, yeni seviye).
signal equipment_purchased(kind: EquipmentDef.Kind, floor_index: int, target: int, level: int)

## Yeni kat açıldı.
signal floor_unlocked(floor_index: int)

# --- Seed-Dex, kayıt, zaman (FAZ 5) ---

## Seed-Dex'e yeni tür/varyant eklendi (ödül kredi olarak verilir).
signal dex_discovery(morph_id: StringName, new_species: bool, bonus: int)

## Oyun kaydedildi.
signal game_saved

## Çevrimdışı ilerleme hesaplandı; özet gösterilebilir.
signal offline_report_ready(report: OfflineReport)

## Oyun yeni başladı ya da kayıttan yüklendi: arayüz her şeyi yeniden çizmeli.
signal game_reloaded

## Yeni oyun günü başladı.
signal day_changed(day: int)

## Oyun hızı değişti.
signal speed_changed(speed: float)

# --- Hedefler ve rehber (cila turu) ---

## Bir hedef tamamlandı (kimlik, ödül kredisi).
signal goal_completed(goal_id: StringName, reward: int)

## Hedef ilerlemesi ya da etkin hedef değişti (HUD ve çiftlik kartı yenilenir).
signal goals_changed
