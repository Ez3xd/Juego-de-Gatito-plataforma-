extends Node2D

var total_coins: int = 0
var collected_coins: int = 0

@onready var coin_label: Label = $HUD/MarginContainer/VBoxContainer/HBoxContainer/CoinLabel
@onready var status_label: Label = $HUD/MarginContainer/VBoxContainer/StatusLabel

func _ready() -> void:
	# Find all coins in the level
	var coins = get_tree().get_nodes_in_group("coins")
	total_coins = coins.size()
	for coin in coins:
		if coin.has_signal("collected"):
			coin.collected.connect(_on_coin_collected)
	_update_hud()

func _on_coin_collected() -> void:
	collected_coins += 1
	_update_hud()
	if collected_coins >= total_coins and total_coins > 0:
		status_label.text = "¡Todas las monedas recolectadas! 🎉 ¡Nivel superado!"
		status_label.modulate = Color(1.0, 0.9, 0.2)

func _update_hud() -> void:
	if coin_label:
		coin_label.text = "Monedas: %d / %d" % [collected_coins, total_coins]
