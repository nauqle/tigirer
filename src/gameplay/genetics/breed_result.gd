class_name BreedResult
extends RefCounted
## Bir çaprazlamanın sonucu ve nasıl oluştuğu. Arayüz "MUTASYON!" bildirimini bundan okur.
##
## Uygular: design/game-brief.md, "Core loop" son madde (çaprazla, mutasyon çıkabilir, Seed-Dex'e kayıt).
##
## [codeblock]
## var result: BreedResult = GeneticsEngine.crossbreed_detailed(a, b, ruleset, rng)
## if result.new_mutation != &"":
##     print("Yeni mutasyon: ", result.new_mutation)
## [/codeblock]

## Üretilen çocuk genotipi.
var child: PlantGene
## Bu çaprazlamada YENİ ortaya çıkan mutasyonun kimliği; yoksa boş.
var new_mutation: StringName = &""
## Ebeveyn(ler)den miras kalan mutasyonların kimlikleri.
var inherited_mutations: Array[StringName] = []
