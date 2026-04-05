extends Node2D

enum LevelStateEnum {
	MAIN_MENU,
	LEVEL1,
	LEVEL2,
	LEVEL3,
	VICTORY_SCREEN
}

var current_level_state: LevelStateEnum = LevelStateEnum.MAIN_MENU

func change_state(new_state: LevelStateEnum):
	if(current_level_state != new_state):
		current_level_state = new_state
	
	match current_level_state:
		LevelStateEnum.MAIN_MENU:
			_load_main_menu()
		LevelStateEnum.LEVEL1:
			_load_level1()
		LevelStateEnum.LEVEL2:
			_load_level2()
		LevelStateEnum.LEVEL3:
			_load_level3()
		LevelStateEnum.VICTORY_SCREEN:
			_load_victory_screen()

func restart_current_level() -> void:
	_clear_pause_state()
	change_state(current_level_state)

func go_to_main_menu() -> void:
	_clear_pause_state()
	change_state(LevelStateEnum.MAIN_MENU)

func _clear_pause_state() -> void:
	get_tree().paused = false

func _change_scene(path: String):
	get_tree().call_deferred("change_scene_to_file", path)

func _load_main_menu():
	_change_scene("res://scenes/levels/main_menu.tscn")

func _load_level1():
	_change_scene("res://scenes/levels/level1.tscn")

func _load_level2():
	_change_scene("res://scenes/levels/level2.tscn")

func _load_level3():
	_change_scene("res://scenes/levels/level3.tscn")
	
func _load_victory_screen():
	_change_scene("res://scenes/levels/victory_screen.tscn")
