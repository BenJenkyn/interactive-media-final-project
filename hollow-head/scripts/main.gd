extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	level_state.change_state(level_state.LevelStateEnum.MAIN_MENU)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
