extends Node2D

func _ready() -> void:
	call_deferred("_go_to_main_menu")

func _go_to_main_menu() -> void:
	level_state.change_state(level_state.LevelStateEnum.MAIN_MENU)

func _process(_delta: float) -> void:
	pass
