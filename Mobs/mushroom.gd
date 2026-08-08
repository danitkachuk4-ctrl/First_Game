extends CharacterBody2D

enum {
	SPAWN,
	IDLE,
	CHASE,
	ATTACK,
	DAMAGE,
	DEATH,
	RECOVER
}

@export var speed: float = 100.0
@export var damage: int = 20
@export var attack_distance: float = 45.0
@export var min_coins: int = 3
@export var max_coins: int = 5
@export var blood_scene: PackedScene

@onready var animPlayer = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
@onready var detector = $AttackDirection/AttackRange



var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var player_pos: Vector2 = Vector2.ZERO
var has_player_pos := false
var direction: Vector2 = Vector2.ZERO
var _state_changed := false
var is_dead := false
var is_spawning := false

var state: int = IDLE:
	set(value):
		_state_changed = true
		state = value
		match state:
			SPAWN:
				spawn_state()
			IDLE:
				idle_state()
			CHASE:
				pass
			ATTACK:
				attack_state()
			DAMAGE:
				damage_state()
			DEATH:
				death_state()
			RECOVER:
				recover_state()

func _ready():
	Signals.connect("player_position_update", Callable(self, "_on_player_position_update"))
	sprite.modulate.a = 0.0
	state = SPAWN

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	if state == CHASE:
		chase_state()

	move_and_slide()

func _on_player_position_update(pos):
	player_pos = pos
	has_player_pos = true

func player_is_close() -> bool:
	return abs(player_pos.x - global_position.x) <= attack_distance

func spawn_state():
	velocity.x = 0
	sprite.modulate.a = 0.0
	animPlayer.play("Spawn")
	_state_changed = false
	await animPlayer.animation_finished
	if not _state_changed:
		sprite.modulate.a = 1.0
		state = CHASE

func idle_state():
	velocity.x = 0
	animPlayer.play("Idle")

func chase_state():
	if not has_player_pos:
		velocity.x = 0
		animPlayer.play("Idle")
		return

	direction = (player_pos - global_position).normalized()

	if direction.x < 0:
		sprite.flip_h = true
		detector.rotation_degrees = 180
	else:
		sprite.flip_h = false
		detector.rotation_degrees = 0

	if player_is_close():
		velocity.x = 0
		state = ATTACK
		return

	velocity.x = direction.x * speed
	animPlayer.play("Run")

func spawn_blood():
	if blood_scene == null:
		return
	var new_blood = blood_scene.instantiate()
	get_parent().add_child(new_blood)
	new_blood.global_position = global_position
	if player_pos.x < global_position.x:
		new_blood.scale.x = -1.0
	else:
		new_blood.scale.x = 1.0
		new_blood.process_material.spread = randf_range(15.0, 40.0)
		new_blood.process_material.gravity = Vector3(0.0, randf_range(100.0, 200.0), 0.0)
	new_blood.restart()
	await get_tree().create_timer(2.0).timeout
	new_blood.queue_free()

func attack_state():
	velocity.x = 0
	animPlayer.play("Attack")
	_state_changed = false

	await animPlayer.animation_finished

	if not _state_changed:
		state = RECOVER

func recover_state():
	velocity.x = 0
	animPlayer.play("Recover")
	_state_changed = false

	await animPlayer.animation_finished

	if not _state_changed:
		state = CHASE

func damage_state():
	velocity.x = 0
	spawn_blood()
	animPlayer.play("TakeHit", -1, true)
	_state_changed = false
	await animPlayer.animation_finished
	if not _state_changed:
		state = CHASE

func death_state():
	velocity.x = 0
	animPlayer.play("Death")
	await animPlayer.animation_finished
	Signals.enemy_died.emit(global_position, min_coins, max_coins)
	queue_free()

func _on_hit_box_area_entered(_area: Area2D) -> void:
	if state == SPAWN or state == DEATH:
		return

	Signals.emit_signal("enemy_attack", damage, self)

func _on_mobs_health_no_health() -> void:
	if is_dead:
		return

	is_dead = true
	state = DEATH

func _on_mobs_health_damage_received() -> void:
	if is_dead or state == SPAWN:
		return
	if state == DAMAGE:
		spawn_blood()
		animPlayer.call_deferred("stop")
		animPlayer.call_deferred("play", "TakeHit", -1, true)
	else:
		set_deferred("state", DAMAGE)
