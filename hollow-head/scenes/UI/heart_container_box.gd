extends HBoxContainer

var full_heart_container = preload("res://scenes/UI/full_heart_container.tscn")
var empty_heart_container = preload("res://scenes/UI/empty_heart_container.tscn")

func _ready() -> void:
	if not player_state.health_changed.is_connected(_on_health_changed):
		player_state.health_changed.connect(_on_health_changed)
	load_hearts()

func _exit_tree() -> void:
	if player_state.health_changed.is_connected(_on_health_changed):
		player_state.health_changed.disconnect(_on_health_changed)

func load_hearts() -> void:
	for child in get_children():
		child.queue_free()

	for i in range(player_state.max_health):
		var heart = full_heart_container.instantiate() if i < player_state.current_health else empty_heart_container.instantiate()
		add_child(heart)

func _on_health_changed(_current_health: int, _max_health: int) -> void:
	load_hearts()
