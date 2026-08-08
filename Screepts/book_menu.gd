extends CanvasLayer

@onready var book_button = $BookButton
@onready var menu_root = $MenuRoot
@onready var book_anim = $MenuRoot/BookAnim
@onready var main_buttons = $MenuRoot/MainButtons
@onready var settings_page = $MenuRoot/SettingsPage
@onready var credits_page = $MenuRoot/CreditsPage
@onready var resume_button = $MenuRoot/MainButtons/Resume
@onready var settings_button = $MenuRoot/MainButtons/Settings
@onready var credits_button = $MenuRoot/MainButtons/Credits
@onready var quit_button = $MenuRoot/MainButtons/Quit
@onready var settings_back_button = $MenuRoot/SettingsPage/Back
@onready var credits_back_button = $MenuRoot/CreditsPage/Back
@onready var book_audio: AudioStreamPlayer = $BookAudio
@onready var book_close_audio: AudioStreamPlayer = $BookClose
@onready var book_click: AudioStreamPlayer = $BookClick
@onready var music_slider = $MenuRoot/SettingsPage/Music
@onready var sfx_slider = $MenuRoot/SettingsPage/Game

var menu_open := false
var changing_page := false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	menu_root.process_mode = Node.PROCESS_MODE_ALWAYS
	book_button.process_mode = Node.PROCESS_MODE_ALWAYS
	book_anim.process_mode = Node.PROCESS_MODE_ALWAYS
	main_buttons.process_mode = Node.PROCESS_MODE_ALWAYS
	settings_page.process_mode = Node.PROCESS_MODE_ALWAYS
	credits_page.process_mode = Node.PROCESS_MODE_ALWAYS
	book_audio.process_mode = Node.PROCESS_MODE_ALWAYS
	book_close_audio.process_mode = Node.PROCESS_MODE_ALWAYS
	book_click.process_mode = Node.PROCESS_MODE_ALWAYS
	book_button.pressed.connect(_on_book_button_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_back_button.pressed.connect(_on_back_to_main_pressed)
	credits_back_button.pressed.connect(_on_back_to_main_pressed)
	menu_root.visible = false
	main_buttons.visible = false
	settings_page.visible = false
	credits_page.visible = false
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.01
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.01
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Game")))
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)

func _on_music_slider_changed(value: float):
	var bus_idx = AudioServer.get_bus_index("Music")
	if value <= 0.0:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	SaveSystem.save_settings()

func _on_sfx_slider_changed(value: float):
	var bus_idx = AudioServer.get_bus_index("Game")
	if value <= 0.0:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	SaveSystem.save_settings()

func play_book_open_sounds():
	await get_tree().create_timer(0.04).timeout
	book_close_audio.play()
	await get_tree().create_timer(0.3234).timeout
	book_audio.play()
	await get_tree().create_timer(0.3318).timeout
	book_audio.play()
	await get_tree().create_timer(0.3329).timeout
	book_audio.play()

func play_book_close_sounds():
	await get_tree().create_timer(0.0806).timeout
	book_audio.play()
	await get_tree().create_timer(0.3321).timeout
	book_audio.play()
	await get_tree().create_timer(0.3316).timeout
	book_audio.play()
	await get_tree().create_timer(0.389).timeout
	book_close_audio.play()

func _on_book_button_pressed():
	if changing_page:
		return
	if menu_open:
		await close_book(false)
		return
	menu_open = true
	changing_page = true
	get_tree().paused = true
	menu_root.visible = true
	main_buttons.visible = false
	settings_page.visible = false
	credits_page.visible = false
	book_anim.stop()
	book_anim.frame = 0
	play_book_open_sounds()
	book_anim.play("BookOpen")
	await book_anim.animation_finished
	main_buttons.visible = true
	changing_page = false

func _on_resume_pressed():
	if changing_page:
		return
	book_click.play()
	await close_book(false)

func _on_quit_pressed():
	if changing_page:
		return
	book_click.play()
	await close_book(true)

func _on_settings_pressed():
	if changing_page:
		return
	changing_page = true
	book_click.play()
	main_buttons.visible = false
	settings_page.visible = false
	credits_page.visible = false
	book_audio.play()
	book_anim.play("PageFlip")
	await book_anim.animation_finished
	settings_page.visible = true
	changing_page = false

func _on_credits_pressed():
	if changing_page:
		return
	changing_page = true
	book_click.play()
	main_buttons.visible = false
	settings_page.visible = false
	credits_page.visible = false
	book_audio.play()
	book_anim.play("PageFlip")
	await book_anim.animation_finished
	credits_page.visible = true
	changing_page = false

func _on_back_to_main_pressed():
	if changing_page:
		return
	changing_page = true
	book_click.play()
	main_buttons.visible = false
	settings_page.visible = false
	credits_page.visible = false
	book_audio.play()
	book_anim.play("PageFlip")
	await book_anim.animation_finished
	main_buttons.visible = true
	changing_page = false

func close_book(go_to_menu: bool):
	changing_page = true
	main_buttons.visible = false
	settings_page.visible = false
	credits_page.visible = false
	play_book_close_sounds()
	book_anim.play("BookClose")
	await book_anim.animation_finished
	menu_root.visible = false
	menu_open = false
	changing_page = false
	get_tree().paused = false
	if go_to_menu:
		get_tree().change_scene_to_file("res://scens/menu.tscn")
