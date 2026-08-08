extends Node

const SAVE_PATH = "user://savegame.json"
const SETTINGS_PATH = "user://settings.json"

func _ready():
	load_settings()

func save_game(world: Node) -> void:
	var player = world.get_node("Player/Player")
	var mobs_node = world.get_node("Mobs")
	
	var mobs_data = []
	for mob in mobs_node.get_children():
		if not mob is CharacterBody2D:
			continue
		mobs_data.append({
			"scene": mob.scene_file_path,
			"x": mob.global_position.x,
			"y": mob.global_position.y
		})
	
	var data = {
		"player_x": player.global_position.x,
		"player_y": player.global_position.y,
		"health": StatsGlobal.health,
		"max_health": StatsGlobal.max_health,
		"coin": StatsGlobal.coin,
		"food": StatsGlobal.food,
		"armor": StatsGlobal.armor,
		"player_damage": StatsGlobal.player_damage,
		"day_count": world.day_count,
		"mobs": mobs_data
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	
	save_settings()

func save_settings() -> void:
	var settings = {
		"music_volume": AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")),
		"game_volume": AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Game")),
	}
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(settings))
	file.close()

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data == null:
		return
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), data["music_volume"])
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Game"), data["game_volume"])

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	return data if data else {}

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
