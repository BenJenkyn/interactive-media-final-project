extends CharacterBody2D

@export var gravity: float = 900.0
@export var attack_cooldown: float = 2.0
@export var shoot_frame: int = 3
@export var projectile_scene: PackedScene
@export var projectile_spawn_distance: float = 20.0
@export var use_teleport_attack: bool = true
@export var teleport_points_path: NodePath
@export var teleport_damage_amount: int = 1
@export var teleport_signal_time: float = 0.5
@export var teleport_in_signal_time: float = 0.4

@export var max_health: int = 2

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var projectile_spawn: Marker2D = $ProjectileSpawn
@onready var teleport_out_effect: AnimatedSprite2D = $TeleportOutEffect
@onready var teleport_in_effect: AnimatedSprite2D = $TeleportInEffect
@onready var teleport_signal: AnimatedSprite2D = $Teleportsignal

@onready var teleport_out_damage: Area2D = $TeleportOutDamage
@onready var teleport_out_damage_shape: CollisionShape2D = $TeleportOutDamage/CollisionShape2D
@onready var teleport_in_damage: Area2D = $TeleportInDamage
@onready var teleport_in_damage_shape: CollisionShape2D = $TeleportInDamage/CollisionShape2D

@onready var hurtbox: Area2D = $Hurtbox

var target: Node2D = null
var facing: float = 1.0
var is_attacking: bool = false
var has_shot: bool = false
var attack_timer: float = 0.0

var is_teleporting: bool = false
var pending_teleport_position: Vector2 = Vector2.ZERO
var teleport_points: Array[Marker2D] = []
var last_teleport_index: int = -1
var teleport_hit_targets: Array[Node] = []

var current_health: int = 0
var is_dead: bool = false

func _ready() -> void:
	current_health = max_health

	anim.animation_finished.connect(_on_animation_finished)
	teleport_out_effect.animation_finished.connect(_on_teleport_out_finished)
	teleport_in_effect.animation_finished.connect(_on_teleport_in_finished)

	teleport_out_damage.body_entered.connect(_on_teleport_damage_body_entered)
	teleport_in_damage.body_entered.connect(_on_teleport_damage_body_entered)
	teleport_out_damage.area_entered.connect(_on_teleport_damage_area_entered)
	teleport_in_damage.area_entered.connect(_on_teleport_damage_area_entered)

	hurtbox.area_entered.connect(_on_hurtbox_area_entered)

	teleport_out_effect.visible = false
	teleport_in_effect.visible = false
	teleport_signal.visible = false
	teleport_out_damage_shape.disabled = true
	teleport_in_damage_shape.disabled = true

	anim.play("idle")
	attack_timer = attack_cooldown
	update_facing_visuals()
	load_teleport_points()

func load_teleport_points() -> void:
	if teleport_points_path == NodePath():
		return

	var points_parent := get_node_or_null(teleport_points_path)
	if points_parent == null:
		return

	for child in points_parent.get_children():
		if child is Marker2D:
			teleport_points.append(child)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

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
	if is_dead:
		return

	is_attacking = true
	has_shot = false
	anim.play("attack")

func start_teleport_attack() -> void:
	if is_teleporting or is_dead:
		return

	is_teleporting = true
	has_shot = false
	velocity = Vector2.ZERO

	pending_teleport_position = get_random_teleport_position()

	teleport_hit_targets.clear()
	teleport_out_effect.visible = true
	teleport_out_damage_shape.disabled = false
	teleport_out_effect.play("teleport_out")
	anim.visible = false

func get_random_teleport_position() -> Vector2:
	if teleport_points.is_empty():
		return global_position

	if teleport_points.size() == 1:
		return teleport_points[0].global_position

	var index := randi() % teleport_points.size()
	while index == last_teleport_index:
		index = randi() % teleport_points.size()

	last_teleport_index = index
	return teleport_points[index].global_position

func _on_teleport_out_finished() -> void:
	teleport_out_effect.visible = false
	teleport_out_damage_shape.disabled = true

	teleport_signal.global_position = pending_teleport_position + Vector2(0, -60)
	teleport_signal.visible = true
	teleport_signal.play("signal")

	await get_tree().create_timer(teleport_in_signal_time).timeout

	teleport_signal.visible = false

	global_position = pending_teleport_position

	if target != null:
		if target.global_position.x < global_position.x:
			facing = -1.0
		else:
			facing = 1.0
		update_facing_visuals()

	teleport_hit_targets.clear()
	teleport_in_effect.visible = true
	teleport_in_damage_shape.disabled = false
	teleport_in_effect.play("teleport_in")

func _on_teleport_in_finished() -> void:
	teleport_in_effect.visible = false
	teleport_in_damage_shape.disabled = true
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

func damage_target(node: Node) -> void:
	if node == null:
		return

	if node in teleport_hit_targets:
		return

	teleport_hit_targets.append(node)

	if node.has_method("take_damage"):
		node.take_damage(teleport_damage_amount)
	elif node.get_parent() != null and node.get_parent().has_method("take_damage"):
		node.get_parent().take_damage(teleport_damage_amount)

func _on_teleport_damage_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		damage_target(body)

func _on_teleport_damage_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		damage_target(area)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if is_dead:
		return

	if area.is_in_group("player_attack"):
		take_damage(1)

func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_health -= amount
	print("Beast health: ", current_health)

	anim.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout

	if not is_dead:
		anim.modulate = Color(1, 1, 1)

	if current_health <= 0:
		die()

func die() -> void:
	is_dead = true
	is_attacking = false
	is_teleporting = false
	teleport_signal.visible = false
	teleport_out_damage_shape.disabled = true
	teleport_in_damage_shape.disabled = true
	queue_free()
	level_state.change_state(level_state.LevelStateEnum.VICTORY_SCREEN)

func _on_animation_finished() -> void:
	if anim.animation == "attack":
		is_attacking = false
		has_shot = false
		attack_timer = attack_cooldown
		anim.play("idle")
