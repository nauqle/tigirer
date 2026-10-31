class_name Main
extends Control
## Uygulamanın ana sahnesi (dikey mobil arayüz): gün-gece döngülü manzara, üst çubuk (HUD), beş sekme (Çiftlik, Lab, Pazar,
## Seed-Dex, Geliştir), alt gezinme çubuğu, bildirimler, ayarlar ve çevrimdışı özeti. `GameSession` burada kurulur (kompozisyon
## kökü) ve panellere verilir; paneller oyunu yalnızca komutlarla değiştirir. Android: güvenli alan, geri tuşu (çift basarak çık),
## duraklatınca otomatik kayıt. Arayüz DEĞİŞTİRİLEBİLİR bir kökün altında kurulur: dil değişince tüm metinler yeni dille yeniden çizilir.
##
## Uygular: design/game-brief.md, FAZ 5 (dikey mobil ekran arayüzü, Seed-Dex, kayıt sistemi, çevrimdışı kazanç);
## design/design-language.md.
##
## Düğüm ağacı:
## [codeblock]
## Main (Control)
## ├── NightBackdrop · GameSession (Node) · AudioService (Node)
## └── Ui (Control, dil değişince yeniden kurulur)
##     ├── SafeArea (MarginContainer)
##     │   └── Column (VBoxContainer)
##     │       ├── HudBar  ├── Content (Control: FarmPanel · LabPanel · MarketPanel · DexPanel · UpgradesPanel)  └── NavBar
##     └── ToastLayer · SettingsOverlay · OfflinePopup
## [/codeblock]

## Çıkış istendi (Android geri tuşuna çift basış). Gerçek uygulama kaydedip kapatır; testlerde bağlanmaz.
signal quit_requested

const CATALOG_PATH: String = "res://assets/data/game_catalog.tres"
const _TAB_ICONS: Array[StringName] = [&"farm", &"lab", &"market", &"dex", &"upgrades"]
const _TAB_KEYS: Array[String] = ["TAB_FARM", "TAB_LAB", "TAB_MARKET", "TAB_DEX", "TAB_UPGRADES"]
const _TAB_FARM: int = 0
const _TAB_MARKET: int = 2
const _TAB_DEX: int = 3
const _TAB_UPGRADES: int = 4
const _BACK_WINDOW_SECONDS: float = 2.0
const _SIDE_MARGIN: float = 24.0
const _PHASE_REFRESH_SECONDS: float = 0.5

## Oyun kataloğu; boşsa varsayılan yüklenir (testler küçük katalog verebilir).
@export var catalog: GameCatalog
## Kayıt dosyasının yolu (testler geçici yol verir).
@export var save_path: String = SaveManager.DEFAULT_PATH
## Gerçek uygulama kipi: otomatik kayıt, kapanışta kaydet, geri tuşu ve ekranı açık tut.
@export var production_mode: bool = true
## >= 0 ise oyunun rastgeleliği tohumlanır (testler ve ekran görüntüleri); -1 = her seferinde farklı.
@export var rng_seed: int = -1
## Doluysa ("tr"/"en") dil seçimi bu olur ve kayıttaki/sistem dilini geçersiz kılar (testler ve ekran görüntüleri).
@export var language_override: String = ""

var session: GameSession

var _ui: Control
var _backdrop: NightBackdrop
var _panels: Array[GamePanel] = []
var _nav: NavBar
var _active_tab: int = 0
var _hud: HudBar
var _audio: AudioService
var _toasts: ToastLayer
var _settings: SettingsOverlay
var _offline: OfflinePopup
var _safe_area: MarginContainer
var _last_back_press: float = -100.0
var _applied_language: String = ""
var _phase_timer: float = 0.0
var _badges_queued: bool = false
var _dex_unseen: bool = false
var _upgrades_acknowledged: bool = false


