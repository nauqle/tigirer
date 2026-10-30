class_name GrowthModel
extends RefCounted
## Büyüme formülleri: saf ve durumsuz (testlerde sahne gerekmez). Tüm sayılar `FarmConfig`'ten gelir.
##
## Uygular: design/game-brief.md, "Core loop" ve FAZ 2 (evreler, su/ışık çarpanları).
## Formüller: docs/architecture/floralab-architecture.md, "Çiftlik kuralları".
##
## [codeblock]
## var rate: float = GrowthModel.growth_rate(phenotype, pot.water, uv_level, config)  # saniyede büyüme
## var stage: GrowthModel.Stage = GrowthModel.stage_of(pot.growth, config)
## [/codeblock]

## Bitkinin yaşam evresi (arayüz ve ses için).
enum Stage {
	SEED,  ## Tohum: yeni dikildi
	SPROUT,  ## Filiz: büyüyor
	MATURE,  ## Olgun: hasada hazır
}


## Büyüme değerinden (0..1) evreyi verir. 1.0 ve üstü olgundur.
static func stage_of(growth: float, config: FarmConfig) -> Stage:
	if growth >= 1.0:
		return Stage.MATURE
	if growth >= config.sprout_threshold:
		return Stage.SPROUT
	return Stage.SEED


## Sudan gelen büyüme çarpanı, 0..1: eşiğin altında 0 (büyüme durur), eşik + rampa üstünde 1, arası yumuşak geçiş.
static func water_factor(water: float, config: FarmConfig) -> float:
	var low: float = config.water_growth_threshold
	return smoothstep(low, low + config.water_growth_ramp, water)


## Satırdaki UV lamba seviyesinden gelen büyüme çarpanı: 1 + seviye x bonus.
static func light_multiplier(uv_level: int, config: FarmConfig) -> float:
	return 1.0 + float(maxi(uv_level, 0)) * config.uv_growth_bonus_per_level


## Saniyede büyüme (0..1 ölçeğinde): (1 / taban süre) x genin büyüme hızı x su çarpanı x ışık çarpanı.
static func growth_rate(phenotype: PlantPhenotype, water: float, uv_level: int, config: FarmConfig) -> float:
	var base: float = 1.0 / maxf(config.base_grow_seconds, 0.001)
	return base * phenotype.growth_speed * water_factor(water, config) * light_multiplier(uv_level, config)


## Büyürken saniyede kaybedilen su: taban tüketim x genin su tüketimi çarpanı.
static func water_drain(phenotype: PlantPhenotype, config: FarmConfig) -> float:
	return config.water_drain_per_second * phenotype.water_use


## Olgunlaştıktan sonra beklemenin değer çarpanı (1.0 = kayıp yok). Ek süre dakika başına `overgrowth_loss_per_minute`
## kadar düşürür, `overgrowth_min_factor`'ün altına inmez.
static func overgrowth_factor(overgrowth_seconds: float, config: FarmConfig) -> float:
	var late: float = maxf(overgrowth_seconds - config.overgrowth_grace_seconds, 0.0)
	var factor: float = 1.0 - config.overgrowth_loss_per_minute * (late / 60.0)
	return clampf(factor, config.overgrowth_min_factor, 1.0)


## Kombo adımından (0 = ilk bitki) hasat değerine eklenen oran: adım x bonus, tavanla sınırlı.
static func combo_bonus(combo_step: int, config: FarmConfig) -> float:
	return minf(float(maxi(combo_step, 0)) * config.combo_bonus_per_step, config.combo_bonus_cap)
