extends Node3D
## Orchestrates Chapter One: builds the level, spawns the player, and drives
## the scripted story beats (bell, NPC encounter, ambush, Blood Surge, ending).

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const WEREWOLF_SCENE := preload("res://scenes/enemies/werewolf.tscn")
const ALDRIC_SCENE := preload("res://scenes/npc/father_aldric.tscn")
const END_SCREEN_SCENE := preload("res://scenes/ui/end_screen.tscn")

var _landmarks: Dictionary = {}
var _player: NightfallPlayer
var _aldric: FatherAldric
var _werewolf: EnemyBase
var _bell_rung := false
var _gate_notified := false
var _square_triggered := false
var _blood_surge_triggered := false
var _chapter_ending := false
var _shadow_glimpse_shown := false

func _ready() -> void:
	PlayerManager.reset_for_new_chapter()
	_landmarks = WorldBuilder.build(self)
	_spawn_player()
	_spawn_aldric()
	_play_intro()
	HUD.activate()
	GameManager.set_phase(GameManager.GamePhase.EXPLORATION)
	GameManager.story_flag_set.connect(_on_story_flag)
	PlayerManager.died.connect(_on_player_died)
	get_tree().create_timer(7.0).timeout.connect(_ring_bell)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("save_game"):
		SaveManager.save_game()
	elif event.is_action_pressed("load_game"):
		SaveManager.load_game()

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player) or _chapter_ending:
		return
	var z := _player.global_position.z
	if not _gate_notified and z <= _landmarks.get("gate_trigger_z", 30.0):
		_gate_notified = true
		GameManager.set_objective("Find the source of the bell.")
	if not _square_triggered and z <= _landmarks.get("square_trigger_z", 8.0):
		_square_triggered = true
		_show_shadow_glimpse()
		GameManager.set_objective("Reach the church.")

func _spawn_player() -> void:
	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	_player.global_position = _landmarks.get("player_spawn", Vector3(0, 1.2, 56))

func _spawn_aldric() -> void:
	_aldric = ALDRIC_SCENE.instantiate()
	add_child(_aldric)
	var door: Vector3 = _landmarks.get("church_door", Vector3(0, 0, -8.5))
	_aldric.global_position = door + Vector3(1.4, 0, 1.6)
	_aldric.rotation.y = PI

func _play_intro() -> void:
	var overlay := CanvasLayer.new()
	overlay.layer = 90
	add_child(overlay)
	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 1)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(black)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.position = Vector2(-260, -60)
	vbox.size = Vector2(520, 120)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay.add_child(vbox)
	var t1 := Label.new()
	t1.text = "NIGHTFALL"
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.add_theme_font_size_override("font_size", 40)
	t1.add_theme_color_override("font_color", Color(0.75, 0.1, 0.15))
	vbox.add_child(t1)
	var t2 := Label.new()
	t2.text = "BLOOD AWAKENING"
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.add_theme_font_size_override("font_size", 18)
	t2.add_theme_color_override("font_color", Color(0.55, 0.5, 0.7))
	vbox.add_child(t2)

	_player.input_locked = true
	GameManager.set_phase(GameManager.GamePhase.CUTSCENE)
	var tween := create_tween()
	tween.tween_interval(1.4)
	tween.tween_property(vbox, "modulate:a", 0.0, 0.01)
	tween.tween_interval(0.01)
	tween.tween_property(black, "color:a", 0.0, 1.8)
	tween.tween_callback(func():
		overlay.queue_free()
		_player.input_locked = false
		GameManager.set_phase(GameManager.GamePhase.EXPLORATION)
		GameManager.notify("The Hollow — the fog closes behind you.")
		GameManager.set_objective("Follow the road into town."))
	vbox.modulate.a = 1.0

