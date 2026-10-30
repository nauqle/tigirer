class_name OfflineReport
extends RefCounted
## Çevrimdışı kalınan sürede olanların özeti: oyuncu geri döndüğünde "Hoş geldin" penceresinde gösterilir.
##
## Uygular: design/game-brief.md, FAZ 5 "çevrimdışı kazanç [Idle/Overgrowth] hesaplaması".

## Oyuncunun uzakta kaldığı gerçek süre (saniye).
var seconds_away: float = 0.0
## Hesaba katılan süre (en çok `FarmConfig.offline_max_hours`).
var seconds_simulated: float = 0.0
## Ayrılık sınıra kırpıldı mı?
var capped: bool = false
## Dronların yaptığı hasat sayısı, çıkan meyve adedi ve toplam değer (kredi karşılığı).
var harvests: int = 0
var harvested_units: int = 0
var harvested_value: float = 0.0
## Dönüşte hasat bekleyen (olgun) bitki sayısı.
var waiting_mature: int = 0
## Bunlardan, değer kaybı başlamış (aşırı olgun) olanlar ve toplam kayıp (kredi karşılığı).
var overgrown: int = 0
var value_lost: float = 0.0


## Gösterilecek bir şey var mı? (hiç hasat, bekleyen bitki ya da kayıp yoksa pencere açılmaz)
func has_news() -> bool:
	return harvests > 0 or waiting_mature > 0 or overgrown > 0
