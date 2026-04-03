extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_velocity: float = -350.0
@export var gravity: float = 900.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	var input_x := Input.get_axis("move_left", "move_right")

	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	velocity.x = input_x * speed

	if input_x < 0:
		anim.flip_h = true
	elif input_x > 0:
		anim.flip_h = false

	move_and_slide()

	if not is_on_floor():
		if velocity.y < 0:
			play_anim("jump")
		else:
			play_anim("fall")
	else:
		if abs(input_x) > 0.0:
			play_anim("run")
		else:
			play_anim("idle")

func play_anim(name: String) -> void:
	if anim.animation != name:
		anim.play(name)
