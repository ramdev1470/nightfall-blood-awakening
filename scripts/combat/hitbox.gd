class_name Hitbox
extends Area3D
## Attach under an attacker (player weapon hand / enemy jaw). Call `activate()`
## for the duration of the active attack frames; anything with a Hurtbox that
## overlaps while active takes damage once.

@export var damage := 12.0
@export var knockback := 6.0
@export var source_group := "player"

var _active := false
var _already_hit: Array[Node] = []

func _ready() -> void:
	monitoring = false
	monitorable = false
	collision_layer = 0
	collision_mask = 4 # hurtboxes live on layer 4
	area_entered.connect(_on_area_entered)

func activate() -> void:
	_active = true
	_already_hit.clear()
	monitoring = true
	for area in get_overlapping_areas():
		_on_area_entered(area)

func deactivate() -> void:
	_active = false
	monitoring = false

func _on_area_entered(area: Area3D) -> void:
	if not _active:
		return
	if not (area is Hurtbox):
		return
	if area in _already_hit:
		return
	var hurtbox := area as Hurtbox
	if hurtbox.owner_group == source_group:
		return
	_already_hit.append(area)
	var dir := Vector3.ZERO
	if area.get_parent() is Node3D and get_parent() is Node3D:
		dir = ((area.get_parent() as Node3D).global_position - (get_parent() as Node3D).global_position)
		dir.y = 0
		dir = dir.normalized()
	hurtbox.receive_hit(damage, dir * knockback, get_parent())
