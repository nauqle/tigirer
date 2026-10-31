class_name ToastLayer
extends Control
## Geçici bildirimler: komut sonuçları, mutasyon ve keşif başlıkları, haber olayları, kombo özeti. Hepsi SignalBus olayıdır;
## burada yalnızca gösterilir (oyun durumuna dokunmaz). Tasarım kuralları:
## - Aynı metin art arda gelirse YENİ bildirim açılmaz, mevcut olan "×N" olur ve hafifçe sıçrar (üç "yeni varyant" tek hap olur).
## - En çok `MAX_VISIBLE` hap; her biri ikon + tek satır. İçeriğin üstüne yığılmaz: HUD'un hemen altında durur.
## - Giriş: küçülüp büyüyerek belirir; hareketi azalt açıkken sabit solar.
##
## Uygular: design/design-language.md, "Geri bildirim"; design/game-brief.md, "Core loop" (mutasyon bildirimi).

## Bildirimin anlamı: ikon ve renk buradan seçilir.
enum Kind { INFO, GOOD, BAD, GOLD, UP, DOWN }

const MAX_VISIBLE: int = 3
const SHOW_SECONDS: float = 2.4

## Mutasyon adını çözmek için kural seti (Main atar).
var ruleset: GeneticsRuleset
var reduce_motion: bool = false
var colorblind: bool = false

var _stack: VBoxContainer
var _margin: MarginContainer
var _live: Array[Dictionary] = []  # {panel, label, text, kind, count, timer}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_margin = MarginContainer.new()
	_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_margin.add_theme_constant_override("margin_top", 250)
	_margin.add_theme_constant_override("margin_left", UiTokens.SPACE_4)
	_margin.add_theme_constant_override("margin_right", UiTokens.SPACE_4)
	add_child(_margin)
	_stack = VBoxContainer.new()
	_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stack.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_stack.alignment = BoxContainer.ALIGNMENT_BEGIN
	_stack.add_theme_constant_override("separation", UiTokens.SPACE_1)
	_margin.add_child(_stack)
	SignalBus.toast_requested.connect(_on_toast_requested)
	SignalBus.mutation_discovered.connect(_on_mutation_discovered)
	SignalBus.dex_discovery.connect(_on_dex_discovery)
	SignalBus.market_event_started.connect(_on_market_event_started)
	SignalBus.harvest_swipe_finished.connect(_on_swipe_finished)
	SignalBus.goal_completed.connect(_on_goal_completed)


## Bildirimlerin başlayacağı üst boşluk (HUD'un altı).
func set_top(offset: float) -> void:
	if _margin != null:
		_margin.add_theme_constant_override("margin_top", int(offset))


## Düz metin bildirimi gösterir.
func show_text(text: String, kind: Kind = Kind.INFO) -> void:
	for entry: Dictionary in _live:
		if entry["text"] == text and entry["kind"] == kind and is_instance_valid(entry["panel"]):
			_repeat(entry)
			return
	_create(text, kind)


## Şu an ekranda olan bildirim metinleri (test ve erişilebilirlik için).
func visible_texts() -> Array[String]:
	var texts: Array[String] = []
	for entry: Dictionary in _live:
		if is_instance_valid(entry["panel"]):
			var text: String = String(entry["text"])
			texts.append(UiKit.plain_text(text) if int(entry["count"]) == 1 else "%s ×%d" % [UiKit.plain_text(text), entry["count"]])
	return texts


## Bildirim içeriğini (metin + satır içi kredi ikonları) kurar.
func _fill(holder: HBoxContainer, text: String, color: Color) -> void:
	UiKit.clear(holder)
	var content: Control = UiKit.credit_text(text, &"")
	holder.add_child(content)
	for child: Node in (content.get_children() if content is HBoxContainer else [content]):
		if child is Label:
			(child as Label).add_theme_color_override("font_color", color)
			(child as Label).vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _create(text: String, kind: Kind) -> void:
	var colors: Dictionary = UiTokens.palette(colorblind)
	var tint: Color = _tint_for(kind, colors)
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = &"Toast"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var row: HBoxContainer = UiKit.hbox(UiTokens.SPACE_1)
	panel.add_child(row)
	row.add_child(UiKit.icon(_icon_for(kind), UiTokens.ICON_SM, tint))
	var holder: HBoxContainer = UiKit.hbox(0)
	holder.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(holder)
	var text_color: Color = tint if kind != Kind.INFO else UiTokens.TEXT
	_fill(holder, text, text_color)
	_stack.add_child(panel)
	var entry: Dictionary = {"panel": panel, "holder": holder, "color": text_color, "text": text, "kind": kind, "count": 1, "timer": null}
	_live.append(entry)
	while _live.size() > MAX_VISIBLE:
		_dismiss(_live[0], true)
	UiMotion.pop_in(panel)
	_arm_timer(entry)