func _ready() -> void:
	if catalog == null:
		catalog = load(CATALOG_PATH) as GameCatalog
	session = GameSession.new()
	add_child(session)
	session.autosave_enabled = production_mode
	session.quit_on_close = production_mode
	session.setup(catalog, save_path, rng_seed)

	_backdrop = NightBackdrop.new()
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)
	move_child(_backdrop, 0)
	_audio = AudioService.new()
	add_child(_audio)

	session.start()
	_resolve_language()
	UiMotion.reduce_motion = session.settings.reduce_motion
	_build_ui()
	session.settings.changed.connect(_on_settings_changed)
	SignalBus.offline_report_ready.connect(_on_offline_report)
	SignalBus.game_reloaded.connect(_apply_settings)
	_connect_badge_signals()
	resized.connect(_apply_safe_area)
	if production_mode:
		get_tree().set_auto_accept_quit(false)
		DisplayServer.screen_set_keep_on(true)
		quit_requested.connect(_on_quit_requested)
	_apply_settings()
	_apply_safe_area()
	_select_tab(_TAB_FARM, false)
	_update_time_of_day()
	if session.last_offline_report != null and session.last_offline_report.has_news():
		_offline.show_report(session.last_offline_report)


func _process(delta: float) -> void:
	_phase_timer += delta
	if _phase_timer >= _PHASE_REFRESH_SECONDS:
		_phase_timer = 0.0
		_update_time_of_day()


# ------------------------------------------------------------------ kurulum


## Dil seçimi: geçersiz kılma > kayıttaki > sistem dili.
func _resolve_language() -> void:
	var settings: GameSettings = session.settings
	if language_override != "":
		settings.set_language(language_override)
	elif settings.language == "":
		settings.set_language(GameSettings.default_language(Localization.system_language()))
	Localization.apply(settings.language)
	_applied_language = settings.language


## Tüm arayüz tek bir kökün altında kurulur; dil değişince bu kök atılıp yeniden kurulur.
func _build_ui() -> void:
	_ui = Control.new()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ui)
	_build_layout()
	_toasts = ToastLayer.new()
	_toasts.ruleset = catalog.ruleset
	_ui.add_child(_toasts)
	_settings = SettingsOverlay.new()
	_settings.setup(session)
	_settings.visible = false
	_settings.closed.connect(func() -> void: _settings.visible = false)
	_ui.add_child(_settings)
	_offline = OfflinePopup.new()
	_offline.setup()
	_ui.add_child(_offline)


func _build_layout() -> void:
	_panels.clear()
	_safe_area = MarginContainer.new()
	_safe_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(_safe_area)
	var column: VBoxContainer = UiKit.vbox(UiTokens.SPACE_2)
	_safe_area.add_child(column)

	_hud = HudBar.new()
	_hud.setup(session)
	_hud.menu_requested.connect(open_settings)
	column.add_child(_hud)

	var content: Control = Control.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(content)
	var panel_scripts: Array[GamePanel] = [FarmPanel.new(), LabPanel.new(), MarketPanel.new(), DexPanel.new(), UpgradesPanel.new()]
	for panel: GamePanel in panel_scripts:
		content.add_child(panel)
		panel.setup(session)
		panel.tab_requested.connect(open_tab)
		_panels.append(panel)

	_nav = NavBar.new()
	_nav.setup()
	for i: int in _TAB_KEYS.size():
		_nav.add_tab(_TAB_ICONS[i], tr(_TAB_KEYS[i]))
	_nav.tab_selected.connect(_on_tab_selected)
	column.add_child(_nav)


## Dil değişti: arayüzü yeni dille baştan kurar (etkin sekme ve açık ayarlar korunur).
func _rebuild_ui() -> void:
	var keep_tab: int = _active_tab
	var settings_open: bool = _settings != null and _settings.visible
	_ui.queue_free()
	_ui = null
	_build_ui()
	_apply_settings()
	_apply_safe_area()
	_select_tab(keep_tab, false)
	_update_time_of_day()
	if settings_open:
		_settings.visible = true


# ------------------------------------------------------------------ ayarlar


func _on_offline_report(report: OfflineReport) -> void:
	if is_instance_valid(_offline):
		_offline.show_report(report)


