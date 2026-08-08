extends Node2D

@onready var light = $Light/Sun
@onready var day_text = $"CanvasLayer/Day text"
@onready var player = $Player/Player
@onready var day_night_anim = $Light/DayNight2
@onready var spawn_timer = $Mobs/Timer
@onready var save_icon = $CanvasLayer/SaveIcon

@export var mobs_spawner: PackedScene
@export var mob_mushroom: PackedScene
@export var mob_skeleton: PackedScene
@export var mob_blue_witch: PackedScene
@export var mob_red_witch: PackedScene
@export var mob_white_witch: PackedScene

enum { DAY, NIGHT }

var state = DAY
var day_count: int
var spawn_index: int = 0

func _ready():
	$Music.finished.connect(func(): $AudioStreamPlayer.play())
	save_icon.visible = false
	if SaveSystem.has_save():
		_load_game()
	else:
		_new_game()
	light.enabled = true
	Signals.emit_signal("day_time", state)

func _new_game():
	StatsGlobal.player_damage = 6
	StatsGlobal.coin = 0
	StatsGlobal.max_health = 100
	StatsGlobal.armor = 0
	StatsGlobal.food = 0
	StatsGlobal.health = 100
	StatsGlobal.max_health_changed.emit(100)
	StatsGlobal.resources_changed.emit()
	day_count = 1
	set_day_text()
	state = DAY
	day_state()
	$Light/DayNight.start()

func _load_game():
	var data = SaveSystem.load_game()
	if data.is_empty():
		_new_game()
		return
	StatsGlobal.player_damage = int(data["player_damage"])
	StatsGlobal.health = data["health"]
	StatsGlobal.max_health = int(data["max_health"])
	StatsGlobal.coin = int(data["coin"])
	StatsGlobal.food = int(data["food"])
	StatsGlobal.armor = int(data["armor"])
	StatsGlobal.max_health_changed.emit(StatsGlobal.max_health)
	StatsGlobal.resources_changed.emit()
	player.global_position = Vector2(data["player_x"], data["player_y"])
	day_count = int(data["day_count"])
	set_day_text()
	state = DAY
	day_state()
	$Light/DayNight.start()
	for mob_data in data["mobs"]:
		var mob_scene = load(mob_data["scene"])
		if mob_scene == null:
			continue
		var mob = mob_scene.instantiate()
		$Mobs.add_child(mob)
		mob.global_position = Vector2(mob_data["x"], mob_data["y"])

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_H:
		SaveSystem.save_game(self)
		_show_save_icon()

func _show_save_icon():
	save_icon.visible = true
	save_icon.modulate.a = 0.0
	save_icon.play("Save")
	var tween = create_tween()
	tween.tween_property(save_icon, "modulate:a", 197.0 / 255.0, 0.3)
	await get_tree().create_timer(1.0).timeout
	var tween2 = create_tween()
	tween2.tween_property(save_icon, "modulate:a", 0.0, 0.3)
	await tween2.finished
	save_icon.visible = false
	save_icon.stop()

func day_state():
	day_night_anim.play("SunRise")

func night_state():
	day_night_anim.play("SunSet")

func _on_day_night_timeout() -> void:
	match state:
		DAY:
			state = NIGHT
			night_state()
			Signals.emit_signal("day_time", state)
		NIGHT:
			state = DAY
			day_count += 1
			set_day_text()
			day_state()
			Signals.emit_signal("day_time", state)
			if day_count >= 5:
				spawn_timer.wait_time = max(1.0, spawn_timer.wait_time - 0.5)

func set_day_text():
	day_text.text = "DAY" + str(day_count)

func _on_timer_timeout() -> void:
	spawn()

func spawn():
	if mobs_spawner == null:
		return
	var available: Array = []
	if day_count >= 1:
		available.append(mob_mushroom)
	if day_count >= 2:
		available.append(mob_skeleton)
	if day_count >= 4:
		available.append(mob_blue_witch)
	if day_count >= 6:
		available.append(mob_red_witch)
	if day_count >= 8:
		available.append(mob_white_witch)
	if available.is_empty():
		return
	var mob_scene = available[spawn_index % available.size()]
	spawn_index += 1
	if mob_scene == null:
		return
	var portal = mobs_spawner.instantiate()
	portal.position = Vector2(randi_range(-3000, 3500), 420)
	portal.mob_scene = mob_scene
	$Mobs.add_child(portal)
