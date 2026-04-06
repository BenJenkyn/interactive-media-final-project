extends Node2D

enum LevelStateEnum {
	MAIN_MENU,
	LEVEL1,
	UPGRADE_BETWEEN_1_2,
	LEVEL2,
	UPGRADE_BETWEEN_2_3,
	LEVEL3,
	VICTORY_SCREEN
}

var current_level_state: LevelStateEnum = LevelStateEnum.MAIN_MENU

func change_state(new_state: LevelStateEnum) -> void:
	if current_level_state != new_state:
		current_level_state = new_state

	match current_level_state:
		LevelStateEnum.MAIN_MENU:
			_load_main_menu()
		LevelStateEnum.LEVEL1:
			_load_level1()
		LevelStateEnum.UPGRADE_BETWEEN_1_2:
			_load_upgrade_between_1_2()
		LevelStateEnum.LEVEL2:
			_load_level2()
		LevelStateEnum.UPGRADE_BETWEEN_2_3:
			_load_upgrade_between_2_3()
		LevelStateEnum.LEVEL3:
			_load_level3()
		LevelStateEnum.VICTORY_SCREEN:
			_load_victory_screen()
	
	player_state.reset_health()

func restart_current_level() -> void:
	_clear_pause_state()
	change_state(current_level_state)

func go_to_main_menu() -> void:
	_clear_pause_state()
	change_state(LevelStateEnum.MAIN_MENU)

func _clear_pause_state() -> void:
	get_tree().paused = false

func _change_scene(path: String) -> void:
	get_tree().call_deferred("change_scene_to_file", path)

func _load_main_menu() -> void:
	_change_scene("res://scenes/levels/main_menu.tscn")

func _load_level1() -> void:
	_change_scene("res://scenes/levels/level1.tscn")

func _load_upgrade_between_1_2() -> void:
	_change_scene("res://scenes/levels/upgrade_between_1_2.tscn")

func _load_level2() -> void:
	_change_scene("res://scenes/levels/level2.tscn")

func _load_upgrade_between_2_3() -> void:
	_change_scene("res://scenes/levels/upgrade_between_2_3.tscn")

func _load_level3() -> void:
	_change_scene("res://scenes/levels/level3.tscn")

func _load_victory_screen() -> void:
	_change_scene("res://scenes/levels/victory_screen.tscn")
