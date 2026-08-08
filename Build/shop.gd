extends Area2D

@onready var label: Label = $CollisionShape2D/Label
@onready var open_sound: AudioStreamPlayer = $OpenSound


var player_inside = false
var shop_menu_scene = preload("res://Build/shop_menu.tscn")
var shop_menu_instance = null

func _ready():
	label.visible = false

func _process(_delta):
	if player_inside and Input.is_action_just_pressed("openshop"):
		toggle_shop()

func toggle_shop():
	if shop_menu_instance == null:
		open_shop()
	else:
		open_sound.play()
		close_shop()

func open_shop():
	open_sound.play()
	shop_menu_instance = shop_menu_scene.instantiate()
	get_tree().root.add_child(shop_menu_instance)
	label.visible = false

func close_shop():
	if shop_menu_instance != null:
		shop_menu_instance.queue_free()
		shop_menu_instance = null
	if player_inside:
		label.visible = true

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_inside = true
		if shop_menu_instance == null:
			label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_inside = false
		label.visible = false
		close_shop()
