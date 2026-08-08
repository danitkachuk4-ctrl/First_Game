extends Node2D

@onready var play_sprite = $Play/CatWalk
@onready var quit_sprite = $Quit/CatHiss
@onready var load_sprite = $Load/Caat
@onready var button_sound = $ButtonSound

var transitioning = false

func _ready():
	$Load.disabled = not SaveSystem.has_save()

func _on_play_pressed():
	if transitioning:
		return
	transitioning = true
	button_sound.play()
	await button_sound.finished
	SaveSystem.delete_save()
	get_tree().change_scene_to_file("res://scens/world.tscn")

func _on_load_pressed():
	if transitioning:
		return
	if SaveSystem.has_save():
		transitioning = true
		button_sound.play()
		await button_sound.finished
		get_tree().change_scene_to_file("res://scens/world.tscn")

func _on_quit_pressed() -> void:
	if transitioning:
		return
	transitioning = true
	button_sound.play()
	await button_sound.finished
	Engine.get_main_loop().quit()

func _on_play_mouse_entered():
	play_sprite.play()

func _on_play_mouse_exited():
	play_sprite.stop()
	play_sprite.frame = 0

func _on_load_mouse_entered():
	if SaveSystem.has_save():
		load_sprite.play()

func _on_load_mouse_exited():
	load_sprite.stop()
	load_sprite.frame = 0

func _on_quit_mouse_entered():
	quit_sprite.play()

func _on_quit_mouse_exited():
	quit_sprite.stop()
	quit_sprite.frame = 0
