extends Control

@onready var upgrade_button_1: Button = $UpgradeButton1
@onready var upgrade_button_2: Button = $UpgradeButton2
@onready var upgrade_button_3: Button = $UpgradeButton3

func _ready() -> void:
	upgrade_button_1.pressed.connect(_on_upgrade_button_1_pressed)
	upgrade_button_2.pressed.connect(_on_upgrade_button_2_pressed)
	upgrade_button_3.pressed.connect(_on_upgrade_button_3_pressed)

func _on_upgrade_button_1_pressed() -> void:
	player_state.unlock_throw()
	level_state.change_state(level_state.LevelStateEnum.LEVEL3)

func _on_upgrade_button_2_pressed() -> void:
	player_state.add_move_speed(50.0)
	level_state.change_state(level_state.LevelStateEnum.LEVEL3)

func _on_upgrade_button_3_pressed() -> void:
	player_state.add_max_health(2)
	level_state.change_state(level_state.LevelStateEnum.LEVEL3)
