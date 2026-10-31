class_name EconomyConfig
extends Resource
## Ekonominin tek sayı kaynağı: başlangıç parası, çaprazlama maliyeti ve keşif ödülü, borsa dalgalanması, arz etkisi,
## haber olayı sıklığı, VIP sipariş ayarları. Kodda ekonomi sayısı sabit yazılmaz; hepsi
## `assets/data/economy/default_economy_config.tres`'ten gelir.
##
## Uygular: design/game-brief.md, "Core loop" ve FAZ 3 (dinamik borsa, haber olayları, envanter, VIP sözleşmeler).
## Formüller: docs/architecture/floralab-architecture.md, "Ekonomi kuralları".
##
## [codeblock]
## var config: EconomyConfig = load("res://assets/data/economy/default_economy_config.tres")
## wallet.credits = config.starting_credits
## [/codeblock]

@export_group("Başlangıç ve laboratuvar")
## Yeni oyunda başlangıç parası (kredi).
@export_range(0, 100000) var starting_credits: int = 120
## Bir çaprazlamanın maliyeti (kredi).
@export_range(0, 10000) var cross_cost: int = 40
## Bir çaprazlamada üretilen çocuk tohum sayısı.
@export_range(1, 6) var offspring_per_cross: int = 2
## Seed-Dex'e yepyeni bir TÜR (gövde+yaprak+meyve birleşimi) eklemenin ödülü.
@export_range(0, 10000) var discovery_bonus_species: int = 60
## Bilinen bir türün yeni bir VARYANTI (ton dilimi/mutasyon kümesi) için ödül.
@export_range(0, 10000) var discovery_bonus_variant: int = 12

@export_group("Borsa")
## Fiyat eğilimi bu aralıkla (oyun saniyesi) güncellenir.
@export_range(1.0, 300.0, 1.0) var market_update_seconds: float = 15.0
## Her güncellemede eğilime eklenen rastgele sapmanın standart sapması.
@export_range(0.0, 0.5, 0.005) var price_volatility: float = 0.05
## Her güncellemede eğilimin 1.0'a doğru çekilme oranı (ortalamaya dönüş).
@export_range(0.0, 1.0, 0.01) var price_reversion: float = 0.12
## Eğilimin en düşük ve en yüksek değeri.
@export_range(0.1, 1.0, 0.05) var price_min: float = 0.5
@export_range(1.0, 5.0, 0.05) var price_max: float = 2.5
## Satılan her birim, o meyvenin arz çarpanını bu kadar düşürür (fiyat düşer).
@export_range(0.0, 0.2, 0.005) var supply_impact_per_unit: float = 0.02
## Arz çarpanının saniyede toparlanma hızı (1.0'a doğru).
@export_range(0.0, 0.1, 0.0005) var supply_recovery_per_second: float = 0.002
## Arz çarpanının inebileceği en düşük değer (sürekli satışta fiyat bunun altına inmez).
@export_range(0.1, 1.0, 0.05) var supply_floor: float = 0.4
## Pazar grafiği için meyve başına tutulan fiyat endeksi örneği sayısı (her eğilim güncellemesinde bir örnek).
@export_range(2, 120) var price_history_size: int = 24

@export_group("Haber olayları")
## İki haber olayı arasındaki en kısa ve en uzun süre (oyun saniyesi).
@export_range(10.0, 1800.0, 1.0) var event_interval_min_seconds: float = 70.0
@export_range(10.0, 1800.0, 1.0) var event_interval_max_seconds: float = 140.0
## Aynı anda sürebilecek en çok olay.
@export_range(1, 5) var max_active_events: int = 2
## Haber geçmişinde tutulan en çok başlık.
@export_range(1, 30) var news_history_size: int = 8

@export_group("VIP siparişler")
## Aynı anda açık sipariş sayısı.
@export_range(1, 8) var order_slots: int = 3
## Yeni sipariş denemesi aralığı (oyun saniyesi).
@export_range(5.0, 600.0, 1.0) var order_interval_seconds: float = 40.0
## Bir siparişin süresi (oyun saniyesi).
@export_range(30.0, 3600.0, 1.0) var order_duration_seconds: float = 420.0
## Siparişin ödülü: referans değer x adet x bu çarpan (piyasa fiyatının üstünde prim).
@export_range(1.0, 5.0, 0.05) var order_reward_multiplier: float = 1.6
## Teslim edilen her sipariş itibar kazandırır.
@export_range(0, 20) var reputation_per_order: int = 1
## Her itibar seviyesi için gereken itibar puanı.
@export_range(1, 50) var reputation_per_level: int = 3
## Her itibar seviyesinin sipariş ödülüne eklediği oran.
@export_range(0.0, 0.5, 0.01) var reputation_reward_bonus: float = 0.05
