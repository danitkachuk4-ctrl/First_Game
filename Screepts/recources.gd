extends CanvasLayer

@onready var gold_text: Label = $Control/PanelContainer/HBoxContainer/CoinText
@onready var food_text: Label = $Control/PanelContainer/HBoxContainer/FoodText
@onready var armor_text: Label = $Control/PanelContainer/HBoxContainer/ArmorText
@onready var max_health_text: Label = $Control/PanelContainer/HBoxContainer/MaxHealthText
@onready var damage_text: Label = $Control/PanelContainer/HBoxContainer/DamageText
@onready var buy_sound: AudioStreamPlayer = $BuySound

var prev_damage: int = 0
var prev_armor: int = 0
var prev_max_health: int = 0
var prev_food: int = 0

func _ready():
	prev_armor = StatsGlobal.armor
	prev_max_health = StatsGlobal.max_health
	prev_food = StatsGlobal.food
	prev_damage = StatsGlobal.player_damage
	_update_labels()
	StatsGlobal.resources_changed.connect(_update_labels)

func _update_labels():
	gold_text.text = str(StatsGlobal.coin)
	food_text.text = str(StatsGlobal.food)
	armor_text.text = str(StatsGlobal.armor)
	damage_text.text = str(StatsGlobal.player_damage)
	max_health_text.text = str(StatsGlobal.max_health)

	if StatsGlobal.armor > prev_armor or \
	   StatsGlobal.max_health > prev_max_health or \
	   StatsGlobal.food > prev_food or \
	   StatsGlobal.player_damage > prev_damage:
		buy_sound.play()

	prev_armor = StatsGlobal.armor
	prev_max_health = StatsGlobal.max_health
	prev_food = StatsGlobal.food
	prev_damage = StatsGlobal.player_damage
