extends Node2D

@onready var victory_count_label = $CanvasLayer/VBoxContainer/VictoryCountLabel
@onready var start_button = $CanvasLayer/VBoxContainer/StartButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	victory_count_label.text = "Victories: " + str(player_state.victory_count)
	start_button.pressed.connect(_on_start_pressed)
	start_button.grab_focus()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_start_pressed():
	level_state.change_state(level_state.LevelStateEnum.LEVEL1)
