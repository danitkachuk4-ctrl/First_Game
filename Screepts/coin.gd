extends CharacterBody2D

@onready var coin_sound: AudioStreamPlayer = $CoinSound


var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.x = 0
	move_and_slide()

func _ready():
	var tween = get_tree().create_tween()
	tween.parallel().tween_property(self, "velocity", Vector2(randi_range(-80, 80), -150), 0.3)

func _on_detector_body_entered(body: Node2D) -> void:
	var tween = get_tree().create_tween()
	tween.parallel().tween_property(self, "velocity", Vector2(0, -150), 0.3)
	tween.parallel().tween_property(self, "modulate:a", 0, 0.5)
	coin_sound.play()
	await get_tree().create_timer(0.55).timeout
	StatsGlobal.coin += 1
	queue_free()
