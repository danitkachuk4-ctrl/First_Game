extends Node2D

var coin_preload = preload("res://scens/coin.tscn")

func _ready():
	Signals.enemy_died.connect(_on_enemy_died)

func _on_enemy_died(enemy_position, min_coins, max_coins):
	var coins_count = randi_range(min_coins, max_coins)


	for i in coins_count:
		var coin = coin_preload.instantiate()
		add_child(coin)
		coin.global_position = enemy_position
		
