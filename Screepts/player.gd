extends CharacterBody2D

signal player_died

enum{
	MOVE,
	ATTACK,
	ATTACK2,
	ATTACK3,
	BLOCK,
	SLIDE,
	DAMAGE,
	DEATH
}

const SPEED = 200.0
const JUMP_VELOCITY = -350.0
const SLIDE_SPEED = 300.0
const RUN_SLIDE_SPEED = 600.0

var damage_basic = 10
var damage_multiplier = 1
var damage_current 
var is_damaged = false
var player_pos
var state = MOVE
var is_sliding = false
var is_attacking = false
var next_attack = false
var combo = false
var attack_cooldown = false
var is_dead = false
var current_slide_speed = SLIDE_SPEED
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim = $AnimatedSprite2D
@onready var animPlayer = $AnimationPlayer
@onready var leafs: GPUParticles2D = $Leafs
@onready var col_shape = $CollisionShape2D
@onready var blood = $BLOOD
@onready var fall_sound: AudioStreamPlayer = $Sounds/Fall
@onready var eat: AudioStreamPlayer = $Sounds/Eat
@onready var healing: AudioStreamPlayer = $Sounds/Healing



var last_direction = 1
var facing_direction = 1
var is_turning = false
var col_offset_x = 0.0
var was_in_air: bool = false

func _ready():
	Signals.connect("enemy_attack", Callable(self, "_on_damage_recived"))
	col_offset_x = col_shape.position.x

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	damage_current = StatsGlobal.player_damage * damage_multiplier

	match state:
		MOVE:
			move_state(delta)
		ATTACK:
			attack_state()
		ATTACK2:
			attack2_state()
		ATTACK3:
			attack3_state()
		BLOCK:
			block_state()
		SLIDE:
			slide_state()
		DAMAGE:
			damage_state()
		DEATH:
			death_state()

	if StatsGlobal.health <= 0 and state != DEATH:
		StatsGlobal.health = 0
		state = DEATH

	if Input.is_action_just_pressed("use_food"):
		if StatsGlobal.use_food():
			eat.play()
			healing.play()
	
	move_and_slide()

	player_pos = self.position
	Signals.emit_signal("player_position_update", player_pos)

func move_state(delta):
	var direction := Input.get_axis("left", "right")
	if Input.is_action_just_pressed("slide") and is_on_floor():
		if direction != 0:
			current_slide_speed = RUN_SLIDE_SPEED
		else:
			current_slide_speed = SLIDE_SPEED
		state = SLIDE
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	move_and_slide()
	
	if is_turning:
		velocity.x = 0
		return
	if direction != 0:
		if (direction > 0 and facing_direction < 0) or (direction < 0 and facing_direction > 0):
			is_turning = true
			facing_direction = direction
			last_direction = direction
			velocity.x = 0
			anim.flip_h = false
			animPlayer.play("Turn")
			await animPlayer.animation_finished
			anim.flip_h = direction < 0
			$AttackDirection.scale.x = 1 if direction > 0 else -1
			col_shape.position.x = -col_offset_x if direction < 0 else col_offset_x
			is_turning = false
			return
		last_direction = direction
		velocity.x = direction * SPEED
		anim.flip_h = direction < 0
		$AttackDirection.scale.x = 1 if direction > 0 else -1
		col_shape.position.x = -col_offset_x if direction < 0 else col_offset_x
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if not is_on_floor():
		was_in_air = true
		if velocity.y < 0:
			animPlayer.play("Jump")
		else:
			animPlayer.play("Fall")
		anim.flip_h = last_direction < 0
		col_shape.position.x = -col_offset_x if last_direction < 0 else col_offset_x
	elif direction != 0:
		if was_in_air:
			fall_sound.play()
			was_in_air = false
		animPlayer.play("Run")
	else:
		if was_in_air:
			fall_sound.play()
			was_in_air = false
		animPlayer.play("Idle")
	if Input.is_action_just_pressed("attack") and is_on_floor() and attack_cooldown == false:
		state = ATTACK
	if Input.is_action_pressed("block") and is_on_floor():
		state = BLOCK

