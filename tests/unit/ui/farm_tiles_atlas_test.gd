extends TestCase
## FarmTiles: SVG atlasından kurulan TileSet ve saksı karosu seçimi.


func test_the_tile_set_exposes_every_atlas_tile_at_the_tile_size() -> void:
	var tile_set: TileSet = FarmTiles.make_tile_set()

	assert_eq(tile_set.tile_size, Vector2i(FarmTiles.TILE_SIZE, FarmTiles.TILE_SIZE))
	assert_eq(tile_set.get_source_count(), 1)
	var source: TileSetAtlasSource = tile_set.get_source(tile_set.get_source_id(0)) as TileSetAtlasSource
	assert_eq(source.get_tiles_count(), FarmTiles.TILE_COUNT)
	for tile: int in FarmTiles.TILE_COUNT:
		assert_true(source.has_tile(FarmTiles.atlas_coords(tile)), "karo %d var" % tile)


func test_the_atlas_texture_is_as_wide_as_all_tiles_side_by_side() -> void:
	assert_eq(FarmTiles.TEXTURE.get_width(), FarmTiles.TILE_SIZE * FarmTiles.TILE_COUNT)
	assert_eq(FarmTiles.TEXTURE.get_height(), FarmTiles.TILE_SIZE)


func test_pot_tile_picks_the_variant_for_water_and_pipe() -> void:
	assert_eq(FarmTiles.pot_tile(false, false), FarmTiles.POT_DRY)
	assert_eq(FarmTiles.pot_tile(true, false), FarmTiles.POT_WET)
	assert_eq(FarmTiles.pot_tile(false, true), FarmTiles.POT_DRY_PIPE)
	assert_eq(FarmTiles.pot_tile(true, true), FarmTiles.POT_WET_PIPE)
