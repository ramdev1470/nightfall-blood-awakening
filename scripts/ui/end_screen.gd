extends Control
## Shared full-screen end state: chapter completion (cliffhanger) or death/restart.

signal restart_requested
signal continue_requested

func show_death() -> void:
	_build("YOU HAVE FALLEN", "The Hollow does not forgive the unworthy.", Color(0.6, 0.05, 0.08), "Try Again", "restart")

func show_chapter_complete() -> void:
	_build("NIGHTFALL", "THE BLOOD HAS AWAKENED", Color(0.65, 0.15, 0.75), "Return to Title", "title", "Chapter One Complete — The Hollow")

func _build(headline: String, sub: String, accent: Color, button_text: String, mode: String, eyebrow: String = "") -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.position = Vector2(-300, -120)
	vbox.size = Vector2(600, 260)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	add_child(vbox)

	if not eyebrow.is_empty():
		var eyebrow_label := Label.new()
		eyebrow_label.text = eyebrow
		eyebrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		eyebrow_label.add_theme_font_size_override("font_size", 14)
		eyebrow_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.65))
		vbox.add_child(eyebrow_label)

	var headline_label := Label.new()
	headline_label.text = headline
	headline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	headline_label.add_theme_font_size_override("font_size", 44)
	headline_label.add_theme_color_override("font_color", accent)
	vbox.add_child(headline_label)

	var sub_label := Label.new()
	sub_label.text = sub
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.add_theme_font_size_override("font_size", 18)
	sub_label.add_theme_color_override("font_color", Color(0.75, 0.72, 0.8))
	vbox.add_child(sub_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(spacer)

	var btn := Button.new()
	btn.text = button_text
	btn.custom_minimum_size = Vector2(220, 42)
	btn.pressed.connect(func():
		AudioManager.play_ui()
		if mode == "restart":
			restart_requested.emit()
			get_tree().paused = false
			get_tree().reload_current_scene()
		else:
			continue_requested.emit()
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/title_screen.tscn"))
	vbox.add_child(btn)
	btn.grab_focus()

	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.2)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