func _ring_bell() -> void:
	if _bell_rung:
		return
	_bell_rung = true
	AudioManager.play_bell()
	GameManager.notify("A church bell tolls, though no one should be there to ring it.")
	var bell := find_child("TowerBell", true, false)
	var flash := find_child("BellFlashLight", true, false)
	if bell:
		var t := bell.create_tween()
		t.set_loops(4)
		t.tween_property(bell, "rotation:z", 0.25, 0.25)
		t.tween_property(bell, "rotation:z", -0.25, 0.25)
	if flash and flash is OmniLight3D:
		var lt := flash.create_tween()
		lt.set_loops(4)
		lt.tween_property(flash, "light_energy", 2.5, 0.25)
		lt.tween_property(flash, "light_energy", 0.0, 0.25)

func _show_shadow_glimpse() -> void:
	if _shadow_glimpse_shown:
		return
	_shadow_glimpse_shown = true
	GameManager.notify("Something moved between the buildings.")
	var silhouette := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.35
	mesh.height = 1.8
	silhouette.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.01, 0.01, 0.02, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	silhouette.material_override = mat
	silhouette.position = Vector3(-10, 1.0, 4)
	add_child(silhouette)
	var tween := create_tween()
	tween.tween_property(silhouette, "position", Vector3(10, 1.0, 2), 1.6).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 1.6)
	tween.tween_callback(silhouette.queue_free)

func _on_story_flag(flag: String) -> void:
	if flag == "met_aldric" and not _chapter_ending:
		GameManager.set_objective("Something is near. Stay alert.")
		get_tree().create_timer(2.5).timeout.connect(_start_ambush)

func _start_ambush() -> void:
	if not is_instance_valid(_player) or _werewolf != null:
		return
	_werewolf = WEREWOLF_SCENE.instantiate()
	add_child(_werewolf)
	var point: Vector3 = _landmarks.get("ambush_point", Vector3(9, 0, -9))
	_werewolf.global_position = point
	_werewolf.died.connect(_on_werewolf_defeated)
	_werewolf.staggered.connect(_on_werewolf_staggered)
	GameManager.set_phase(GameManager.GamePhase.COMBAT)
	GameManager.set_objective("Survive the attack.")
	GameManager.notify("A shape lunges from the graveyard fog!")
	ScreenEffects.request_shake(0.3, 0.25)

func _on_werewolf_staggered(_enemy: EnemyBase) -> void:
	if _blood_surge_triggered:
		return
	_blood_surge_triggered = true
	get_tree().create_timer(0.4).timeout.connect(_trigger_blood_surge)

func _trigger_blood_surge() -> void:
	if not is_instance_valid(_player):
		return
	PlayerManager.trigger_blood_surge()
	GameManager.notify("Power floods through you — impossible, burning power.")
	GameManager.set_objective("Finish this.")
	if is_instance_valid(_aldric):
		_aldric.fear_reaction()

func _on_werewolf_defeated(_enemy: EnemyBase) -> void:
	if _chapter_ending:
		return
	_chapter_ending = true
	GameManager.set_phase(GameManager.GamePhase.CUTSCENE)
	_player.input_locked = true
	GameManager.set_objective("The bloodline stirs...")
	get_tree().create_timer(2.5).timeout.connect(_end_chapter)

func _end_chapter() -> void:
	await ScreenEffects.fade_out(1.8)
	var end_screen := END_SCREEN_SCENE.instantiate()
	var layer := CanvasLayer.new()
	layer.layer = 95
	add_child(layer)
	layer.add_child(end_screen)
	end_screen.show_chapter_complete()

func _on_player_died() -> void:
	if _chapter_ending:
		return
	_chapter_ending = true
	_player.input_locked = true
	GameManager.set_phase(GameManager.GamePhase.CUTSCENE)
	var end_screen := END_SCREEN_SCENE.instantiate()
	var layer := CanvasLayer.new()
	layer.layer = 95
	add_child(layer)
	layer.add_child(end_screen)
	end_screen.show_death()
