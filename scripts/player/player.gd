class_name NightfallPlayer
extends CharacterBody3D

signal movement_mode_changed(label: String)
signal attack_performed

@export_category("Movement")
@export var walk_speed := 4.5
@export var sprint_speed := 7.2
@export var acceleration := 22.0
@export var jump_velocity := 6.8
@export var dodge_speed := 12.0
@export var dodge_duration := 0.28
@export_category("Camera")
@export var mouse_sensitivity := 0.0025
@export var min_pitch := deg_to_rad(-55.0)
@export var max_pitch := deg_to_rad(35.0)
@export_category("Combat")
@export var base_attack_damage := 18.0
@export var attack_duration := 0.45
@export var attack_cooldown := 0.25

@onready var camera_rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/SpringArm3D/Camera3D

var gravity := ProjectSettings.get_setting("physics/3d/default_gravity") as float
var _pitch := deg_to_rad(-12.0)
var _dodge_remaining := 0.0
var _dodge_direction := Vector3.ZERO
var _dodge_cooldown := 0.0
var _footstep_distance := 0.0
var input_locked := false

var _attack_timer := 0.0
var _attack_cooldown_timer := 0.0
var _is_attacking := false

var blood_surge_active := false
var _blood_surge_timer := 0.0
const BLOOD_SURGE_SPEED_MULT := 1.6
const BLOOD_SURGE_DAMAGE_MULT := 2.0

# --- procedural model parts ---
var _torso: MeshInstance3D
var _head: MeshInstance3D
var _cloak: MeshInstance3D
var _arm_l: Node3D
var _arm_r: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _model_root: Node3D
var _walk_phase := 0.0
var _aura_particles: GPUParticles3D
var hitbox: Hitbox
var hurtbox: Hurtbox

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	PlayerManager.player = self
	camera_rig.rotation.x = _pitch
	add_to_group("player")
	_build_model()
	_build_combat_components()
	PlayerManager.blood_surge_activated.connect(_on_blood_surge_activated)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch = clamp(_pitch - event.relative.y * mouse_sensitivity, min_pitch, max_pitch)
		camera_rig.rotation.x = _pitch
	elif event.is_action_pressed("pause"):
		pass # handled by HUD
	elif event.is_action_pressed("attack") and not input_locked:
		try_attack()

func update_locomotion(delta: float) -> void:
	if _dodge_cooldown > 0.0:
		_dodge_cooldown -= delta
	if _attack_cooldown_timer > 0.0:
		_attack_cooldown_timer -= delta
	if _is_attacking:
		_process_attack(delta)
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return
	if _dodge_remaining > 0.0:
		_dodge_remaining -= delta
		velocity.x = _dodge_direction.x * dodge_speed
		velocity.z = _dodge_direction.z * dodge_speed
		move_and_slide()
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = jump_velocity if (Input.is_action_just_pressed("jump") and not input_locked) else -0.1
	var input_vector := Vector2.ZERO
	if not input_locked:
		input_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var local_direction := Vector3(input_vector.x, 0.0, input_vector.y)
	var world_direction := (global_transform.basis * local_direction).normalized()
	var is_sprinting := Input.is_action_pressed("sprint") and input_vector.y < -0.1
	var speed_mult := BLOOD_SURGE_SPEED_MULT if blood_surge_active else 1.0
	var speed := (sprint_speed if is_sprinting else walk_speed) * speed_mult
	if world_direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, world_direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, world_direction.z * speed, acceleration * delta)
		if _model_root:
			_model_root.rotation.y = lerp_angle(_model_root.rotation.y, atan2(world_direction.x, world_direction.z), delta * 12.0)
		movement_mode_changed.emit("Sprint" if is_sprinting else "Walk")
		if Input.is_action_just_pressed("dodge") and not input_locked and _dodge_cooldown <= 0.0:
			_dodge_direction = world_direction
			_dodge_remaining = dodge_duration
			_dodge_cooldown = dodge_duration + 0.5
			AudioManager.play_swing()
		_step_footsteps(delta, Vector2(velocity.x, velocity.z).length())
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		movement_mode_changed.emit("Idle")
	move_and_slide()
	_animate_locomotion(delta, Vector2(velocity.x, velocity.z).length())

