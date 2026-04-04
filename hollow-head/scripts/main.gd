extends Node2D

@export var spawn_effect_scene: PackedScene

@onready var beast = $Beast

func _ready() -> void:
	beast.visible = false
	spawn_beast_effect()

func spawn_beast_effect() -> void:
	if spawn_effect_scene == null:
		return

	var effect = spawn_effect_scene.instantiate()
	effect.global_position = beast.global_position
	add_child(effect)

	effect.spawn_finished.connect(_on_spawn_finished)

func _on_spawn_finished() -> void:
	beast.visible = true
