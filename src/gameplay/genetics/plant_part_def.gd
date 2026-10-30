class_name PlantPartDef
extends Resource
## Bitkinin tek bir görsel parçasının tanımı: gövde, yaprak ya da çiçek/meyve.
##
## Veri odaklıdır: yeni bir parça eklemek bir .tres dosyası eklemektir, kod değişmez.
## Parçalar `GeneticsRuleset.parts` listesinde toplanır. Baskınlık (Mendel) burada tanımlanır:
## bir genotipte iki farklı alel varsa baskınlığı büyük olan görünüme çıkar, küçük olan "çekinik" kalır.
##
## [codeblock]
## var part: PlantPartDef = ruleset.get_part(&"stem_vine")
## print(part.display_name, " baskınlık=", part.dominance)
## [/codeblock]

## Parçanın bitkideki katmanı.
enum Layer {
	STEM,  ## Gövde
	LEAF,  ## Yaprak
	FRUIT,  ## Çiçek / meyve
}

## Benzersiz kimlik, alellerde bu kimlik saklanır (örn. &"stem_vine").
@export var id: StringName = &""
@export var layer: Layer = Layer.STEM
## Oyuncuya gösterilecek ad.
@export var display_name: String = ""
## Parçanın dokusu. Gri tonlu çizilir; genetik renk `modulate` ile bindirilir.
@export var texture: Texture2D
## Dokuda, parçanın bağlandığı ya da oturduğu nokta (piksel). Gövde için taban, yaprak için sap ucu,
## meyve için oturma noktası.
@export var anchor: Vector2 = Vector2.ZERO
## Baskınlık. Büyük olan görünüme çıkar. Eşitse kimliği alfabetik olarak küçük olan çıkar.
@export var dominance: int = 0
## Yalnızca FRUIT: tek bir meyvenin taban pazar değeri (altın). Gene göre çarpılır.
@export var base_value: float = 0.0
## Yalnızca STEM: yaprakların gövdeye bağlandığı noktalar. Gövde tabanına göre; y negatif = yukarı.
@export var leaf_mounts: PackedVector2Array = PackedVector2Array()
## Yalnızca STEM: çiçek/meyvenin gövdeye bağlandığı nokta. Gövde tabanına göre.
@export var fruit_mount: Vector2 = Vector2.ZERO
