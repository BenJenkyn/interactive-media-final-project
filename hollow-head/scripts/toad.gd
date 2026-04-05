extends CharacterBody2D

@export var move_speed: float = 60.0
@export var gravity: float = 900.0

@export var normal_jump_force: float = -260.0

@export var big_jump_height: float = 520.0
@export var min_big_jump_wait: float = 2.5
@export var max_big_jump_wait: float = 4.5

@export var jump_hurtbox_offset_y: float = -12.0

@export var max_health: int = 10
@export var attack_damage: int = 1
@export var attack_range: float = 100.0
@export var attack_cooldown: float = 1.2
@export var attack_active_time: float = 0.2
@export var attack_area_x_offset: float = 28.0

@export var random_move_time_min: float = 0.8
@export var random_move_time_max: float = 1.8

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var health_warning_label: Label = $HealthWarningLabel

var player: Node2D = null

var hurtbox_start_pos: Vector2
var body_collision_start_pos: Vector2
var attack_area_start_pos: Vector2
var health_warning_start_pos: Vector2

var health: int = 0
var is_attacking: bool = false
var can_attack: bool = true
var attack_has_hit: bool = false
var is_dead: bool = false

var random_move_timer: float = 0.0
var random_move_dir: float = 0.0

var normal_jump_timer: float = 0.0
var big_jump_timer: float = 0.0

var is_big_jumping: bool = false
var big_jump_target_x: float = 0.0
var big_jump_start_x: float = 0.0
var big_jump_total_time: float = 0.0
var big_jump_elapsed: float = 0.0
var big_jump_velocity_x: float = 0.0

var shown_50_percent: bool = false
var shown_25_percent: bool = false
var shown_10_percent: bool = false
var warning_tween: Tween = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D

	hurtbox_start_pos = hurtbox.position
	body_collision_start_pos = body_collision.position
	attack_area_start_pos = attack_area.position
	health_warning_start_pos = health_warning_label.position

	health = max_health

	attack_area.monitoring = true
	attack_shape.disabled = true
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)

	health_warning_label.text = ""
	health_warning_label.visible = false
	health_warning_label.modulate = Color(1, 1, 1, 1)
	health_warning_label.scale = Vector2(1, 1)

	anim.play("idle")

	_reset_normal_jump_timer()
	_reset_big_jump_timer()
	_pick_random_move()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D

	if not is_on_floor():
		velocity.y += gravity * delta

	if is_attacking:
		velocity.x = 0.0
	elif is_big_jumping:
		big_jump_elapsed += delta
		velocity.x = big_jump_velocity_x
	else:
		_handle_ai(delta)

	move_and_slide()

	if is_big_jumping and is_on_floor() and velocity.y >= 0.0:
		is_big_jumping = false
		big_jump_velocity_x = 0.0
		global_position.x = big_jump_target_x

	_update_animation()

func _handle_ai(delta: float) -> void:
	if player == null:
		_do_random_move(delta)
		return

	var dx: float = player.global_position.x - global_position.x
	var abs_dx: float = abs(dx)
	var facing_dir: float = sign(dx)

	if facing_dir != 0.0:
		anim.flip_h = facing_dir < 0.0
		_update_attack_area_side(facing_dir)

	if abs_dx <= attack_range and is_on_floor():
		velocity.x = 0.0
		if can_attack:
			_start_attack()
		return

	normal_jump_timer -= delta
	big_jump_timer -= delta

	if abs_dx > attack_range and big_jump_timer <= 0.0 and is_on_floor():
		_start_big_jump()
		return

	_do_random_move(delta)

	if normal_jump_timer <= 0.0 and is_on_floor():
		_start_normal_jump()

func _do_random_move(delta: float) -> void:
	random_move_timer -= delta

	if random_move_timer <= 0.0:
		_pick_random_move()

	velocity.x = random_move_dir * move_speed

	if random_move_dir != 0.0:
		anim.flip_h = random_move_dir < 0.0
		_update_attack_area_side(random_move_dir)

func _pick_random_move() -> void:
	var choices := [-1.0, 1.0, 0.0]
	random_move_dir = choices[randi() % choices.size()]
	random_move_timer = randf_range(random_move_time_min, random_move_time_max)

func _start_attack() -> void:
	if is_dead:
		return

	is_attacking = true
	can_attack = false
	attack_has_hit = false
	is_big_jumping = false
	big_jump_velocity_x = 0.0
	velocity.x = 0.0
	_reset_jump_offsets()
	anim.play("attack")

func _finish_attack() -> void:
	is_attacking = false
	_disable_attack_hitbox()

	await get_tree().create_timer(attack_cooldown).timeout

	if not is_dead:
		can_attack = true

