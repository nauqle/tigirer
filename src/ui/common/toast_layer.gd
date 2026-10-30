class_name ToastLayer
extends Control
## Geçici bildirimler: komut sonuçları, mutasyon ve keşif başlıkları, haber olayları, kombo özeti. Hepsi SignalBus olayıdır;
## burada yalnızca gösterilir (oyun durumuna dokunmaz). Hareketi azalt açıksa süzülme yerine sabit solar.
##
## Uygular: design/game-brief.md, FAZ 5 mobil arayüz (geri bildirim), "Core loop" (mutasyon bildirimi).

const _MAX_VISIBLE: int = 4
const _SHOW_SECONDS: float = 2.6

## Mutasyon adını çözmek için kural seti (Main atar).
var ruleset: GeneticsRuleset
var reduce_motion: bool = false
var colorblind: bool = false

var _stack: VBoxContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin: MarginContainer = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 250)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	add_child(margin)
	_stack = VBoxContainer.new()
	_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stack.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_stack.add_theme_constant_override("separation", 10)
	margin.add_child(_stack)
	SignalBus.toast_requested.connect(_on_toast_requested)
	SignalBus.mutation_discovered.connect(_on_mutation_discovered)
	SignalBus.dex_discovery.connect(_on_dex_discovery)
	SignalBus.market_event_started.connect(_on_market_event_started)
	SignalBus.harvest_swipe_finished.connect(_on_swipe_finished)


## Düz metin bildirimi gösterir. `kind`: 0 bilgi, 1 iyi, 2 kötü, 3 altın (büyük başlık).
func show_text(text: String, kind: int = 0) -> void:
	var palette: Dictionary = UiTheme.palette(colorblind)
	var color: Color = palette["accent"] as Color
	var variation: StringName = &"AccentLabel"
	match kind:
		1:
			color = palette["good"] as Color
			variation = &"GoodLabel"
		2:
			color = palette["bad"] as Color
			variation = &"BadLabel"
		3:
			color = palette["gold"] as Color
			variation = &"HeadingLabel"
	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.modulate = Color(1, 1, 1, 0.97)
	var label: Label = UiKit.label(text, variation, true, HORIZONTAL_ALIGNMENT_CENTER)
	label.add_theme_color_override("font_color", color)
	panel.add_child(label)
	_stack.add_child(panel)
	while _stack.get_child_count() > _MAX_VISIBLE:
		var oldest: Node = _stack.get_child(0)
		_stack.remove_child(oldest)
		oldest.queue_free()
	var tween: Tween = panel.create_tween()
	tween.tween_interval(_SHOW_SECONDS)
	tween.tween_property(panel, "modulate:a", 0.0, 0.0 if reduce_motion else 0.4)
	tween.tween_callback(panel.queue_free)


func _on_toast_requested(message_key: String, args: Array) -> void:
	var text: String = tr(message_key)
	if not args.is_empty():
		text = text % args
	show_text(text, 2 if message_key.begins_with("ERR_") else 0)


func _on_mutation_discovered(_child: PlantGene, mutation_id: StringName) -> void:
	var mutation: MutationDef = ruleset.get_mutation(mutation_id) if ruleset != null else null
	show_text(tr("TOAST_MUTATION") % (mutation.display_name if mutation != null else String(mutation_id)), 3)


func _on_dex_discovery(_morph_id: StringName, new_species: bool, bonus: int) -> void:
	show_text(tr("TOAST_NEW_SPECIES" if new_species else "TOAST_NEW_VARIANT") % bonus, 1)


func _on_market_event_started(event_def: MarketEventDef) -> void:
	show_text("%s %s" % ["▲" if event_def.is_positive() else "▼", event_def.headline], 1 if event_def.is_positive() else 2)


func _on_swipe_finished(count: int, total_value: float) -> void:
	if count >= 3:
		show_text(tr("TOAST_COMBO") % [count, int(round(total_value))], 3)
