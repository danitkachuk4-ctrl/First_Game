extends Node2D

@export var mob_scene: PackedScene
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var spawn_point: Marker2D = $Marker2D
@onready var portal_sound: AudioStreamPlayer2D = $PortalSound

func _ready() -> void:
	spawn_mob()

func spawn_mob() -> void:
	if mob_scene == null:
		return
	portal_sound.play()
	anim_player.play("PortalSpawn")
	await get_tree().create_timer(3.0).timeout
	var mob = mob_scene.instantiate()
	get_parent().add_child(mob)
	mob.global_position = spawn_point.global_position
	if mob.has_node("AnimatedSprite2D"):
		var mob_sprite: AnimatedSprite2D = mob.get_node("AnimatedSprite2D")
	await get_tree().create_timer(1.0).timeout
	anim_player.play("PortalClose")
	await anim_player.animation_finished
	queue_free()
