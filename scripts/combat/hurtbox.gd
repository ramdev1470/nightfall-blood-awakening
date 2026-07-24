class_name Hurtbox
extends Area3D
## Attach to the character's body. `owner_group` should be "player" or "enemy"
## so hitboxes can avoid friendly fire. The owning script must implement
## `_on_hurtbox_hit(damage: float, knockback: Vector3, source: Node) -> void`.

signal hit_received(damage: float, knockback: Vector3, source: Node)

@export var owner_group := "enemy"

func _ready() -> void:
	monitoring = false
	monitorable = true
	collision_mask = 0

func receive_hit(damage: float, knockback: Vector3, source: Node) -> void:
	hit_received.emit(damage, knockback, source)
