extends HBoxContainer

var full_heart_container = preload("res://scenes/UI/full_heart_container.tscn")
var empty_heart_container = preload("res://scenes/UI/empty_heart_container.tscn")

var last_health: int = -1
var last_max_health: int = -1

func _ready() -> void:
	load_hearts()

func _process(_delta: float) -> void:
	if player_state.current_health != last_health or player_state.max_health != last_max_health:
		load_hearts()

func load_hearts() -> void:
	last_health = player_state.current_health
	last_max_health = player_state.max_health

	for child in get_children():
		child.queue_free()

	for i in range(player_state.max_health):
		var heart = full_heart_container.instantiate() if i < player_state.current_health else empty_heart_container.instantiate()
		add_child(heart)
