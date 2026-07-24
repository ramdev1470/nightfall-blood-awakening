extends Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	HUD.visible = false
	_build()

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.015, 0.015, 0.03)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.04, 0.02, 0.06, 1.0))
	gradient.set_color(1, Color(0.0, 0.0, 0.0, 1.0))
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = gradient
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.35)
	grad_tex.width = 512
	grad_tex.height = 512
	var glow := TextureRect.new()
	glow.texture = grad_tex
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(glow)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.position = Vector2(-260, -140)
	vbox.size = Vector2(520, 320)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	add_child(vbox)

	var title := Label.new()
	title.text = "NIGHTFALL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.75, 0.08, 0.14))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "B L O O D   A W A K E N I N G"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.55, 0.5, 0.7))
	vbox.add_child(subtitle)

	var chapter := Label.new()
	chapter.text = "Chapter One — The Hollow"
	chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter.add_theme_font_size_override("font_size", 14)
	chapter.add_theme_color_override("font_color", Color(0.6, 0.55, 0.6))
	vbox.add_child(chapter)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	var start_btn := Button.new()
	start_btn.text = "Enter The Hollow"
	start_btn.custom_minimum_size = Vector2(220, 44)
	start_btn.add_theme_font_size_override("font_size", 16)
	start_btn.pressed.connect(_on_start)
	vbox.add_child(start_btn)
	start_btn.grab_focus()

	var quit_btn := Button.new()
	quit_btn.text = "Quit"
	quit_btn.custom_minimum_size = Vector2(220, 36)
	quit_btn.pressed.connect(func(): get_tree().quit())
	vbox.add_child(quit_btn)

	title.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(title, "modulate:a", 1.0, 1.4)

func _on_start() -> void:
	AudioManager.play_ui()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