func _repeat(entry: Dictionary) -> void:
	entry["count"] = int(entry["count"]) + 1
	_fill(entry["holder"] as HBoxContainer, "%s ×%d" % [entry["text"], entry["count"]], entry["color"] as Color)
	UiMotion.bump(entry["panel"] as Control)
	_arm_timer(entry)


func _arm_timer(entry: Dictionary) -> void:
	var previous: Variant = entry["timer"]
	if previous is Tween and (previous as Tween).is_valid():
		(previous as Tween).kill()
	var panel: Control = entry["panel"] as Control
	var tween: Tween = panel.create_tween()
	tween.tween_interval(SHOW_SECONDS)
	tween.tween_callback(func() -> void: _dismiss(entry, false))
	entry["timer"] = tween


func _dismiss(entry: Dictionary, immediately: bool) -> void:
	_live.erase(entry)
	var panel: Control = entry["panel"] as Control
	if not is_instance_valid(panel):
		return
	if immediately or UiMotion.reduce_motion:
		panel.queue_free()
		return
	var tween: Tween = panel.create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, UiTokens.DUR_QUICK)
	tween.tween_callback(panel.queue_free)


func _on_toast_requested(message_key: String, args: Array) -> void:
	var text: String = tr(message_key)
	if not args.is_empty():
		var shown: Array = []
		for value: Variant in args:
			if value is String:
				shown.append(tr(value))
			elif value is int:
				shown.append(UiFormat.number(value as int))
			else:
				shown.append(value)
		text = text % shown
	show_text(text, Kind.BAD if message_key.begins_with("ERR_") else Kind.INFO)


func _on_mutation_discovered(_child: PlantGene, mutation_id: StringName) -> void:
	var mutation: MutationDef = ruleset.get_mutation(mutation_id) if ruleset != null else null
	show_text(tr("TOAST_MUTATION") % (tr(mutation.display_name) if mutation != null else String(mutation_id)), Kind.GOLD)


func _on_dex_discovery(_morph_id: StringName, new_species: bool, bonus: int) -> void:
	show_text(tr("TOAST_NEW_SPECIES" if new_species else "TOAST_NEW_VARIANT") % UiFormat.number(bonus), Kind.GOOD)


func _on_market_event_started(event_def: MarketEventDef) -> void:
	show_text(tr(event_def.headline), Kind.UP if event_def.is_positive() else Kind.DOWN)


func _on_swipe_finished(count: int, total_value: float) -> void:
	if count >= 3:
		show_text(tr("TOAST_COMBO") % [count, UiFormat.number(int(round(total_value)))], Kind.GOLD)


func _on_goal_completed(goal_id: StringName, reward: int) -> void:
	show_text(tr("TOAST_GOAL_DONE") % [tr("GOAL_%s_TITLE" % String(goal_id).to_upper()), UiFormat.number(reward)], Kind.GOOD)


func _icon_for(kind: Kind) -> StringName:
	match kind:
		Kind.GOOD:
			return &"check"
		Kind.BAD:
			return &"close"
		Kind.GOLD:
			return &"sparkle"
		Kind.UP:
			return &"trend_up"
		Kind.DOWN:
			return &"trend_down"
	return &"info"


func _tint_for(kind: Kind, colors: Dictionary) -> Color:
	match kind:
		Kind.GOOD, Kind.UP:
			return colors["good"] as Color
		Kind.BAD, Kind.DOWN:
			return colors["bad"] as Color
		Kind.GOLD:
			return colors["gold"] as Color
	return colors["aqua"] as Color
