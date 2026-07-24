extends CanvasLayer
## Persistent HUD singleton: health/mana bars, fading objective banner,
## contextual interaction prompt, dialogue box with choices, and pause menu.
## Deliberately minimal — nothing sits permanently on screen except the two
## resource bars.

var health_bar: ProgressBar
var mana_bar: ProgressBar
var objective_label: Label
var objective_panel: PanelContainer
var prompt_label: Label
var notification_label: Label
var controls_hint: Label
var dialogue_panel: PanelContainer
var dialogue_speaker: Label
var dialogue_line: Label
var choices_box: VBoxContainer
var pause_panel: PanelContainer
var root_control: Control

var _notification_timer := 0.0
var _objective_timer := 0.0
var _controls_timer := 6.0
var _paused := false

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	_build_bars()
	_build_objective_banner()
	_build_prompt()
	_build_notification()
	_build_controls_hint()
	_build_dialogue_box()
	_build_pause_menu()
	visible = false
	DialogueManager.line_shown.connect(_on_dialogue_line)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	GameManager.notification_requested.connect(show_notification)
	GameManager.objective_requested.connect(set_objective)

func activate() -> void:
	visible = true
	_controls_timer = 6.0
	controls_hint.show()
	if PlayerManager.player:
		PlayerManager.player.movement_mode_changed.connect(func(_l): pass)
	_refresh_stats()
	PlayerManager.stats_changed.connect(_refresh_stats)

func _process(delta: float) -> void:
	if not visible:
		return
	if Input.is_action_just_pressed("pause") and not DialogueManager.is_open and GameManager.phase != GameManager.GamePhase.CUTSCENE:
		toggle_pause()
	if _notification_timer > 0.0:
		_notification_timer -= delta
		if _notification_timer <= 0.0:
			var t := create_tween()
			t.tween_property(notification_label, "modulate:a", 0.0, 0.6)
	if _objective_timer > 0.0:
		_objective_timer -= delta
	if _controls_timer > 0.0:
		_controls_timer -= delta
		if _controls_timer <= 0.0:
			var t2 := create_tween()
			t2.tween_property(controls_hint, "modulate:a", 0.0, 1.0)

# ---------------------------------------------------------------- bars

func _panel_style(bg: Color, border: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.border_color = border
	if border.a > 0.0:
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.border_width_top = 1
		sb.border_width_bottom = 1
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

func _build_bars() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 24)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.015, 0.03, 0.72), Color(0.4, 0.1, 0.15, 0.5)))
	root_control.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)
	var title := Label.new()
	title.text = "NIGHTFALL"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.75, 0.15, 0.2))
	vbox.add_child(title)
	health_bar = _make_bar(Color(0.62, 0.09, 0.13))
	vbox.add_child(health_bar)
	mana_bar = _make_bar(Color(0.35, 0.28, 0.75))
	vbox.add_child(mana_bar)

func _make_bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(240, 16)
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.06, 0.08, 0.8)
	bg.corner_radius_top_left = 3
	bg.corner_radius_top_right = 3
	bg.corner_radius_bottom_left = 3
	bg.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("background", bg)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left = 3
	fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_left = 3
	fill.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _refresh_stats() -> void:
	health_bar.max_value = PlayerManager.max_health
	health_bar.value = PlayerManager.health
	mana_bar.max_value = PlayerManager.max_mana
	mana_bar.value = PlayerManager.mana

# ---------------------------------------------------------------- objective

func _build_objective_banner() -> void:
	objective_panel = PanelContainer.new()
	objective_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.015, 0.03, 0.68), Color(0.4, 0.3, 0.6, 0.4)))
	objective_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	objective_panel.position = Vector2(0, 20)
	objective_panel.set_deferred("size", Vector2(1280, 0))
	objective_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root_control.add_child(objective_panel)
	objective_label = Label.new()
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 16)
	objective_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.95))
	objective_panel.add_child(objective_label)
	objective_panel.custom_minimum_size = Vector2(1280, 0)
	objective_panel.anchor_left = 0.5
	objective_panel.anchor_right = 0.5
	objective_panel.offset_left = -260
	objective_panel.offset_right = 260

func set_objective(text: String) -> void:
	objective_label.text = "OBJECTIVE — %s" % text
	objective_panel.modulate.a = 0.0
	objective_panel.show()
	var t := create_tween()
	t.tween_property(objective_panel, "modulate:a", 1.0, 0.5)
	t.tween_interval(5.0)
	t.tween_property(objective_panel, "modulate:a", 0.55, 0.8)

