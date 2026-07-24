class_name Werewolf
extends EnemyBase

var _legs: Array[MeshInstance3D] = []
var _head: MeshInstance3D
var _walk_phase := 0.0

func _ready() -> void:
	super._ready()
	_build_model()

func _build_model() -> void:
	var fur := StandardMaterial3D.new()
	fur.albedo_color = Color(0.08, 0.07, 0.09)
	fur.roughness = 1.0
	var fur_light := StandardMaterial3D.new()
	fur_light.albedo_color = Color(0.14, 0.11, 0.13)
	fur_light.roughness = 1.0
	var eyes := StandardMaterial3D.new()
	eyes.albedo_color = Color(0.9, 0.15, 0.15)
	eyes.emission_enabled = true
	eyes.emission = Color(0.9, 0.1, 0.1)
	eyes.emission_energy_multiplier = 3.0

	var torso := MeshInstance3D.new()
	torso.name = "Torso"
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.42
	torso_mesh.height = 1.5
	torso.mesh = torso_mesh
	torso.material_override = fur
	torso.rotation_degrees = Vector3(90, 0, 0)
	torso.position = Vector3(0, 0.75, 0.1)
	add_child(torso)

	_head = MeshInstance3D.new()
	_head.name = "Head"
	var head_mesh := PrismMesh.new()
	head_mesh.size = Vector3(0.5, 0.45, 0.7)
	_head.mesh = head_mesh
	_head.material_override = fur_light
	_head.position = Vector3(0, 1.05, 0.85)
	_head.rotation_degrees = Vector3(0, 180, 0)
	add_child(_head)

	for ex in [-0.14, 0.14]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.05
		eye_mesh.height = 0.1
		eye.mesh = eye_mesh
		eye.material_override = eyes
		eye.position = Vector3(ex, 1.1, 1.15)
		add_child(eye)

	var leg_positions := [Vector3(-0.28, 0.4, 0.5), Vector3(0.28, 0.4, 0.5), Vector3(-0.28, 0.4, -0.4), Vector3(0.28, 0.4, -0.4)]
	for lp in leg_positions:
		var leg := MeshInstance3D.new()
		leg.name = "Leg"
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.09
		leg_mesh.height = 0.8
		leg.mesh = leg_mesh
		leg.material_override = fur
		leg.position = lp
		add_child(leg)
		_legs.append(leg)

	var tail := MeshInstance3D.new()
	var tail_mesh := CapsuleMesh.new()
	tail_mesh.radius = 0.08
	tail_mesh.height = 0.6
	tail.mesh = tail_mesh
	tail.material_override = fur
	tail.position = Vector3(0, 0.85, -0.75)
	tail.rotation_degrees = Vector3(60, 0, 0)
	add_child(tail)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.5
	shape.height = 1.5
	collision.shape = shape
	collision.position = Vector3(0, 0.75, 0)
	add_child(collision)

	var hb := Hurtbox.new()
	hb.name = "Hurtbox"
	hb.owner_group = "enemy"
	var hb_shape := CollisionShape3D.new()
	var hb_capsule := CapsuleShape3D.new()
	hb_capsule.radius = 0.55
	hb_capsule.height = 1.6
	hb_shape.shape = hb_capsule
	hb_shape.position = Vector3(0, 0.75, 0)
	hb.add_child(hb_shape)
	hb.collision_layer = 4
	add_child(hb)
	hurtbox = hb
	hb.owner_group = "enemy"
	hb.hit_received.connect(_on_hurtbox_hit)

	var hbx := Hitbox.new()
	hbx.name = "Hitbox"
	hbx.damage = attack_damage
	hbx.source_group = "enemy"
	var hbx_shape := CollisionShape3D.new()
	var hbx_sphere := SphereShape3D.new()
	hbx_sphere.radius = 0.6
	hbx_shape.shape = hbx_sphere
	hbx_shape.position = Vector3(0, 1.05, 1.0)
	hbx.add_child(hbx_shape)
	hbx.collision_layer = 8
	add_child(hbx)
	hitbox = hbx

func _on_animate(delta: float) -> void:
	var speed_ratio: float = Vector2(velocity.x, velocity.z).length() / max(chase_speed, 0.01)
	_walk_phase += delta * (6.0 + speed_ratio * 6.0)
	for i in _legs.size():
		var offset := 0.0 if i % 2 == 0 else PI
		var swing := sin(_walk_phase + offset) * 0.22 * clampf(speed_ratio, 0.0, 1.0)
		_legs[i].rotation.x = swing
	if _head:
		_head.rotation.x = sin(_walk_phase * 0.5) * 0.05
