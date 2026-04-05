extends Node

@onready var main_menu_button := $CanvasLayer/MainMenuButton
@onready var victory_gem_1 := $CanvasLayer/VictoryGem
@onready var victory_gem_2 := $CanvasLayer/VictoryGem2
@onready var dancing_npc_1 := $CanvasLayer/DancingNpc
@onready var dancing_npc_2 := $CanvasLayer/DancingNpc2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	main_menu_button.grab_focus()
	victory_gem_1.play()
	victory_gem_2.play()
	dancing_npc_1.play()
	dancing_npc_2.play()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_main_menu_pressed() -> void:
	player_state.reset_health()
	level_state.go_to_main_menu()
	player_state.add_victory()
	queue_free()
