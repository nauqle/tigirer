class_name FloorDef
extends Resource
## Gökdelen katının tanımı (veri): ızgara boyutu ve açma maliyeti. Yeni kat eklemek bir .tres eklemektir.
##
## Uygular: design/game-brief.md, MVP "yeni kat açma" (FAZ 4); ızgara boyutu FAZ 2'de kullanılır.
##
## [codeblock]
## var floor_def: FloorDef = catalog.floors[1]
## print(floor_def.display_name, " ", floor_def.cols, "x", floor_def.rows, " maliyet=", floor_def.unlock_cost)
## [/codeblock]

## Katın sırası (0 = en alt kat, oyunun başladığı yer).
@export var index: int = 0
## Oyuncuya gösterilecek ad.
@export var display_name: String = ""
## Izgaradaki sütun ve satır sayısı (saksı sayısı = sütun x satır).
@export_range(1, 6) var cols: int = 3
@export_range(1, 5) var rows: int = 2
## Katı açmanın maliyeti (kredi). 0 = baştan açık.
@export_range(0, 1000000) var unlock_cost: int = 0
