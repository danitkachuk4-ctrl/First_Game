extends CanvasLayer

@onready var buy_armor_btn: BaseButton = $ColorRect/Buttons/Buy
@onready var buy_hp_btn: BaseButton = $ColorRect/Buttons/Buy2
@onready var buy_food_btn: BaseButton = $ColorRect/Buttons/Buy3
@onready var buy_damage_btn: BaseButton = $ColorRect/Buttons/Buy4
@onready var button_sound = $ButtonSound

func _ready():
	buy_armor_btn.pressed.connect(_on_buy_armor_pressed)
	buy_hp_btn.pressed.connect(_on_buy_hp_pressed)
	buy_food_btn.pressed.connect(_on_buy_food_pressed)
	buy_damage_btn.pressed.connect(_on_buy_damage_pressed)

func _on_buy_armor_pressed():
	button_sound.play()
	StatsGlobal.buy_armor()

func _on_buy_hp_pressed():
	button_sound.play()
	StatsGlobal.buy_max_health()

func _on_buy_food_pressed():
	button_sound.play()
	StatsGlobal.buy_food()

func _on_buy_damage_pressed():
	button_sound.play()
	StatsGlobal.buy_damage()
