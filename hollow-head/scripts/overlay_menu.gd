extends CanvasLayer

signal menu_closed

enum OverlayMode {
	PAUSE,
	GAME_OVER,
}

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var restart_button: Button = $Panel/VBoxContainer/RestartLevelButton
@onready var main_menu_button: Button = $Panel/VBoxContainer/MainMenuButton

var mode: OverlayMode = OverlayMode.PAUSE
var ignore_pause_until_release: bool = true

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	_configure_button_navigation()
	_apply_mode_ui()
	call_deferred("_focus_default_button")

func _process(_delta: float) -> void:
	if mode != OverlayMode.PAUSE:
		return

	if ignore_pause_until_release:
		if not Input.is_action_pressed("pause"):
			ignore_pause_until_release = false
		return

	if Input.is_action_just_pressed("pause"):
		_close_overlay()

func configure_mode(new_mode: OverlayMode) -> void:
	mode = new_mode
	if is_node_ready():
		_apply_mode_ui()

func _apply_mode_ui() -> void:
	if mode == OverlayMode.GAME_OVER:
		title_label.text = "Game Over"
		resume_button.visible = false
	else:
		title_label.text = "Paused"
		resume_button.visible = true

	if is_node_ready():
		call_deferred("_focus_default_button")

func _configure_button_navigation() -> void:
	resume_button.focus_mode = Control.FOCUS_ALL
	restart_button.focus_mode = Control.FOCUS_ALL
	main_menu_button.focus_mode = Control.FOCUS_ALL

	resume_button.focus_neighbor_bottom = restart_button.get_path()
	restart_button.focus_neighbor_top = resume_button.get_path()
	restart_button.focus_neighbor_bottom = main_menu_button.get_path()
	main_menu_button.focus_neighbor_top = restart_button.get_path()
	main_menu_button.focus_neighbor_bottom = restart_button.get_path()

func _focus_default_button() -> void:
	if mode == OverlayMode.GAME_OVER:
		restart_button.grab_focus()
	else:
		resume_button.grab_focus()

func _on_resume_pressed() -> void:
	_close_overlay()

func _on_restart_pressed() -> void:
	player_state.reset_health()
	level_state.restart_current_level()
	queue_free()

func _on_main_menu_pressed() -> void:
	player_state.reset_health()
	level_state.go_to_main_menu()
	queue_free()

func _close_overlay() -> void:
	get_tree().paused = false
	ignore_pause_until_release = true
	menu_closed.emit()
	queue_free()