func _step_footsteps(delta: float, speed: float) -> void:
	if speed < 0.5 or not is_on_floor():
		return
	_footstep_distance += speed * delta
	if _footstep_distance > 3.2:
		_footstep_distance = 0.0
		AudioManager.play_footstep()

# ---------------------------------------------------------------- combat

func try_attack() -> void:
	if _is_attacking or _attack_cooldown_timer > 0.0 or _dodge_remaining > 0.0:
		return
	_is_attacking = true
	_attack_timer = attack_duration
	AudioManager.play_swing()
	attack_performed.emit()
	get_tree().create_timer(attack_duration * 0.35).timeout.connect(func():
		if is_instance_valid(hitbox) and _is_attacking:
			hitbox.damage = base_attack_damage * (BLOOD_SURGE_DAMAGE_MULT if blood_surge_active else 1.0)
			hitbox.activate())
	get_tree().create_timer(attack_duration * 0.6).timeout.connect(func():
		if is_instance_valid(hitbox):
			hitbox.deactivate())

func _process_attack(delta: float) -> void:
	_attack_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, acceleration * 3.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, acceleration * 3.0 * delta)
	if _arm_r:
		var progress := 1.0 - clampf(_attack_timer / attack_duration, 0.0, 1.0)
		_arm_r.rotation.x = lerp(-0.3, -2.4, sin(progress * PI))
	if _attack_timer <= 0.0:
		_is_attacking = false
		_attack_cooldown_timer = attack_cooldown
		if _arm_r:
			_arm_r.rotation.x = 0.0

func _build_combat_components() -> void:
	hurtbox = Hurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.owner_group = "player"
	var hb_shape := CollisionShape3D.new()
	var hb_capsule := CapsuleShape3D.new()
	hb_capsule.radius = 0.45
	hb_capsule.height = 1.8
	hb_shape.shape = hb_capsule
	hb_shape.position = Vector3(0, 0.95, 0)
	hurtbox.add_child(hb_shape)
	hurtbox.collision_layer = 4
	add_child(hurtbox)
	hurtbox.hit_received.connect(_on_hurtbox_hit)

	hitbox = Hitbox.new()
	hitbox.name = "Hitbox"
	hitbox.damage = base_attack_damage
	hitbox.source_group = "player"
	var hbx_shape := CollisionShape3D.new()
	var hbx_sphere := SphereShape3D.new()
	hbx_sphere.radius = 0.7
	hbx_shape.shape = hbx_sphere
	hbx_shape.position = Vector3(0, 1.1, 1.1)
	hitbox.add_child(hbx_shape)
	hitbox.collision_layer = 8
	add_child(hitbox)

func _on_hurtbox_hit(damage: float, knockback: Vector3, _source: Node) -> void:
	PlayerManager.set_health(PlayerManager.health - damage)
	velocity += knockback
	ScreenEffects.pulse_hit()
	ScreenEffects.request_shake(0.25, 0.15)
	if PlayerManager.health <= 0.0:
		input_locked = true

# ---------------------------------------------------------------- blood surge

func _on_blood_surge_activated() -> void:
	blood_surge_active = true
	_blood_surge_timer = 6.0
	AudioManager.play_power()
	ScreenEffects.pulse_blood_surge(6.0)
	_spawn_aura()

func _process(delta: float) -> void:
	if blood_surge_active:
		_blood_surge_timer -= delta
		if _blood_surge_timer <= 0.0:
			blood_surge_active = false
			if _aura_particles:
				_aura_particles.emitting = false

