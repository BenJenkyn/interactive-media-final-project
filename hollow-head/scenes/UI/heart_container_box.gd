extends HBoxContainer

var full_heart_container = preload("res://scenes/UI/full_heart_container.tscn")
var empty_heart_container = preload("res://scenes/UI/empty_heart_container.tscn")
@export var heart_size: Vector2 = Vector2(32, 32)
@export_range(0.0, 0.1, 0.001) var viewport_margin_percent: float = 0.01

func _ready() -> void:
	if not player_state.health_changed.is_connected(_on_health_changed):
		player_state.health_changed.connect(_on_health_changed)
	if not get_viewport().size_changed.is_connected(_apply_viewport_margin):
		get_viewport().size_changed.connect(_apply_viewport_margin)
	_apply_viewport_margin()
	load_hearts()

func _exit_tree() -> void:
	if player_state.health_changed.is_connected(_on_health_changed):
		player_state.health_changed.disconnect(_on_health_changed)
	if get_viewport().size_changed.is_connected(_apply_viewport_margin):
		get_viewport().size_changed.disconnect(_apply_viewport_margin)

func load_hearts() -> void:
	for child in get_children():
		child.queue_free()

	for i in range(player_state.max_health):
		var heart = full_heart_container.instantiate() if i < player_state.current_health else empty_heart_container.instantiate()
		if heart is TextureRect:
			heart.custom_minimum_size = heart_size
			heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(heart)

func _on_health_changed(_current_health: int, _max_health: int) -> void:
	load_hearts()

func _apply_viewport_margin() -> void:
	var viewport_size = get_viewport_rect().size
	position = viewport_size * viewport_margin_percent
