class_name FarmTiles
extends RefCounted
## Çiftlik karo atlası: `assets/art/farm/farm_tiles.svg` 6 karoluk bir şerittir; burada TileSet'e çevrilir.
## Karo numaraları atlastaki sıradır (tools/art/make_farm_tiles.py ile aynı).
##
## Uygular: design/game-brief.md, FAZ 2 (hidroponik ızgara; Godot 4.3+ `TileMapLayer`).
##
## [codeblock]
## var layer: TileMapLayer = TileMapLayer.new()
## layer.tile_set = FarmTiles.make_tile_set()
## layer.set_cell(Vector2i(0, 1), 0, FarmTiles.atlas_coords(FarmTiles.POT_WET))
## [/codeblock]

## Karo kenar uzunluğu (piksel).
const TILE_SIZE: int = 180
const TILE_COUNT: int = 6
const TEXTURE: Texture2D = preload("res://assets/art/farm/farm_tiles.svg")

## Atlastaki karo numaraları.
const FLOOR: int = 0
const LAMP: int = 1
const POT_DRY: int = 2
const POT_WET: int = 3
const POT_DRY_PIPE: int = 4
const POT_WET_PIPE: int = 5


## Atlas dokusundan TileSet kurar (kaynak numarası 0).
static func make_tile_set() -> TileSet:
	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = TEXTURE
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for i: int in TILE_COUNT:
		source.create_tile(atlas_coords(i))
	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_source(source, 0)
	return tile_set


## Karo numarasının atlastaki koordinatı (tek satır).
static func atlas_coords(tile: int) -> Vector2i:
	return Vector2i(tile, 0)


## Saksı karosu: suya ve boruya göre doğru varyant.
static func pot_tile(wet: bool, piped: bool) -> int:
	if piped:
		return POT_WET_PIPE if wet else POT_DRY_PIPE
	return POT_WET if wet else POT_DRY
