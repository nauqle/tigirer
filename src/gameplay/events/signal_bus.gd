extends Node
## Oyun genelindeki olay merkezi (EventBus), Autoload olarak "SignalBus" adıyla yüklenir.
## Sistemler birbirini doğrudan bilmez; olayı buraya yayınlar, ilgilenen buradan dinler (gevşek bağlılık).
##
## Bu sınıf DURUM TUTMAZ: yalnızca sinyal bildirir. (Şablon kuralı: oyun durumu için global singleton yok;
## durum tutan servisler sahnede enjekte edilir. Bkz. docs/architecture/floralab-architecture.md.)
##
## Uygular: design/game-brief.md, "Modülerlik ve sinyaller" mimari kuralı (proje sahibi konsepti).
##
## [codeblock]
## # Yayınlama (örn. çaprazlamayı yapan sistem):
## SignalBus.seed_crossbred.emit(parent_a, parent_b, child)
## # Dinleme (örn. Seed-Dex, FAZ 5):
## SignalBus.mutation_discovered.connect(_on_mutation_discovered)
## [/codeblock]
## Not: Autoload betiğine `class_name` verilmez (adı çakışır).

## İki tohum çaprazlandı ve bir çocuk üretildi.
signal seed_crossbred(parent_a: PlantGene, parent_b: PlantGene, child: PlantGene)

## Bir çaprazlamada YENİ bir mutasyon ortaya çıktı (arayüz "MUTASYON!" bildirimi gösterir).
signal mutation_discovered(child: PlantGene, mutation_id: StringName)
