class_name UiMotion
extends RefCounted
## Hareket dili: tüm arayüz animasyonları BURADAN geçer (süre/eğri `UiTokens`). "Hareketi azalt" açıkken hiçbir animasyon oynamaz:
## düğüm doğrudan son durumuna konur (içerik kaybolmaz, yalnızca hareket kalkar). Tween'ler düğümün kendisine bağlıdır: düğüm
## silinince tween de biter, sızıntı olmaz.
##
## Eğriler: giriş = OUT (yavaşlayarak), ödül/pop = BACK/OUT (hafif aşım), ortam döngüsü = SINE IN_OUT.
##
## Uygular: design/design-language.md, "Hareket".
##
## [codeblock]
## UiMotion.pop_in(card)                  # ödül, yeni öğe
## UiMotion.stagger_in(rows)              # liste girişi
## UiMotion.count_label(label, 0, 250, fmt)
## [/codeblock]

## Ayarlardaki "hareketi azalt" (Main atar).
static var reduce_motion: bool = false


## Kontrolün dönme/ölçek merkezini ortaya alır ve boyut değişince güncel tutar.
static func center_pivot(control: Control) -> void:
	control.pivot_offset = control.size * 0.5
	if not control.has_meta(&"_pivot_bound"):
		control.set_meta(&"_pivot_bound", true)
		control.resized.connect(func() -> void: control.pivot_offset = control.size * 0.5)


## Küçülüp büyüyerek belirir (hafif aşımlı). Ödül ve yeni öğe girişi için.
static func pop_in(node: Control, delay: float = 0.0) -> Tween:
	if reduce_motion:
		node.modulate.a = 1.0
		node.scale = Vector2.ONE
		return null
	center_pivot(node)
	node.scale = Vector2.ONE * 0.82
	node.modulate.a = 0.0
	var tween: Tween = node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "modulate:a", 1.0, UiTokens.DUR_QUICK).set_delay(delay)
	tween.tween_property(node, "scale", Vector2.ONE, UiTokens.DUR_BASE).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween


## Yavaşça soluklaşarak belirir.
static func fade_in(node: CanvasItem, duration: float = UiTokens.DUR_BASE, delay: float = 0.0) -> Tween:
	if reduce_motion:
		node.modulate.a = 1.0
		return null
	node.modulate.a = 0.0
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "modulate:a", 1.0, duration).set_delay(delay)
	return tween


## `offset` kadar uzaktan kayarak belirir (konteyner altındaki düğümlerde `position` yerine `translation` gibi çalışması için
## hedef konumu tween sonunda korur: yalnızca görsel kaydırma uygular).
static func slide_in(node: Control, offset: Vector2, delay: float = 0.0, duration: float = UiTokens.DUR_BASE) -> Tween:
	if reduce_motion:
		node.modulate.a = 1.0
		return null
	var target: Vector2 = node.position
	node.modulate.a = 0.0
	node.position = target + offset
	var tween: Tween = node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "modulate:a", 1.0, duration * 0.7).set_delay(delay)
	tween.tween_property(node, "position", target, duration).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return tween


## Bir listenin öğelerini sırayla (`step` saniye arayla) belirir yapar. Kapsayıcı yerleşimi bozulmaz: yalnızca saydamlık ve ölçek.
static func stagger_in(items: Array[Control], step: float = 0.045, max_delay: float = 0.5) -> void:
	var index: int = 0
	for item: Control in items:
		pop_in(item, minf(float(index) * step, max_delay))
		index += 1


## Bir sayı etiketini `from`'dan `to`'ya sayarak değiştirir; metin `formatter.call(int)` ile üretilir.
static func count_label(label: Label, from: int, to: int, formatter: Callable, duration: float = UiTokens.DUR_SLOW) -> Tween:
	if reduce_motion or from == to:
		label.text = formatter.call(to) as String
		return null
	var tween: Tween = label.create_tween()
	tween.tween_method(func(value: float) -> void: label.text = formatter.call(int(round(value))) as String, float(from), float(to), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return tween


## Kısa "tık": ölçeği büyütüp geri getirir (kredi kazanımı, yeni sayı).
static func bump(node: Control, amount: float = UiTokens.POP_OVERSHOOT) -> Tween:
	if reduce_motion:
		return null
	center_pivot(node)
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "scale", Vector2.ONE * amount, UiTokens.DUR_PRESS * 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, UiTokens.DUR_BASE).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween


## Sürekli nabız (hazır/dikkat göstergesi): saydamlık ve hafif ölçek. Döngü düğümle birlikte biter. Hareketi azalt: sabit.
static func pulse(node: Control, low_alpha: float = 0.55, scale_to: float = 1.06) -> Tween:
	if reduce_motion:
		node.modulate.a = 1.0
		return null
	center_pivot(node)
	var tween: Tween = node.create_tween().set_loops()
	tween.set_parallel(true)
	tween.tween_property(node, "modulate:a", low_alpha, UiTokens.DUR_AMBIENT * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "scale", Vector2.ONE * scale_to, UiTokens.DUR_AMBIENT * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.chain().set_parallel(true)
	tween.tween_property(node, "modulate:a", 1.0, UiTokens.DUR_AMBIENT * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, UiTokens.DUR_AMBIENT * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tween


## Hata sarsıntısı: yatayda kısa titreme (yetersiz kredi gibi reddedilen eylemler).
static func shake(node: Control) -> Tween:
	if reduce_motion:
		return null
	var origin: float = node.position.x
	var tween: Tween = node.create_tween()
	for offset: float in [-10.0, 9.0, -6.0, 4.0, 0.0]:
		tween.tween_property(node, "position:x", origin + offset, UiTokens.DUR_PRESS * 0.7)
	return tween


## Hedefe doğru kayan renk geçişi (seçili sekme, açık/kapalı).
static func tint(node: CanvasItem, color: Color, duration: float = UiTokens.DUR_QUICK) -> Tween:
	if reduce_motion:
		node.modulate = color
		return null
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "modulate", color, duration)
	return tween
