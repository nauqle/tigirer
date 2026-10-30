class_name Main
extends Control
## Uygulamanın ana sahnesi (dikey mobil arayüz): üst çubuk, beş sekme (Çiftlik, Laboratuvar, Pazar, Seed-Dex, Geliştir),
## bildirimler, ayarlar ve çevrimdışı özeti. `GameSession` burada kurulur (kompozisyon kökü) ve panellere verilir; paneller
## oyunu yalnızca komutlarla değiştirir. Android: güvenli alan, geri tuşu (çift basarak çık), duraklatınca otomatik kayıt.
##
## Uygular: design/game-brief.md, FAZ 5 (dikey mobil ekran arayüzü, Seed-Dex, kayıt sistemi, çevrimdışı kazanç).
##
## Düğüm ağacı:
## [codeblock]
## Main (Control)
## ├── CityBackdrop · GameSession (Node) · AudioService (Node)
## ├── SafeArea (MarginContainer)
## │   └── Column (VBoxContainer)
## │       ├── HudBar  ├── Content (Control: FarmPanel · LabPanel · MarketPanel · DexPanel · UpgradesPanel)  └── TabBar (HBox)
## └── ToastLayer · SettingsOverlay · OfflinePopup
## [/codeblock]

## Çıkış istendi (Android geri tuşuna çift basış). Gerçek uygulama kaydedip kapatır; testlerde bağlanmaz.
signal quit_requested

const CATALOG_PATH: String = "res://assets/data/game_catalog.tres"
const _TAB_KEYS: Array[String] = ["TAB_FARM", "TAB_LAB", "TAB_MARKET", "TAB_DEX", "TAB_UPGRADES"]
const _BACK_WINDOW_SECONDS: float = 2.0
const _SIDE_MARGIN: float = 24.0

## Oyun kataloğu; boşsa varsayılan yüklenir (testler küçük katalog verebilir).
@export var catalog: GameCatalog
## Kayıt dosyasının yolu (testler geçici yol verir).
@export var save_path: String = SaveManager.DEFAULT_PATH
## Gerçek uygulama kipi: otomatik kayıt, kapanışta kaydet, geri tuşu ve ekranı açık tut.
@export var production_mode: bool = true
## >= 0 ise oyunun rastgeleliği tohumlanır (testler ve ekran görüntüleri); -1 = her seferinde farklı.
@export var rng_seed: int = -1

var session: GameSession

var _panels: Array[GamePanel] = []
var _tab_buttons: Array[Button] = []
var _active_tab: int = 0
var _hud: HudBar
var _audio: AudioService
var _toasts: ToastLayer
var _settings: SettingsOverlay
var _offline: OfflinePopup
var _safe_area: MarginContainer
var _last_back_press: float = -100.0


func _ready() -> void:
	if catalog == null:
		catalog = load(CATALOG_PATH) as GameCatalog
	session = GameSession.new()
	add_child(session)
	session.autosave_enabled = production_mode
	session.quit_on_close = production_mode
	session.setup(catalog, save_path, rng_seed)

	var backdrop: CityBackdrop = CityBackdrop.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	move_child(backdrop, 0)
	_audio = AudioService.new()
	add_child(_audio)
	_build_layout()
	_toasts = ToastLayer.new()
	_toasts.ruleset = catalog.ruleset
	add_child(_toasts)
	_settings = SettingsOverlay.new()
	_settings.setup(session)
	_settings.visible = false
	_settings.closed.connect(func() -> void: _settings.visible = false)
	add_child(_settings)
	_offline = OfflinePopup.new()
	_offline.setup()
	add_child(_offline)

	session.settings.changed.connect(_apply_settings)
	SignalBus.offline_report_ready.connect(_offline.show_report)
	SignalBus.game_reloaded.connect(_apply_settings)
	resized.connect(_apply_safe_area)
	if production_mode:
		get_tree().set_auto_accept_quit(false)
		DisplayServer.screen_set_keep_on(true)
		quit_requested.connect(_on_quit_requested)
	session.start()
	_apply_settings()
	_apply_safe_area()
	_select_tab(0)
	if session.last_offline_report != null and session.last_offline_report.has_news():
		_offline.show_report(session.last_offline_report)


func _build_layout() -> void:
	_safe_area = MarginContainer.new()
	_safe_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_safe_area)
	var column: VBoxContainer = UiKit.vbox(12)
	_safe_area.add_child(column)

	_hud = HudBar.new()
	_hud.setup(session)
	_hud.menu_requested.connect(func() -> void: _settings.visible = true)
	column.add_child(_hud)

	var content: Control = Control.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(content)
	var panel_scripts: Array[GamePanel] = [FarmPanel.new(), LabPanel.new(), MarketPanel.new(), DexPanel.new(), UpgradesPanel.new()]
	for panel: GamePanel in panel_scripts:
		content.add_child(panel)
		panel.setup(session)
		_panels.append(panel)

	var tabs: HBoxContainer = UiKit.hbox(8)
	column.add_child(tabs)
	for i: int in _TAB_KEYS.size():
		var button: Button = UiKit.button(tr(_TAB_KEYS[i]), &"TabButton", 104.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true  # uzun çeviri/büyük yazıda düğme genişliği metne göre büyüyüp ekranı taşırmasın
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.pressed.connect(_select_tab.bind(i))
		tabs.add_child(button)
		_tab_buttons.append(button)


func _select_tab(index: int) -> void:
	_active_tab = index
	for i: int in _panels.size():
		_panels[i].visible = i == index
		_tab_buttons[i].theme_type_variation = &"TabButtonActive" if i == index else &"TabButton"
	_panels[index].on_shown()
	SignalBus.ui_tapped.emit()


## Ayarları uygular: tema (yazı boyutu, renk körlüğü paleti), ses, hareketi azalt.
func _apply_settings() -> void:
	var settings: GameSettings = session.settings
	theme = UiTheme.build(settings.text_scale(), settings.colorblind)
	_audio.enabled = settings.sound_on
	_toasts.reduce_motion = settings.reduce_motion
	_toasts.colorblind = settings.colorblind
	_hud.set_reduce_motion(settings.reduce_motion)
	for panel: GamePanel in _panels:
		panel.refresh()


## Mobilde çentik ve sistem çubukları için güvenli alan kenar boşlukları (tuval pikseli); masaüstünde sabit boşluk.
func _apply_safe_area() -> void:
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


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_pressed()


## Android geri tuşu: önce açık pencereyi kapatır, sonra Çiftlik sekmesine döner, son olarak çift basışla çıkar.
func _on_back_pressed() -> void:
	if _settings != null and _settings.visible:
		_settings.visible = false
	elif _offline != null and _offline.visible:
		_offline.close()
	elif _active_tab != 0:
		_select_tab(0)
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


## Sekme düğmesine program yoluyla basar (testler ve otomatik oynatma).
func open_tab(index: int) -> void:
	_select_tab(clampi(index, 0, _panels.size() - 1))


func panel(index: int) -> GamePanel:
	return _panels[index]


func settings_overlay() -> SettingsOverlay:
	return _settings
