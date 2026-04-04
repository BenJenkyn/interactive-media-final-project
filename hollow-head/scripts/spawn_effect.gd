extends Node2D

signal spawn_finished

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	anim.animation_finished.connect(_on_animation_finished)
	anim.play("spawn")

func _on_animation_finished() -> void:
	if anim.animation == "spawn":
		spawn_finished.emit()
		queue_free()
