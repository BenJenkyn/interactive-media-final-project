extends Node

signal health_changed(current_health: int, max_health: int)
signal player_died

var max_health := 5
var current_health = max_health
var throw_unlocked := false
var victory_count := 0

func reset_health() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

func apply_damage(amount: int) -> void:
	if amount <= 0:
		return

	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		player_died.emit()

func add_victory():
	victory_count += 1
