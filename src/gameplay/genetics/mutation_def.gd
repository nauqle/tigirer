class_name MutationDef
extends Resource
## Nadir bir mutasyon özelliğinin tanımı. Çaprazlamada küçük bir olasılıkla ortaya çıkar ve
## sonraki nesillere geçebilir. Etkileri bitkinin ifade edilen özelliklerini ve görünümünü değiştirir.
##
## Veri odaklıdır: yeni mutasyon eklemek bir .tres dosyası eklemektir. Etkiler çarpandır;
## 1.0 "etki yok" demektir.
##
## [codeblock]
## var golden: MutationDef = ruleset.get_mutation(&"golden")
## print(golden.value_multiplier)  # pazar değeri çarpanı
## [/codeblock]

## Benzersiz kimlik (örn. &"golden").
@export var id: StringName = &""
## Oyuncuya gösterilecek ad.
@export var display_name: String = ""
## Rastgele seçimde ağırlık. Büyük = daha sık çıkar, küçük = daha nadir.
@export_range(0.0, 100.0, 0.1) var weight: float = 10.0

@export_group("Özellik çarpanları")
@export var growth_multiplier: float = 1.0
@export var water_multiplier: float = 1.0
@export var value_multiplier: float = 1.0

@export_group("Görünüm")
## 0 = parlama yok. Büyüdükçe halo ve kenar parlaması güçlenir.
@export_range(0.0, 2.0, 0.05) var glow_strength: float = 0.0
@export var glow_color: Color = Color(0.4, 1.0, 0.8)
## 0..1. Yüzeyde gezinen parlak bir bant (kristal etkisi).
@export_range(0.0, 1.0, 0.05) var shimmer: float = 0.0
## Alfa 0'dan büyükse meyvenin rengi bu renge zorlanır (örn. altın).
@export var tint_override: Color = Color(1.0, 1.0, 1.0, 0.0)
## Meyve tonuna eklenen kayma; 0.5 = tamamlayıcı renk (kimera etkisi).
@export_range(-1.0, 1.0, 0.01) var fruit_hue_shift: float = 0.0

@export_group("Uyumsuzluk")
## Bu mutasyonla AYNI bitkide bulunamayacak mutasyonların kimlikleri.
@export var excludes: Array[StringName] = []