# ---------------------------------------------------------------- prompt / notification

func _build_prompt() -> void:
	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.position = Vector2(-160, -120)
	prompt_label.size = Vector2(320, 30)
	prompt_label.add_theme_font_size_override("font_size", 16)
	prompt_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
	prompt_label.hide()
	root_control.add_child(prompt_label)

func show_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.show()

func hide_prompt() -> void:
	prompt_label.hide()

func _build_notification() -> void:
	notification_label = Label.new()
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	notification_label.position = Vector2(-320, -160)
	notification_label.size = Vector2(640, 28)
	notification_label.add_theme_font_size_override("font_size", 15)
	notification_label.add_theme_color_override("font_color", Color(0.8, 0.78, 0.85))
	notification_label.modulate.a = 0.0
	root_control.add_child(notification_label)

func show_notification(message: String) -> void:
	notification_label.text = message
	notification_label.modulate.a = 1.0
	_notification_timer = 3.2

func _build_controls_hint() -> void:
	controls_hint = Label.new()
	controls_hint.text = "WASD Move   Mouse Look   Shift Sprint   Space Jump   Ctrl Dodge   LMB Attack   E Interact"
	controls_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	controls_hint.position = Vector2(-360, -34)
	controls_hint.size = Vector2(720, 24)
	controls_hint.add_theme_font_size_override("font_size", 13)
	controls_hint.modulate = Color(1, 1, 1, 0.65)
	root_control.add_child(controls_hint)

# ---------------------------------------------------------------- dialogue

func _build_dialogue_box() -> void:
	dialogue_panel = PanelContainer.new()
	dialogue_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.01, 0.025, 0.9), Color(0.5, 0.12, 0.18, 0.65)))
	dialogue_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialogue_panel.position = Vector2(-380, -220)
	dialogue_panel.size = Vector2(760, 0)
	dialogue_panel.hide()
	root_control.add_child(dialogue_panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	dialogue_panel.add_child(vbox)
	dialogue_speaker = Label.new()
	dialogue_speaker.add_theme_font_size_override("font_size", 15)
	dialogue_speaker.add_theme_color_override("font_color", Color(0.78, 0.2, 0.28))
	vbox.add_child(dialogue_speaker)
	dialogue_line = Label.new()
	dialogue_line.add_theme_font_size_override("font_size", 17)
	dialogue_line.add_theme_color_override("font_color", Color(0.92, 0.9, 0.95))
	dialogue_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(dialogue_line)
	choices_box = VBoxContainer.new()
	choices_box.add_theme_constant_override("separation", 4)
	vbox.add_child(choices_box)

func _on_dialogue_line(speaker: String, line: String, choices: Array) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	dialogue_panel.show()
	dialogue_speaker.text = speaker
	dialogue_line.text = line
	for c in choices_box.get_children():
		c.queue_free()
	if choices.is_empty():
		return
	for i in choices.size():
		var choice: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = "%d. %s" % [i + 1, choice.get("text", "...")]
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(func():
			AudioManager.play_ui()
			DialogueManager.choose(i))
		choices_box.add_child(btn)

func _on_dialogue_ended() -> void:
	dialogue_panel.hide()
	if not _paused:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# ---------------------------------------------------------------- pause menu

func _build_pause_menu() -> void:
	pause_panel = PanelContainer.new()
	pause_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.01, 0.008, 0.02, 0.92), Color(0.4, 0.1, 0.15, 0.6)))
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.position = Vector2(-140, -110)
	pause_panel.size = Vector2(280, 220)
	pause_panel.hide()
	root_control.add_child(pause_panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	pause_panel.add_child(vbox)
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.8, 0.2, 0.25))
	vbox.add_child(title)
	var resume := Button.new()
	resume.text = "Resume"
	resume.pressed.connect(toggle_pause)
	vbox.add_child(resume)
	var save := Button.new()
	save.text = "Save Game"
	save.pressed.connect(func(): SaveManager.save_game())
	vbox.add_child(save)
	var load_btn := Button.new()
	load_btn.text = "Load Game"
	load_btn.pressed.connect(func():
		SaveManager.load_game()
		toggle_pause())
	vbox.add_child(load_btn)
	var quit := Button.new()
	quit.text = "Quit to Title"
	quit.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn"))
	vbox.add_child(quit)

func toggle_pause() -> void:
	_paused = not _paused
	pause_panel.visible = _paused
	get_tree().paused = _paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _paused else Input.MOUSE_MODE_CAPTURED
	AudioManager.play_ui()