func block_state():
	if not is_on_floor():
		state = MOVE
		return

	velocity.x = 0
	velocity.y = 0
	animPlayer.play("Block")

	var direction := Input.get_axis("left", "right")

	if direction < 0:
		anim.flip_h = true
		col_shape.position.x = -col_offset_x
	elif direction > 0:
		anim.flip_h = false
		col_shape.position.x = col_offset_x

	if Input.is_action_just_released("block"):
		state = MOVE

func slide_state():
	if is_sliding:
		return

	is_sliding = true
	anim.flip_h = last_direction < 0
	$AttackDirection.scale.x = 1 if last_direction > 0 else -1
	col_shape.position.x = -col_offset_x if last_direction < 0 else col_offset_x
	animPlayer.play("Slide")

	if last_direction < 0:
		velocity.x = -current_slide_speed
	else:
		velocity.x = current_slide_speed

	await animPlayer.animation_finished

	velocity.x = 0
	is_sliding = false
	state = MOVE

func attack_state():
	damage_multiplier = 1
	if is_attacking:
		if Input.is_action_just_pressed("attack") and combo == true:
			next_attack = true
		return

	is_attacking = true
	next_attack = false
	combo = false
	velocity.x = 0
	animPlayer.play("Attack")

	await animPlayer.animation_finished
	attack_freeze()
	is_attacking = false
	combo = false

	if next_attack == true:
		next_attack = false
		state = ATTACK2
	else:
		state = MOVE

func attack2_state():
	damage_multiplier = 1.2
	if is_attacking:
		if Input.is_action_just_pressed("attack") and combo == true:
			next_attack = true
		return

	is_attacking = true
	next_attack = false
	combo = false
	velocity.x = 0
	animPlayer.play("Attack2")
	await animPlayer.animation_finished

	is_attacking = false
	combo = false

	if next_attack == true:
		next_attack = false
		state = ATTACK3
	else:
		state = MOVE

func attack3_state():
	damage_multiplier = 2
	if is_attacking:
		return

	is_attacking = true
	combo = false
	velocity.x = 0
	animPlayer.play("Attack3")

	await animPlayer.animation_finished

	is_attacking = false
	state = MOVE

func combo1():
	combo = true

func combo1_close():
	combo = false

func attack_freeze():
	attack_cooldown = true
	await get_tree().create_timer(0.3).timeout
	attack_cooldown = false


func spawn_blood():
	blood.scale.x = -1.0 if anim.flip_h else 1.0
	blood.process_material.spread = randf_range(15.0, 40.0)
	blood.process_material.gravity = Vector3(0.0, randf_range(100.0, 200.0), 0.0)
	blood.restart()

var knockback_direction = 0

func damage_state():
	if is_damaged:
		return
		
	is_damaged = true

	if is_attacking:
		is_attacking = false

	velocity.x = 0
	if knockback_direction > 0:
		velocity.x += 100
	else:
		velocity.x -= 100
	col_shape.position.x = -col_offset_x if $AnimatedSprite2D.flip_h else col_offset_x
	animPlayer.play("Damage")
	await animPlayer.animation_finished

	is_damaged = false
	if StatsGlobal.health > 0:
		state = MOVE

func _on_damage_recived(enemy_damage, attacker = null):
	if is_dead:
		return
	var is_blue_witch = attacker != null and attacker.name == "BlueWitch"
	if state == SLIDE:
		if is_blue_witch:
			state = DAMAGE
		else:
			enemy_damage = 0
	elif state == BLOCK:
		enemy_damage /= 2
		state = DAMAGE
	else:
		state = DAMAGE
	if enemy_damage <= 0:
		return
	if attacker != null:
		knockback_direction = 1 if global_position.x > attacker.global_position.x else -1
	else:
		knockback_direction = -1 if $AnimatedSprite2D.flip_h else 1
	var damage_reduction = clamp(StatsGlobal.armor * 0.01, 0.0, 0.9)
	var final_damage = enemy_damage * (1.0 - damage_reduction)
	StatsGlobal.health -= final_damage

	

func death_state():
	if is_dead:
		return

	is_dead = true
	velocity.x = 0
	animPlayer.play("Death")

	emit_signal("player_died")

	await animPlayer.animation_finished

func _on_hit_box_area_entered(area: Area2D) -> void:
	var node = area

	while node != null:
		if node.has_node("MobsHealth"):
			node.get_node("MobsHealth").take_damage(damage_current)
			return

		node = node.get_parent()

func steps():
	leafs.emitting = true
	leafs.one_shot = true
