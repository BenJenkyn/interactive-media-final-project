extends Node2D

enum LevelStateEnum {
	MAIN_MENU,
	LEVEL1,
	LEVEL2,
	LEVEL3,
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

func _load_main_menu():
	get_tree().change_scene_to_file("res://scenes/levels/main_menu.tscn")
	
func _load_level1():
	get_tree().change_scene_to_file("res://scenes/levels/level1.tscn")
	
func _load_level2():
	get_tree().change_scene_to_file("res://scenes/levels/level2.tscn")
	
func _load_level3():
	get_tree().change_scene_to_file("res://scenes/levels/level3.tscn")
