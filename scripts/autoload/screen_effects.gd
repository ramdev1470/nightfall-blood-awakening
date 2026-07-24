extends CanvasLayer
## Full-screen overlay used for the Blood Surge power and impact feedback.
## Lives as an autoload so any system (combat, story script, NPC) can trigger it.

signal shake_requested(strength: float, duration: float)

var _overlay: ColorRect
var _material: ShaderMaterial

func _ready() -> void:
	layer = 50
	_overlay = ColorRect.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(1, 1, 1, 1)
	var shader := load("res://shaders/vignette_overlay.gdshader")
	if shader:
		_material = ShaderMaterial.new()
		_material.shader = shader
		_material.set_shader_parameter("intensity", 0.0)
		_material.set_shader_parameter("tint", Color(0.55, 0.05, 0.12, 1.0))
		_overlay.material = _material
	add_child(_overlay)

func pulse_blood_surge(duration: float = 3.0) -> void:
	if _material == null:
		return
	var tween := create_tween()
	_material.set_shader_parameter("tint", Color(0.6, 0.05, 0.35, 1.0))
	tween.tween_method(func(v: float): _material.set_shader_parameter("intensity", v), 0.0, 0.85, 0.35)
	tween.tween_method(func(v: float): _material.set_shader_parameter("intensity", v), 0.85, 0.35, duration)

func pulse_hit(duration: float = 0.25) -> void:
	if _material == null:
		return
	var tween := create_tween()
	_material.set_shader_parameter("tint", Color(0.7, 0.02, 0.05, 1.0))
	tween.tween_method(func(v: float): _material.set_shader_parameter("intensity", v), 0.6, 0.0, duration)

func fade_out(duration: float = 1.0) -> void:
	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 0)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)
	var tween := create_tween()
	tween.tween_property(black, "color:a", 1.0, duration)
	await tween.finished

func request_shake(strength: float = 0.3, duration: float = 0.2) -> void:
	shake_requested.emit(strength, duration)
