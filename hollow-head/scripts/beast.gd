extends CharacterBody2D

@export var gravity: float = 900.0
@export var attack_cooldown: float = 2.0
@export var shoot_frame: int = 3
@export var projectile_scene: PackedScene
@export var projectile_spawn_distance: float = 20.0
@export var teleport_distance_from_player: float = 24.0
@export var use_teleport_attack: bool = true

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var projectile_spawn: Marker2D = $ProjectileSpawn
@onready var teleport_out_effect: AnimatedSprite2D = $TeleportOutEffect
@onready var teleport_in_effect: AnimatedSprite2D = $TeleportInEffect

var target: Node2D = null
var facing: float = 1.0
var is_attacking: bool = false
var has_shot: bool = false
var attack_timer: float = 0.0

var is_teleporting: bool = false
var pending_teleport_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	anim.animation_finished.connect(_on_animation_finished)
	teleport_out_effect.animation_finished.connect(_on_teleport_out_finished)
	teleport_in_effect.animation_finished.connect(_on_teleport_in_finished)

	teleport_out_effect.visible = false
	teleport_in_effect.visible = false

	anim.play("idle")
	attack_timer = attack_cooldown
	update_facing_visuals()

func _physics_process(delta: float) -> void:
	if target == null:
		target = get_tree().get_first_node_in_group("player") as Node2D

	if not is_on_floor():
		velocity.y += gravity * delta

	velocity.x = 0.0

	if target != null and not is_teleporting:
		face_target()

	if not is_attacking and not is_teleporting:
		attack_timer -= delta
		if attack_timer <= 0.0:
			if use_teleport_attack:
				start_teleport_attack()
			else:
				start_attack()

	if is_attacking and not is_teleporting:
		if anim.animation == "attack" and anim.frame >= shoot_frame and not has_shot:
			spawn_fireball()
			has_shot = true

	move_and_slide()

func face_target() -> void:
	if target == null:
		return

	if target.global_position.x < global_position.x:
		facing = -1.0
	else:
		facing = 1.0

	update_facing_visuals()

func update_facing_visuals() -> void:
	anim.flip_h = facing > 0.0
	projectile_spawn.position.x = projectile_spawn_distance * facing

func start_attack() -> void:
	is_attacking = true
	has_shot = false
	anim.play("attack")

func start_teleport_attack() -> void:
	if target == null:
		return

	is_teleporting = true
	has_shot = false
	velocity = Vector2.ZERO

	pending_teleport_position = target.global_position

	teleport_out_effect.visible = true
	teleport_out_effect.play("teleport_out")
	anim.visible = false

func _on_teleport_out_finished() -> void:
	teleport_out_effect.visible = false

	global_position = pending_teleport_position

	if target != null:
		if target.global_position.x < global_position.x:
			facing = -1.0
		else:
			facing = 1.0
		update_facing_visuals()

	teleport_in_effect.visible = true
	teleport_in_effect.play("teleport_in")

func _on_teleport_in_finished() -> void:
	teleport_in_effect.visible = false
	anim.visible = true
	is_teleporting = false
	start_attack()

func spawn_fireball() -> void:
	if projectile_scene == null:
		return

	var fireball = projectile_scene.instantiate()
	fireball.global_position = projectile_spawn.global_position

	if fireball.has_method("set_direction"):
		fireball.set_direction(facing)
	elif "direction" in fireball:
		fireball.direction = facing

	get_parent().add_child(fireball)

func _on_animation_finished() -> void:
	if anim.animation == "attack":
		is_attacking = false
		has_shot = false
		attack_timer = attack_cooldown
		anim.play("idle")
