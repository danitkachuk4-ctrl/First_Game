extends PointLight2D

@onready var timer: Timer = $Timer

var day_state = 0
var current_tween

func _ready() -> void:
	Signals.connect("day_time", Callable(self, "_on_time_changed"))
	energy = 0
	timer.stop()

func _on_timer_timeout() -> void:
	if day_state == 1:
		var rng = randf_range(0.8, 1.2)
		if current_tween:
			current_tween.kill()
		current_tween = get_tree().create_tween()
		current_tween.parallel().tween_property(self, "texture_scale", rng, timer.wait_time)
		current_tween.parallel().tween_property(self, "energy", rng, timer.wait_time)
		timer.wait_time = randf_range(0.4, 0.8)

func _on_time_changed(state):
	day_state = state
	if state == 0:
		timer.stop()
		light_off()
	elif state == 1:
		light_on()

func light_on():
	if current_tween:
		current_tween.kill()
	current_tween = get_tree().create_tween()
	current_tween.tween_property(self, "energy", 1.5, randf_range(3, 6))
	await current_tween.finished
	timer.start()

func light_off():
	timer.stop()
	if current_tween:
		current_tween.kill()
	current_tween = get_tree().create_tween()
	current_tween.tween_property(self, "energy", 0, randf_range(3, 6))
