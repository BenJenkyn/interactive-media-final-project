extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_velocity: float = -350.0
@export var gravity: float = 900.0
@export var projectile_scene: PackedScene

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var projectile_spawn: Marker2D = $ProjectileSpawn

var is_attacking: bool = false
var is_throwing: bool = false
var facing: float = 1.0
var attack_facing: float = 1.0
var throw_facing: float = 1.0
var has_spawned_projectile: bool = false

func _ready() -> void:
	attack_area.monitoring = false
	attack_shape.disabled = true

func _physics_process(delta: float) -> void:
	var input_x := Input.get_axis("move_left", "move_right")

	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_attacking and not is_throwing:
		velocity.y = jump_velocity

	if Input.is_action_just_pressed("attack") and not is_attacking and not is_throwing:
		start_attack()

	if Input.is_action_just_pressed("throw") and not is_throwing and not is_attacking:
		start_throw()

	if not is_attacking and not is_throwing:
		velocity.x = input_x * speed
	else:
		velocity.x = 0.0

	if not is_attacking and not is_throwing:
		if input_x < 0:
			facing = -1.0
		elif input_x > 0:
			facing = 1.0

	_update_facing_visuals()

	move_and_slide()

	if is_attacking or is_throwing:
		return

	if velocity.y < -20:
		_play_if_not("jump")
	elif velocity.y > 20:
		_play_if_not("fall")
	else:
		if abs(input_x) > 0.1:
			_play_if_not("run")
		else:
			_play_if_not("idle")

func _update_facing_visuals() -> void:
	if is_attacking:
		anim.flip_h = attack_facing < 0
		attack_area.position.x = abs(attack_area.position.x) * attack_facing
		projectile_spawn.position.x = abs(projectile_spawn.position.x) * facing
	elif is_throwing:
		anim.flip_h = throw_facing < 0
		attack_area.position.x = abs(attack_area.position.x) * facing
		projectile_spawn.position.x = abs(projectile_spawn.position.x) * throw_facing
	else:
		anim.flip_h = facing < 0
		attack_area.position.x = abs(attack_area.position.x) * facing
		projectile_spawn.position.x = abs(projectile_spawn.position.x) * facing

func start_attack() -> void:
	is_attacking = true
	attack_facing = facing
	attack_area.position.x = abs(attack_area.position.x) * attack_facing
	anim.flip_h = attack_facing < 0
	attack_area.monitoring = true
	attack_shape.disabled = false
	anim.play("attack")

func start_throw() -> void:
	is_throwing = true
	throw_facing = facing
	projectile_spawn.position.x = abs(projectile_spawn.position.x) * throw_facing
	anim.flip_h = throw_facing < 0
	has_spawned_projectile = false
	anim.play("throw")

func spawn_projectile() -> void:
	if projectile_scene == null:
		print("Projectile scene not assigned")
		return

	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = projectile_spawn.global_position
	projectile.setup(throw_facing)

func _on_animated_sprite_2d_frame_changed() -> void:
	if anim.animation == "throw" and anim.frame == 1 and not has_spawned_projectile:
		has_spawned_projectile = true
		spawn_projectile()

func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "attack":
		is_attacking = false
		attack_area.monitoring = false
		attack_shape.disabled = true
	elif anim.animation == "throw":
		is_throwing = false

func _play_if_not(name: String) -> void:
	if anim.animation != name:
		anim.play(name)
