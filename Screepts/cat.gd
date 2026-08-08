extends CharacterBody2D

enum {
	IDLE,
	RUN,
	HISS,
	DEATH
}

@export var player: Node2D
@export var follow_distance = 80.0
@export var speed = 180.0

@onready var anim = $AnimatedSprite2D
@onready var hiss_area: Area2D = $HissArea2D
@onready var hiss_sound: AudioStreamPlayer2D = $HissSound
@onready var run_sound: AudioStreamPlayer2D = $RunSound

var state = IDLE
var is_hissing = false

func _ready():
	hiss_area.body_entered.connect(_on_hiss_area_body_entered)
	hiss_area.area_entered.connect(_on_hiss_area_area_entered)
	if player != null:
		player.player_died.connect(_on_player_died)

func _physics_process(delta):
	if player == null:
		return
	if state == HISS or state == DEATH:
		move_and_slide()
		return
	var distance = global_position.distance_to(player.global_position)
	if distance > follow_distance:
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * speed
		anim.flip_h = direction.x < 0
		anim.play("Run")
		if not run_sound.playing:
			run_sound.play()
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		anim.play("Idle")
		if run_sound.playing:
			run_sound.stop()
	move_and_slide()

func hiss_once(target: Node2D):
	is_hissing = true
	state = HISS
	velocity.x = 0
	if target.global_position.x < global_position.x:
		anim.flip_h = true
	else:
		anim.flip_h = false
	anim.play("Hiss")
	hiss_sound.play()
	await anim.animation_finished
	is_hissing = false
	state = IDLE

func _on_hiss_area_body_entered(body):
	check_mob(body)

func _on_hiss_area_area_entered(area):
	check_mob(area)

func check_mob(start_node):
	if is_hissing:
		return
	var node = start_node
	while node != null:
		if node.is_in_group("mobs") or node.is_in_group("Mobs"):
			hiss_once(node)
			return
		node = node.get_parent()

func _on_player_died():
	is_hissing = false
	state = DEATH
	velocity = Vector2.ZERO
	run_sound.stop()
	anim.play("Death")
	await anim.animation_finished
	get_tree().change_scene_to_file("res://scens/menu.tscn")