func _spawn_aura() -> void:
	if _aura_particles == null:
		_aura_particles = GPUParticles3D.new()
		_aura_particles.name = "BloodSurgeAura"
		var mesh := QuadMesh.new()
		mesh.size = Vector2(0.12, 0.12)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.6, 0.1, 0.85, 0.9)
		mat.emission_enabled = true
		mat.emission = Color(0.6, 0.1, 0.85)
		mat.emission_energy_multiplier = 3.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_aura_particles.draw_pass_1 = mesh
		var pm := ParticleProcessMaterial.new()
		pm.direction = Vector3(0, 1, 0)
		pm.spread = 40.0
		pm.gravity = Vector3(0, 0.6, 0)
		pm.initial_velocity_min = 0.6
		pm.initial_velocity_max = 1.4
		pm.scale_min = 0.5
		pm.scale_max = 1.2
		pm.color = Color(0.6, 0.1, 0.85, 0.9)
		_aura_particles.process_material = pm
		_aura_particles.amount = 40
		_aura_particles.lifetime = 1.2
		_aura_particles.position = Vector3(0, 0.2, 0)
		mesh.material = mat
		add_child(_aura_particles)
	_aura_particles.emitting = true
	_aura_particles.restart()

# ---------------------------------------------------------------- procedural model

func _build_model() -> void:
	_model_root = Node3D.new()
	_model_root.name = "Model"
	add_child(_model_root)

	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color(0.14, 0.03, 0.05)
	cloth.roughness = 0.75
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.75, 0.6, 0.5)
	skin.roughness = 0.8
	var cloak_mat := StandardMaterial3D.new()
	cloak_mat.albedo_color = Color(0.05, 0.045, 0.06)
	cloak_mat.roughness = 0.9

	_torso = MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.28
	torso_mesh.height = 0.95
	_torso.mesh = torso_mesh
	_torso.material_override = cloth
	_torso.position = Vector3(0, 1.15, 0)
	_model_root.add_child(_torso)

	_cloak = MeshInstance3D.new()
	var cloak_mesh := CylinderMesh.new()
	cloak_mesh.top_radius = 0.3
	cloak_mesh.bottom_radius = 0.42
	cloak_mesh.height = 0.85
	_cloak.mesh = cloak_mesh
	_cloak.material_override = cloak_mat
	_cloak.position = Vector3(0, 0.75, -0.05)
	_model_root.add_child(_cloak)

	_head = MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.44
	_head.mesh = head_mesh
	_head.material_override = skin
	_head.position = Vector3(0, 1.72, 0)
	_model_root.add_child(_head)

	_arm_l = _limb(_model_root, Vector3(-0.36, 1.25, 0), cloth)
	_arm_r = _limb(_model_root, Vector3(0.36, 1.25, 0), cloth)
	_leg_l = _limb(_model_root, Vector3(-0.14, 0.55, 0), Color(0.08, 0.06, 0.07))
	_leg_r = _limb(_model_root, Vector3(0.14, 0.55, 0), Color(0.08, 0.06, 0.07))

func _limb(parent: Node3D, pos: Vector3, mat_or_color) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pos
	parent.add_child(pivot)
	var limb := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.09
	mesh.height = 0.62
	limb.mesh = mesh
	limb.position = Vector3(0, -0.3, 0)
	if mat_or_color is Material:
		limb.material_override = mat_or_color
	else:
		var m := StandardMaterial3D.new()
		m.albedo_color = mat_or_color
		limb.material_override = m
	pivot.add_child(limb)
	return pivot

func _animate_locomotion(delta: float, speed: float) -> void:
	var moving := speed > 0.3
	if moving:
		_walk_phase += delta * (7.0 + speed * 1.2)
	else:
		_walk_phase = lerp(_walk_phase, 0.0, delta * 4.0)
	var swing := sin(_walk_phase) * clampf(speed / walk_speed, 0.0, 1.3) * 0.55
	if not _is_attacking:
		if _arm_l:
			_arm_l.rotation.x = -swing
		if _arm_r:
			_arm_r.rotation.x = swing
	if _leg_l:
		_leg_l.rotation.x = swing
	if _leg_r:
		_leg_r.rotation.x = -swing
	if _torso:
		_torso.position.y = 1.15 + (abs(sin(_walk_phase * 2.0)) * 0.02 if moving else sin(Time.get_ticks_msec() * 0.002) * 0.01)