func _on_settings_changed() -> void:
	if session.settings.language != _applied_language:
		_applied_language = session.settings.language
		Localization.apply(_applied_language)
		_rebuild_ui.call_deferred()
		return
	_apply_settings()


## Ayarları uygular: tema (yazı boyutu, renk körlüğü paleti), ses, hareketi azalt, dil.
func _apply_settings() -> void:
	if _ui == null or not is_instance_valid(_toasts):
		return
	var settings: GameSettings = session.settings
	UiMotion.reduce_motion = settings.reduce_motion
	theme = UiTheme.build(settings.text_scale(), settings.colorblind)
	_audio.enabled = settings.sound_on
	_toasts.reduce_motion = settings.reduce_motion
	_toasts.colorblind = settings.colorblind
	_hud.set_colorblind(settings.colorblind)
	_backdrop.set_motion(not settings.reduce_motion)
	for panel: GamePanel in _panels:
		panel.refresh()
	_position_toasts.call_deferred()


## Mobilde çentik ve sistem çubukları için güvenli alan kenar boşlukları (tuval pikseli); masaüstünde sabit boşluk.
func _apply_safe_area() -> void:
	if _safe_area == null:
		return
	var top: float = 24.0
	var bottom: float = 16.0
	if OS.has_feature("mobile") and DisplayServer.window_get_size().x > 0:
		var safe: Rect2i = DisplayServer.get_display_safe_area()
		var window: Vector2i = DisplayServer.window_get_size()
		var scale_factor: float = size.x / float(window.x)
		top += maxf(float(safe.position.y) * scale_factor, 0.0)
		bottom += maxf(float(window.y - safe.end.y) * scale_factor, 0.0)
	_safe_area.add_theme_constant_override("margin_left", int(_SIDE_MARGIN))
	_safe_area.add_theme_constant_override("margin_right", int(_SIDE_MARGIN))
	_safe_area.add_theme_constant_override("margin_top", int(top))
	_safe_area.add_theme_constant_override("margin_bottom", int(bottom))
	_position_toasts.call_deferred()


## Bildirimler HUD'un hemen altından başlar.
func _position_toasts() -> void:
	if is_instance_valid(_toasts) and is_instance_valid(_hud) and _hud.is_inside_tree():
		_toasts.set_top(_hud.get_global_rect().end.y - global_position.y + float(UiTokens.SPACE_1))


## Oyun saatine bağlı gün evresi: manzara ve HUD güncellenir.
func _update_time_of_day() -> void:
	if session == null or not is_instance_valid(_hud):
		return
	var phase: float = session.time.day_progress()
	_backdrop.set_phase(phase)
	_hud.set_time_of_day(phase)


# ------------------------------------------------------------------ sekmeler


func _on_tab_selected(index: int) -> void:
	_select_tab(index, true)


func _select_tab(index: int, animate: bool = true) -> void:
	var changed: bool = index != _active_tab
	_active_tab = index
	for i: int in _panels.size():
		_panels[i].visible = i == index
	_nav.select(index, false)
	if index == _TAB_DEX:
		_dex_unseen = false
	if index == _TAB_UPGRADES:
		_upgrades_acknowledged = true
	_panels[index].on_shown()
	if animate:
		SignalBus.ui_tapped.emit()
		if changed:
			UiMotion.fade_in(_panels[index], UiTokens.DUR_QUICK)
	_update_badges()


## Sekme düğmesine program yoluyla basar (testler ve otomatik oynatma).
func open_tab(index: int) -> void:
	_select_tab(clampi(index, 0, _panels.size() - 1), true)


func panel(index: int) -> GamePanel:
	return _panels[index]


func nav_bar() -> NavBar:
	return _nav


func hud() -> HudBar:
	return _hud


func toasts() -> ToastLayer:
	return _toasts


func settings_overlay() -> SettingsOverlay:
	return _settings


## Ayarlar sayfasını açar.
func open_settings() -> void:
	_settings.open()


# ------------------------------------------------------------------ rozetler


