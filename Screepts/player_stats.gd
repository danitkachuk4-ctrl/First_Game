extends Node

signal health_changed(new_health)

var max_health = 100

var health = 100:
	set(value):
		health = clamp(value, 0, max_health)
		health_changed.emit(health)

var gold = 0
