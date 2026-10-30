class_name AutomationConfig
extends Resource
## Otomasyon sayıları: dron hızı, hasat süresi, bekleme ve (çevrimdışı hesap için) dron döngü süresi.
## `assets/data/automation/default_automation_config.tres`'ten gelir; kodda sabit yazılmaz.
##
## Uygular: design/game-brief.md, FAZ 4 "hasat dronları için basit durum makinesi".
##
## [codeblock]
## var config: AutomationConfig = load("res://assets/data/automation/default_automation_config.tres")
## agent.position = agent.position.move_toward(target, config.drone_speed * delta)
## [/codeblock]

## Dron hızı (saksı hücresi / saniye).
@export_range(0.5, 12.0, 0.1) var drone_speed: float = 2.6
## Dronun bitkiyi biçme süresi (saniye).
@export_range(0.1, 5.0, 0.05) var drone_harvest_seconds: float = 0.7
## Hedef bulamayan ya da işini bitiren dronun yeniden bakmadan önce beklediği süre.
@export_range(0.1, 10.0, 0.1) var drone_idle_seconds: float = 0.6
## Dron üssünün (şarj istasyonu) ızgara hücresi biriminde konumu: sütun, satır. Negatif = ızgaranın dışı.
@export var dock_position: Vector2 = Vector2(-0.5, 0.2)
## Çevrimdışı hesapta bir dronun bir bitkiyi biçip sıradakine hazırlanma süresi tahmini (saniye).
@export_range(0.5, 60.0, 0.5) var offline_drone_cycle_seconds: float = 4.0
