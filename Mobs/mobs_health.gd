extends Node2D

signal no_health
signal damage_received

@onready var damage_text = $DamageText
@export var max_health = 100

var health = 100
var text_tween

func _ready():
	damage_text.visible = false
	health = max_health

func take_damage(player_damage):
	health -= player_damage

	show_damage_text(player_damage)

	if health <= 0:
		no_health.emit()
	else:
		damage_received.emit()

func show_damage_text(damage):
	if text_tween:
		text_tween.kill()

	damage_text.text = "-" + str(damage)
	damage_text.visible = true
	damage_text.modulate.a = 1.0

	damage_text.position = Vector2(
		randf_range(-50, 50),
		randf_range(-45, -25)
	)

	text_tween = create_tween()
	text_tween.parallel().tween_property(damage_text, "position:y", damage_text.position.y - 35, 0.7)
	text_tween.parallel().tween_property(damage_text, "modulate:a", 0.0, 0.7)

	await text_tween.finished
	damage_text.visible = false
