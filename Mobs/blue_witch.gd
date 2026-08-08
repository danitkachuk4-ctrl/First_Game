extends CharacterBody2D

enum {
	IDLE,
	CHASE,
	ATTACK,
	DAMAGE,
	DEATH
}

@export var speed: float = 90.0
@export var damage: int = 25
@export var attack_distance: float = 60.0
@export var min_coins: int = 3
@export var max_coins: int = 6
@export var blood_scene: PackedScene

@onready var animPlayer = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
@onready var attackDirection = $AttackDirection
@onready var detector = $AttackDirection/AttackRange
@onready var blue_sparks = $BlueSparks

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var player_pos: Vector2 = Vector2.ZERO
var has_player_pos := false
var direction: Vector2 = Vector2.ZERO
var _state_changed := false
var is_dead := false
var facing_right := true

var state: int = IDLE:
	set(value):
		_state_changed = true
		state = value
		match state:
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

func _ready():
	Signals.connect("player_position_update", Callable(self, "_on_player_position_update"))
	state = CHASE

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

func set_facing(right: bool):
	facing_right = right
	if right:
		sprite.flip_h = false
		attackDirection.scale.x = 1
	else:
		sprite.flip_h = true
		attackDirection.scale.x = -1

func idle_state():
	velocity.x = 0
	sprite.flip_h = !facing_right
	animPlayer.play("Idle")

func chase_state():
	if not has_player_pos:
		velocity.x = 0
		sprite.flip_h = !facing_right
		animPlayer.play("Idle")
		return
	direction = (player_pos - global_position).normalized()
	set_facing(direction.x >= 0)
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

func spawn_blue_sparks():
	if facing_right:
		blue_sparks.position.x = abs(blue_sparks.position.x)
	else:
		blue_sparks.position.x = -abs(blue_sparks.position.x)
	blue_sparks.restart()

func attack_state():
	velocity.x = 0
	sprite.flip_h = !facing_right
	animPlayer.play("Charge")
	_state_changed = false
	await animPlayer.animation_finished
	if _state_changed:
		return
	if facing_right:
		sprite.flip_h = false
		animPlayer.play("Attack")
	else:
		sprite.flip_h = false
		animPlayer.play("AttackLeft")
	_state_changed = false
	await animPlayer.animation_finished
	if not _state_changed:
		state = CHASE

func damage_state():
	velocity.x = 0
	spawn_blood()
	sprite.flip_h = !facing_right
	animPlayer.call_deferred("play", "Hit")
	_state_changed = false
	await animPlayer.animation_finished
	if not _state_changed:
		state = CHASE

func death_state():
	velocity.x = 0
	sprite.flip_h = !facing_right
	animPlayer.play("Death")
	await animPlayer.animation_finished
	Signals.enemy_died.emit(global_position, min_coins, max_coins)
	queue_free()

func _on_hit_box_area_entered(_area: Area2D) -> void:
	if state == DEATH:
		return
	Signals.emit_signal("enemy_attack", damage, self)

func _on_attack_range_body_entered(body: Node2D) -> void:
	pass

func _on_attack_range_body_exited(body: Node2D) -> void:
	pass

func _on_mobs_health_no_health() -> void:
	if is_dead:
		return
	is_dead = true
	state = DEATH

func _on_mobs_health_damage_received() -> void:
	if is_dead:
		return
	if state == DAMAGE:
		spawn_blood()
		animPlayer.call_deferred("stop")
		animPlayer.call_deferred("play", "Hit")
	else:
		set_deferred("state", DAMAGE)
