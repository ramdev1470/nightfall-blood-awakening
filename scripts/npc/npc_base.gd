class_name NPCBase
extends CharacterBody3D

signal interacted(npc: NPCBase)

@export var npc_name := "Stranger"
@export var robe_color := Color(0.2, 0.18, 0.24)
@export var trim_color := Color(0.5, 0.1, 0.15)
@export var interaction_range := 2.6

var _player_in_range := false
var can_interact := true

@onready var prompt_area: Area3D = get_node("InteractionArea") as Area3D

func _ready() -> void:
	add_to_group("npc")
	prompt_area.body_entered.connect(_on_body_entered)
	prompt_area.body_exited.connect(_on_body_exited)
	_build_model()

func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and can_interact and event.is_action_pressed("interact") and not DialogueManager.is_open:
		start_dialogue()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		if can_interact:
			HUD.show_prompt("[E] Talk to %s" % npc_name)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		HUD.hide_prompt()

func start_dialogue() -> void:
	interacted.emit(self)
	HUD.hide_prompt()
	face_player()
	var tree := _get_dialogue_tree()
	if tree.is_empty():
		return
	DialogueManager.start(tree, "start", Callable(self, "_on_dialogue_finished"))

## Override in subclasses to provide the branching dialogue tree.
func _get_dialogue_tree() -> Dictionary:
	return {}

## Override in subclasses to react after the conversation ends.
func _on_dialogue_finished() -> void:
	pass

func face_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var dir: Vector3 = (player.global_position - global_position)
		dir.y = 0
		if dir.length() > 0.1:
			rotation.y = atan2(dir.x, dir.z)

func _build_model() -> void:
	var robe := StandardMaterial3D.new()
	robe.albedo_color = robe_color
	robe.roughness = 0.95
	var trim := StandardMaterial3D.new()
	trim.albedo_color = trim_color
	trim.roughness = 0.7
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.75, 0.6, 0.5)
	skin.roughness = 0.8

	var cloak := MeshInstance3D.new()
	var cloak_mesh := CylinderMesh.new()
	cloak_mesh.top_radius = 0.32
	cloak_mesh.bottom_radius = 0.5
	cloak_mesh.height = 1.35
	cloak.mesh = cloak_mesh
	cloak.material_override = robe
	cloak.position = Vector3(0, 0.9, 0)
	add_child(cloak)

	var trim_ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.42
	ring_mesh.outer_radius = 0.5
	trim_ring.mesh = ring_mesh
	trim_ring.material_override = trim
	trim_ring.position = Vector3(0, 0.28, 0)
	add_child(trim_ring)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.24
	head_mesh.height = 0.48
	head.mesh = head_mesh
	head.material_override = skin
	head.position = Vector3(0, 1.72, 0)
	add_child(head)

	var hood := MeshInstance3D.new()
	var hood_mesh := CylinderMesh.new()
	hood_mesh.top_radius = 0.02
	hood_mesh.bottom_radius = 0.28
	hood_mesh.height = 0.4
	hood.mesh = hood_mesh
	hood.material_override = robe
	hood.position = Vector3(0, 1.85, -0.05)
	add_child(hood)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.7
	collision.shape = shape
	collision.position = Vector3(0, 0.9, 0)
	add_child(collision)
