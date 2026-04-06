extends CharacterBody2D

enum State {
	IDLE,
	ATTACKING,
	TELEPORTING,
	DEAD
}

@export var gravity: float = 900.0
@export var attack_cooldown: float = 2.0
@export var shoot_frame: int = 3
@export var projectile_scene: PackedScene
@export var projectile_spawn_distance: float = 20.0
@export var use_teleport_attack: bool = true
@export var teleport_points_path: NodePath
@export var teleport_damage_amount: int = 1
@export var teleport_signal_time: float = 0.5
@export var teleport_in_signal_time: float = 0.7

@export var fireballs_per_attack: int = 3
@export var time_between_fireballs: float = 0.25

@export var max_health: int = 10

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var projectile_spawn: Marker2D = $ProjectileSpawn
@onready var teleport_out_effect: AnimatedSprite2D = $TeleportOutEffect
@onready var teleport_in_effect: AnimatedSprite2D = $TeleportInEffect
@onready var teleport_signal: AnimatedSprite2D = $Teleportsignal
@onready var death_animation: AnimatedSprite2D = $DeathAnimation

# Sound Effects
@onready var death_sound: AudioStreamPlayer2D = $SoundEffects/DeathSound

@onready var teleport_out_damage: Area2D = $TeleportOutDamage
@onready var teleport_out_damage_shape: CollisionShape2D = $TeleportOutDamage/CollisionShape2D
@onready var teleport_in_damage: Area2D = $TeleportInDamage
@onready var teleport_in_damage_shape: CollisionShape2D = $TeleportInDamage/CollisionShape2D

@onready var hurtbox: Area2D = $Hurtbox
@onready var health_warning_label: Label = $HealthWarningLabel

var current_state: State = State.IDLE
var target: Node2D = null
var facing: float = 1.0
var has_shot: bool = false
var attack_timer: float = 0.0

var pending_teleport_position: Vector2 = Vector2.ZERO
var teleport_points: Array[Marker2D] = []
var last_teleport_index: int = -1
var teleport_hit_targets: Array[Node] = []

var current_health: int = 0

var health_warning_start_pos: Vector2
var shown_50_percent: bool = false
var shown_25_percent: bool = false
var shown_10_percent: bool = false
var warning_tween: Tween = null

func _ready() -> void:
	current_health = max_health

	anim.animation_finished.connect(_on_animation_finished)
	death_animation.animation_finished.connect(_on_death_animation_finished)
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
	death_animation.visible = false
	teleport_out_damage_shape.disabled = true
	teleport_in_damage_shape.disabled = true

	health_warning_start_pos = health_warning_label.position
	health_warning_label.text = ""
	health_warning_label.visible = false
	health_warning_label.modulate = Color(1, 1, 1, 1)
	health_warning_label.scale = Vector2(1, 1)

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
	if target == null:
		target = get_tree().get_first_node_in_group("player") as Node2D

	if not is_on_floor():
		velocity.y += gravity * delta

	velocity.x = 0.0

	match current_state:
		State.IDLE:
			update_idle(delta)
		State.ATTACKING:
			update_attacking(delta)
		State.TELEPORTING:
			update_teleporting(delta)
		State.DEAD:
			return

	move_and_slide()

func update_idle(delta: float) -> void:
	if target != null:
		face_target()

	attack_timer -= delta
	if attack_timer <= 0.0:
		if use_teleport_attack:
			transition_to_state(State.TELEPORTING)
			start_teleport_attack()
		else:
			transition_to_state(State.ATTACKING)
			start_attack()

func update_attacking(delta: float) -> void:
	if anim.animation == "attack" and anim.frame >= shoot_frame and not has_shot:
		has_shot = true
		fireball_burst()

func update_teleporting(delta: float) -> void:
	pass

func transition_to_state(new_state: State) -> void:
	if current_state == new_state:
		return

	match current_state:
		State.IDLE:
			exit_idle()
		State.ATTACKING:
			exit_attacking()
		State.TELEPORTING:
			exit_teleporting()
		State.DEAD:
			exit_dead()

	current_state = new_state

	match current_state:
		State.IDLE:
			enter_idle()
		State.ATTACKING:
			enter_attacking()
		State.TELEPORTING:
			enter_teleporting()
		State.DEAD:
			enter_dead()

func enter_idle() -> void:
	anim.play("idle")

func exit_idle() -> void:
	pass

func enter_attacking() -> void:
	has_shot = false

func exit_attacking() -> void:
	has_shot = false

