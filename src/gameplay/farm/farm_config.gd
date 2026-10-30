class_name FarmConfig
extends Resource
## Çiftlik kurallarının tek sayı kaynağı: büyüme, su, UV/sulama etkisi, hasat verimi, aşırı olgunluk, kombo ve oyun günü.
## Oyun kodunda bu değerlerin hiçbiri sabit yazılmaz; hepsi `assets/data/farm/default_farm_config.tres`'ten gelir.
##
## Uygular: design/game-brief.md, "Core loop" (Tohum -> Filiz -> Olgun, su ve UV ışık, kaydırarak hasat).
## Formüller: docs/architecture/floralab-architecture.md, "Çiftlik kuralları".
##
## [codeblock]
## var config: FarmConfig = load("res://assets/data/farm/default_farm_config.tres")
## var rate: float = GrowthModel.growth_rate(phenotype, pot.water, uv_level, config)
## [/codeblock]

@export_group("Büyüme")
## Büyüme hızı 1.0, su yeterli, ışık 1.0 iken bir bitkinin tohumdan olgunluğa (büyüme 0 -> 1) gelme süresi (oyun saniyesi).
@export_range(5.0, 600.0, 1.0) var base_grow_seconds: float = 40.0
## Bu büyüme değerinden itibaren bitki "Filiz" evresindedir (altı "Tohum").
@export_range(0.01, 0.99, 0.01) var sprout_threshold: float = 0.25

@export_group("Su")
## Su tüketimi çarpanı 1.0 olan bir bitkinin saniyede kaybettiği su (0..1 ölçeğinde).
@export_range(0.0, 0.2, 0.001) var water_drain_per_second: float = 0.012
## Saksıdaki su bunun altına inince büyüme DURUR.
@export_range(0.0, 0.9, 0.01) var water_growth_threshold: float = 0.15
## Eşiğin üstünde büyümenin tam hıza çıktığı su aralığı (yumuşak geçiş: aniden kesilmez).
@export_range(0.01, 0.9, 0.01) var water_growth_ramp: float = 0.10
## Yeni açılan saksıdaki başlangıç suyu.
@export_range(0.0, 1.0, 0.01) var water_start: float = 1.0

@export_group("Otomasyon etkisi")
## Satırdaki her UV lambası seviyesinin büyüme hızına eklediği oran (1 seviye = +%50).
@export_range(0.0, 2.0, 0.05) var uv_growth_bonus_per_level: float = 0.5
## Otomatik sulaması olan satırdaki saksıların saniyedeki su dolumu.
@export_range(0.0, 1.0, 0.01) var irrigation_refill_per_second: float = 0.25

@export_group("Hasat")
## Bir bitkiden tek hasatta çıkan meyve adedi.
@export_range(1, 20) var base_yield_units: int = 3
## Hasatta envantere dönen tohum adedi (aynı genotip; ekimi sürdürülebilir kılar).
@export_range(0, 5) var seeds_returned_per_harvest: int = 1
## Olgunlaştıktan sonra bu kadar saniye değer kaybı olmaz.
@export_range(0.0, 3600.0, 1.0) var overgrowth_grace_seconds: float = 60.0
## Ek süre geçince dakika başına kaybedilen değer oranı.
@export_range(0.0, 1.0, 0.01) var overgrowth_loss_per_minute: float = 0.10
## Aşırı olgunlukta değer çarpanının inebileceği en düşük değer.
@export_range(0.0, 1.0, 0.01) var overgrowth_min_factor: float = 0.5

@export_group("Kombo")
## Tek bir kaydırmada art arda biçilen her ek bitkinin değere eklediği oran.
@export_range(0.0, 0.5, 0.01) var combo_bonus_per_step: float = 0.05
## Kombo ile eklenebilecek en çok değer oranı.
@export_range(0.0, 2.0, 0.01) var combo_bonus_cap: float = 0.5

@export_group("Zaman")
## Bir oyun "günü"nün oyun saniyesi cinsinden uzunluğu (gösterge ve sipariş süreleri için).
@export_range(30.0, 3600.0, 1.0) var day_length_seconds: float = 300.0
## Oyuncunun seçebileceği en yüksek oyun hızı çarpanı.
@export_range(1.0, 10.0, 0.5) var max_speed: float = 5.0

@export_group("Çevrimdışı")
## Çevrimdışı kazanç için hesaplanan en uzun süre (saat); daha uzun ayrılık bu sınıra kırpılır.
@export_range(0.5, 72.0, 0.5) var offline_max_hours: float = 8.0
## Bundan kısa ayrılıklar için çevrimdışı rapor gösterilmez (saniye).
@export_range(0.0, 3600.0, 1.0) var offline_min_report_seconds: float = 60.0
## Çevrimdışı simülasyonun adım uzunluğu (saniye): büyük = hızlı ama kaba, küçük = hassas ama yavaş.
@export_range(1.0, 60.0, 1.0) var offline_step_seconds: float = 5.0
