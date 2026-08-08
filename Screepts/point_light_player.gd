extends PointLight2D

var current_tween

func _ready() -> void:
	Signals.connect("day_time", Callable(self, "_on_time_changed"))
	energy = 0

func _on_time_changed(state):
	if state == 0:  # DAY
		light_off()
	elif state == 1:  # NIGHT
		light_on()

func light_on():
	if current_tween:
		current_tween.kill()
	current_tween = get_tree().create_tween()
	current_tween.tween_property(self, "energy", 1.5, 5.0)

func light_off():
	if current_tween:
		current_tween.kill()
	current_tween = get_tree().create_tween()
	current_tween.tween_property(self, "energy", 0.0, 5.0)