func enter_teleporting() -> void:
	has_shot = false
	velocity = Vector2.ZERO
	pending_teleport_position = get_random_teleport_position()
	teleport_hit_targets.clear()
	teleport_out_effect.visible = true
	teleport_out_damage_shape.disabled = false
	teleport_out_effect.play("teleport_out")
	anim.visible = false

func exit_teleporting() -> void:
	pass

func enter_dead() -> void:
	has_shot = false
	velocity = Vector2.ZERO
	hurtbox.monitoring = false
	hurtbox.monitorable = false
	teleport_signal.visible = false
	teleport_out_effect.visible = false
	teleport_in_effect.visible = false
	teleport_out_damage_shape.disabled = true
	teleport_in_damage_shape.disabled = true
	anim.visible = false
	death_animation.visible = true
	death_sound.play()
	death_animation.play("dead")
	health_warning_label.visible = false

func exit_dead() -> void:
	pass

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
	if current_state == State.DEAD:
		return

	anim.play("attack")

func start_teleport_attack() -> void:
	pass

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
	if current_state == State.DEAD:
		return

	teleport_out_effect.visible = false
	teleport_out_damage_shape.disabled = true

	teleport_signal.global_position = pending_teleport_position + Vector2(0, -50)
	teleport_signal.visible = true
	teleport_signal.play("signal")

	await get_tree().create_timer(teleport_in_signal_time).timeout

	if current_state == State.DEAD:
		return

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
	if current_state == State.DEAD:
		return

	teleport_in_effect.visible = false
	teleport_in_damage_shape.disabled = true
	anim.visible = true
	transition_to_state(State.ATTACKING)
	start_attack()

func fireball_burst() -> void:
	_fireball_burst_async()

func _fireball_burst_async() -> void:
	var shot_count: int = max(1, fireballs_per_attack)

	for i in range(shot_count):
		if current_state == State.DEAD:
			return

		spawn_fireball()

		if i < shot_count - 1:
			await get_tree().create_timer(time_between_fireballs).timeout

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

func _get_player_attack_damage(area: Area2D) -> int:
	if area == null:
		return 1

	var owner_node := area.owner
	if owner_node != null and owner_node.has_method("get_attack_damage"):
		return owner_node.get_attack_damage()

	var parent_node := area.get_parent()
	if parent_node != null and parent_node.has_method("get_attack_damage"):
		return parent_node.get_attack_damage()

	return 1

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if current_state == State.DEAD:
		return

	if area.is_in_group("player_attack"):
		take_damage(_get_player_attack_damage(area))

func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return

	current_health -= amount

	var health_percent: float = float(current_health) / float(max_health)

	if health_percent <= 0.5 and not shown_50_percent:
		shown_50_percent = true
		_show_health_warning("50% HEALTH")

	if health_percent <= 0.25 and not shown_25_percent:
		shown_25_percent = true
		_show_health_warning("25% HEALTH")

	if health_percent <= 0.10 and not shown_10_percent:
		shown_10_percent = true
		_show_health_warning("10% HEALTH")

	print("Beast health: ", current_health)

	anim.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout

	if current_state != State.DEAD:
		anim.modulate = Color(1, 1, 1)

	if current_health <= 0:
		die()

func _show_health_warning(text_to_show: String) -> void:
	health_warning_label.text = text_to_show
	health_warning_label.visible = true
	health_warning_label.modulate = Color(1, 1, 1, 1)
	health_warning_label.scale = Vector2(1.5, 1.5)
	health_warning_label.position = health_warning_start_pos

	if warning_tween != null:
		warning_tween.kill()

	warning_tween = create_tween()
	warning_tween.tween_property(
		health_warning_label,
		"position",
		health_warning_start_pos + Vector2(0, -20),
		1.5
	)
	warning_tween.parallel().tween_property(
		health_warning_label,
		"modulate:a",
		0.0,
		1.5
	)

	await warning_tween.finished

	if current_state != State.DEAD:
		health_warning_label.visible = false
		health_warning_label.modulate = Color(1, 1, 1, 1)
		health_warning_label.position = health_warning_start_pos
		health_warning_label.scale = Vector2(1, 1)

func _stop_player_movement() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	if player.has_method("set_movement_locked"):
		player.set_movement_locked(true)

func die() -> void:
	_stop_player_movement()
	transition_to_state(State.DEAD)


func _on_animation_finished() -> void:
	if anim.animation == "attack" and current_state == State.ATTACKING:
		attack_timer = attack_cooldown
		transition_to_state(State.IDLE)

func _on_death_animation_finished() -> void:
	if current_state != State.DEAD:
		return

	level_state.change_state(level_state.LevelStateEnum.VICTORY_SCREEN)
	queue_free()