func _connect_badge_signals() -> void:
	SignalBus.credits_changed.connect(_queue_badges_int)
	SignalBus.inventory_changed.connect(_queue_badges)
	SignalBus.order_added.connect(_queue_badges_order)
	SignalBus.order_completed.connect(_queue_badges_order)
	SignalBus.order_expired.connect(_queue_badges_order)
	SignalBus.plant_matured.connect(_on_plant_matured)
	SignalBus.plant_harvested.connect(_on_plant_harvested)
	SignalBus.dex_discovery.connect(_on_dex_discovery)
	SignalBus.equipment_purchased.connect(_on_equipment_purchased)
	SignalBus.floor_unlocked.connect(_on_floor_unlocked)
	SignalBus.game_reloaded.connect(_queue_badges)


func _queue_badges() -> void:
	if _badges_queued:
		return
	_badges_queued = true
	_update_badges.call_deferred()


func _queue_badges_int(_value: int) -> void:
	_queue_badges()


func _queue_badges_order(_order: Order) -> void:
	_queue_badges()


func _on_plant_matured(_floor_index: int, _pot_index: int) -> void:
	_queue_badges()


func _on_plant_harvested(_result: HarvestResult) -> void:
	_queue_badges()


func _on_dex_discovery(_morph_id: StringName, _new_species: bool, _bonus: int) -> void:
	if _active_tab != _TAB_DEX:
		_dex_unseen = true
	_queue_badges()


func _on_equipment_purchased(_kind: EquipmentDef.Kind, _floor_index: int, _target: int, _level: int) -> void:
	_upgrades_acknowledged = false
	_queue_badges()


func _on_floor_unlocked(_floor_index: int) -> void:
	_upgrades_acknowledged = false
	_queue_badges()


## Dikkat rozetleri: Çiftlik (olgun bitki bekliyor), Pazar (teslim edilebilir sipariş), Seed-Dex (yeni keşif), Geliştir (yeni bir
## şey alınabilir hale geldi; sekme açılınca söner, kredi yeniden yetmeyince yeniden hazırlanır).
func _update_badges() -> void:
	_badges_queued = false
	if _nav == null or session == null:
		return
	var mature_waiting: bool = false
	for floor_state: FloorState in session.farm.floors:
		if not floor_state.unlocked:
			continue
		for pot: PotState in floor_state.pots:
			if pot.is_mature():
				mature_waiting = true
	_nav.set_badge(_TAB_FARM, mature_waiting and _active_tab != _TAB_FARM)
	var order_ready: bool = false
	for order: Order in session.orders.orders:
		if session.orders.can_fulfil(order, session.inventory):
			order_ready = true
	_nav.set_badge(_TAB_MARKET, order_ready and _active_tab != _TAB_MARKET)
	_nav.set_badge(_TAB_DEX, _dex_unseen and _active_tab != _TAB_DEX)
	var cheapest: int = session.automation.cheapest_purchase_cost()
	var affordable: bool = cheapest >= 0 and session.wallet.credits >= cheapest
	if not affordable:
		_upgrades_acknowledged = false
	_nav.set_badge(_TAB_UPGRADES, affordable and not _upgrades_acknowledged and _active_tab != _TAB_UPGRADES)


# ------------------------------------------------------------------ geri tuşu ve çıkış


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_pressed()


## Android geri tuşu: önce açık pencereyi kapatır, sonra Çiftlik sekmesine döner, son olarak çift basışla çıkar.
func _on_back_pressed() -> void:
	if _settings != null and _settings.visible:
		_settings.close()
	elif _offline != null and _offline.visible:
		_offline.close()
	elif _active_tab != _TAB_FARM:
		_select_tab(_TAB_FARM)
	else:
		var now: float = float(Time.get_ticks_msec()) / 1000.0
		if now - _last_back_press <= _BACK_WINDOW_SECONDS:
			quit_requested.emit()
		else:
			_last_back_press = now
			SignalBus.toast_requested.emit("MSG_BACK_AGAIN", [])


func _on_quit_requested() -> void:
	session.save_game()
	get_tree().quit()