func _start_normal_jump() -> void:
	velocity.y = normal_jump_force
	_reset_normal_jump_timer()

func _start_big_jump() -> void:
	if player == null:
		return

	big_jump_target_x = player.global_position.x
	big_jump_start_x = global_position.x

	var distance_x: float = big_jump_target_x - big_jump_start_x

	velocity.y = -big_jump_height

	big_jump_total_time = (2.0 * big_jump_height) / gravity
	if big_jump_total_time <= 0.0:
		big_jump_total_time = 0.1

	big_jump_velocity_x = distance_x / big_jump_total_time
	big_jump_elapsed = 0.0
	is_big_jumping = true

	if distance_x != 0.0:
		anim.flip_h = distance_x < 0.0
		_update_attack_area_side(sign(distance_x))

	anim.play("jump")
	_reset_big_jump_timer()

func _reset_normal_jump_timer() -> void:
	normal_jump_timer = randf_range(1.2, 2.4)

func _reset_big_jump_timer() -> void:
	big_jump_timer = randf_range(min_big_jump_wait, max_big_jump_wait)

func _enable_attack_hitbox() -> void:
	if anim.get_frame() == 3:
		attack_shape.disabled = false

		await get_tree().create_timer(attack_active_time).timeout

	if not is_dead:
		_disable_attack_hitbox()

func _disable_attack_hitbox() -> void:
	attack_shape.disabled = true

func _on_attack_area_body_entered(body: Node) -> void:
	if not is_attacking:
		return

	if attack_has_hit:
		return

	if body == player and body.has_method("take_damage"):
		body.take_damage(attack_damage)
		attack_has_hit = true

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if is_dead:
		return

	if area.is_in_group("player_attack"):
		take_damage(1)

func _update_attack_area_side(direction: float) -> void:
	var new_x: float = abs(attack_area_x_offset)
	if direction < 0.0:
		new_x = -new_x
	attack_area.position.x = new_x

func _apply_jump_offsets() -> void:
	hurtbox.position = hurtbox_start_pos + Vector2(0.0, jump_hurtbox_offset_y)
	body_collision.position = body_collision_start_pos + Vector2(0.0, jump_hurtbox_offset_y)
	attack_area.position.y = attack_area_start_pos.y + jump_hurtbox_offset_y
	health_warning_label.position.y = health_warning_start_pos.y + jump_hurtbox_offset_y

func _reset_jump_offsets() -> void:
	hurtbox.position = hurtbox_start_pos
	body_collision.position = body_collision_start_pos
	attack_area.position.y = attack_area_start_pos.y
	health_warning_label.position = health_warning_start_pos

func _update_animation() -> void:
	if is_dead:
		return

	if is_attacking:
		return

	if not is_on_floor():
		_apply_jump_offsets()
		if anim.animation != "jump":
			anim.play("jump")
		return

	_reset_jump_offsets()

	if abs(velocity.x) > 0.1:
		if anim.animation != "walk":
			anim.play("walk")
	else:
		if anim.animation != "idle":
			anim.play("idle")

func _process(_delta: float) -> void:
	if is_dead:
		return

	if is_attacking and anim.animation == "attack":
		var frame: int = anim.frame
		var last_frame: int = anim.sprite_frames.get_frame_count("attack") - 1

		if frame >= 1 and attack_shape.disabled:
			_enable_attack_hitbox()

		if frame >= last_frame:
			_finish_attack()

func take_damage(amount: int) -> void:
	if is_dead:
		return

	health -= amount

	var health_percent: float = float(health) / float(max_health)

	if health_percent <= 0.5 and not shown_50_percent:
		shown_50_percent = true
		_show_health_warning("50% HEALTH")

	if health_percent <= 0.25 and not shown_25_percent:
		shown_25_percent = true
		_show_health_warning("25% HEALTH")

	if health_percent <= 0.10 and not shown_10_percent:
		shown_10_percent = true
		_show_health_warning("10% HEALTH")

	print("Enemy health: ", health)

	anim.modulate = Color(1, 0.3, 0.3)

	await get_tree().create_timer(0.1).timeout

	if not is_dead:
		anim.modulate = Color(1, 1, 1)

	if health <= 0:
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

	if not is_dead:
		health_warning_label.visible = false
		health_warning_label.modulate = Color(1, 1, 1, 1)
		health_warning_label.position = health_warning_start_pos
		health_warning_label.scale = Vector2(1, 1)

func die() -> void:
	is_dead = true
	anim.play("death")
	await anim.animation_finished
	queue_free()
	#await get_tree().create_timer(3.0).timeout
	level_state.change_state(level_state.LevelStateEnum.LEVEL2)
