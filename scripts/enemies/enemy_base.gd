class_name EnemyBase
extends CharacterBody3D

signal died(enemy: EnemyBase)
signal staggered(enemy: EnemyBase)

@export var max_health := 60.0
@export var move_speed := 3.4
@export var chase_speed := 5.6
@export var detection_range := 14.0
@export var attack_range := 1.9
@export var attack_damage := 10.0
@export var attack_cooldown := 1.4
@export var contact_knockback := 4.0

enum EnemyState { IDLE, CHASE, ATTACK, STAGGER, DEAD }
var state: EnemyState = EnemyState.IDLE
var health: float
var _attack_timer := 0.0
var _stagger_timer := 0.0
var _player: Node3D
var gravity := ProjectSettings.get_setting("physics/3d/default_gravity") as float

@onready var hurtbox: Hurtbox = get_node_or_null("Hurtbox") as Hurtbox
@onready var hitbox: Hitbox = get_node_or_null("Hitbox") as Hitbox

func _ready() -> void:
	health = max_health
	add_to_group("enemy")
	_player = get_tree().get_first_node_in_group("player")
	if hurtbox:
		hurtbox.owner_group = "enemy"
		hurtbox.hit_received.connect(_on_hurtbox_hit)

func _physics_process(delta: float) -> void:
	if state == EnemyState.DEAD:
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.1
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")

	match state:
		EnemyState.IDLE:
			_process_idle()
		EnemyState.CHASE:
			_process_chase(delta)
		EnemyState.ATTACK:
			_process_attack(delta)
		EnemyState.STAGGER:
			_process_stagger(delta)

	move_and_slide()
	_on_animate(delta)

func _distance_to_player() -> float:
	if _player == null:
		return INF
	return global_position.distance_to(_player.global_position)

func _process_idle() -> void:
	velocity.x = move_toward(velocity.x, 0.0, move_speed * 4.0)
	velocity.z = move_toward(velocity.z, 0.0, move_speed * 4.0)
	if _distance_to_player() <= detection_range:
		_enter_chase()

func _enter_chase() -> void:
	state = EnemyState.CHASE
	AudioManager.play_growl()

func _process_chase(delta: float) -> void:
	if _player == null:
		return
	var dist := _distance_to_player()
	if dist <= attack_range:
		state = EnemyState.ATTACK
		_attack_timer = 0.0
		return
	var dir := (_player.global_position - global_position)
	dir.y = 0
	dir = dir.normalized()
	velocity.x = move_toward(velocity.x, dir.x * chase_speed, chase_speed * 6.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z * chase_speed, chase_speed * 6.0 * delta)
	_face_direction(dir, delta)

func _process_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, chase_speed * 6.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, chase_speed * 6.0 * delta)
	if _player:
		var dir := (_player.global_position - global_position)
		dir.y = 0
		_face_direction(dir.normalized(), delta)
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_perform_attack()
		_attack_timer = attack_cooldown
	if _distance_to_player() > attack_range * 1.3:
		state = EnemyState.CHASE

func _perform_attack() -> void:
	AudioManager.play_growl()
	if hitbox:
		hitbox.activate()
		get_tree().create_timer(0.22).timeout.connect(func():
			if is_instance_valid(hitbox):
				hitbox.deactivate())

func _process_stagger(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, move_speed * 8.0 * delta)
	_stagger_timer -= delta
	if _stagger_timer <= 0.0:
		state = EnemyState.CHASE

func _face_direction(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.05:
		return
	var target_y := atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_y, delta * 8.0)

func _on_hurtbox_hit(damage: float, knockback: Vector3, _source: Node) -> void:
	if state == EnemyState.DEAD:
		return
	health -= damage
	velocity += knockback
	AudioManager.play_hit()
	ScreenEffects.request_shake(0.15, 0.1)
	if health <= 0.0:
		_die()
	else:
		state = EnemyState.STAGGER
		_stagger_timer = 0.35
		staggered.emit(self)

func _die() -> void:
	state = EnemyState.DEAD
	if hurtbox:
		hurtbox.monitorable = false
	AudioManager.play_death()
	died.emit(self)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.9).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(queue_free)

## Overridable hook for subclasses to add procedural animation (leg swing, etc).
func _on_animate(_delta: float) -> void:
	pass
