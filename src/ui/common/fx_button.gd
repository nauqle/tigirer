class_name FxButton
extends Button
## Dokunma geri bildirimli düğme: basınca hafifçe küçülür, bırakınca yaylanarak döner, basılınca arayüz "tık" sesi için olay yayar.
## Hareketi azalt açıkken ölçek animasyonu oynamaz. İkon (`UiIcons`) ve metin birlikte gösterilebilir.
##
## Uygular: design/design-language.md, "Hareket" (basma geri bildirimi) ve "Etkileşim".
##
## [codeblock]
## var buy: FxButton = FxButton.new()
## buy.text = tr("BTN_BUY")
## buy.theme_type_variation = &"PrimaryButton"
## [/codeblock]

## Basınca `SignalBus.ui_tapped` yayınlansın mı (ses). Başka bir olay kendi sesini çalıyorsa kapatılabilir.
var tap_sound: bool = true

var _tween: Tween


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	UiMotion.center_pivot(self)
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	pressed.connect(_on_pressed)


func _on_down() -> void:
	_animate_to(Vector2.ONE * UiTokens.PRESS_SCALE, UiTokens.DUR_PRESS, Tween.TRANS_SINE)


func _on_up() -> void:
	_animate_to(Vector2.ONE, UiTokens.DUR_BASE, Tween.TRANS_BACK)


func _on_pressed() -> void:
	if tap_sound:
		SignalBus.ui_tapped.emit()


func _animate_to(target: Vector2, duration: float, transition: Tween.TransitionType) -> void:
	if _tween != null:
		_tween.kill()
	if UiMotion.reduce_motion:
		scale = Vector2.ONE
		return
	_tween = create_tween()
	_tween.tween_property(self, "scale", target, duration).set_trans(transition).set_ease(Tween.EASE_OUT)
