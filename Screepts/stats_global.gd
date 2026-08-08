extends Node

signal health_changed(new_health)
signal max_health_changed(new_max_health)
signal resources_changed

var coin = 0:
	set(value):
		coin = value
		resources_changed.emit()

var max_health = 100
var regen_amount = 2
var regen_time = 5.0
var armor = 0
var food = 0
var player_damage = 6

var health = 100:
	set(value):
		health = clamp(value, 0, max_health)
		health_changed.emit(health)

const UPGRADE_COST = 5
const FOOD_COST = 10
const ARMOR_PER_LEVEL = 1
const HP_PER_LEVEL = 5
const FOOD_HEAL_AMOUNT = 25
const DAMAGE_COST = 8
const DAMAGE_PER_LEVEL = 2
const MAX_DAMAGE = 50

func _ready():
	var regen_timer = Timer.new()
	regen_timer.wait_time = regen_time
	regen_timer.one_shot = false
	regen_timer.autostart = true
	regen_timer.timeout.connect(_on_regen_timer_timeout)
	add_child(regen_timer)

func _on_regen_timer_timeout():
	if health <= 0:
		return
	if health >= max_health:
		return
	health += regen_amount

# ====== ПОКУПКИ ======

func buy_armor() -> bool:
	if coin >= UPGRADE_COST:
		coin -= UPGRADE_COST
		armor += ARMOR_PER_LEVEL
		resources_changed.emit()
		return true
	return false

func buy_max_health() -> bool:
	if coin >= UPGRADE_COST:
		coin -= UPGRADE_COST
		max_health += HP_PER_LEVEL
		max_health_changed.emit(max_health)
		health += HP_PER_LEVEL
		resources_changed.emit()
		return true
	return false

func buy_food() -> bool:
	if coin >= FOOD_COST:
		coin -= FOOD_COST
		food += 1
		resources_changed.emit()
		return true
	return false

func buy_damage() -> bool:
	if coin >= DAMAGE_COST and player_damage < MAX_DAMAGE:
		coin -= DAMAGE_COST
		player_damage = min(player_damage + DAMAGE_PER_LEVEL, MAX_DAMAGE)
		resources_changed.emit()
		return true
	return false

# ====== ИСПОЛЬЗОВАНИЕ ЕДЫ ======

func use_food() -> bool:
	if food > 0 and health < max_health:
		food -= 1
		health += FOOD_HEAL_AMOUNT
		resources_changed.emit()
		return true
	return false

# ====== СБРОС ПРИ СМЕРТИ ======

const DEFAULT_MAX_HEALTH = 100
const DEFAULT_ARMOR = 0

func reset_on_death() -> void:
	max_health = DEFAULT_MAX_HEALTH
	armor = DEFAULT_ARMOR
	health = DEFAULT_MAX_HEALTH
	max_health_changed.emit(max_health)
	resources_changed.emit()
