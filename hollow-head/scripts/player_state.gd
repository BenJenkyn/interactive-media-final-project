extends Node

signal health_changed(current_health: int, max_health: int)
signal player_died

var base_max_health: int = 5
var max_health: int = 5
var current_health: int = 5

var throw_unlocked: bool = false
var dodge_unlocked: bool = false

var move_speed_bonus: float = 0.0
var attack_damage_bonus: int = 0

var victory_count: int = 0

func reset_run(reset_victories: bool = false) -> void:
	max_health = base_max_health
	current_health = max_health
	throw_unlocked = false
	dodge_unlocked = false
	move_speed_bonus = 0.0
	attack_damage_bonus = 0
	if reset_victories:
		victory_count = 0
	health_changed.emit(current_health, max_health)

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

func add_victory() -> void:
	victory_count += 1

func unlock_throw() -> void:
	throw_unlocked = true

func unlock_dodge() -> void:
	dodge_unlocked = true

func add_max_health(amount: int) -> void:
	if amount <= 0:
		return

	max_health += amount
	current_health += amount
	health_changed.emit(current_health, max_health)

func add_move_speed(amount: float) -> void:
	move_speed_bonus += amount

func add_attack_damage(amount: int) -> void:
	attack_damage_bonus += amount
