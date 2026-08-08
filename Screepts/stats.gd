extends CanvasLayer

@onready var health_bar = $HealthBar

func _ready():
	health_bar.max_value = StatsGlobal.max_health
	health_bar.value = StatsGlobal.health

	if not StatsGlobal.health_changed.is_connected(_on_health_changed):
		StatsGlobal.health_changed.connect(_on_health_changed)

	if not StatsGlobal.max_health_changed.is_connected(_on_max_health_changed):
		StatsGlobal.max_health_changed.connect(_on_max_health_changed)

func _on_health_changed(new_health):
	health_bar.value = new_health

func _on_max_health_changed(new_max_health):
	health_bar.max_value = new_max_health
