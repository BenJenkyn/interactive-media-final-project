extends CharacterBody2D

enum PlayerState {
	IDLE,
	RUN,
	JUMP,
	FALL,
	ATTACK,
	THROW,
	DODGE
}

@export var speed: float = 200.0
@export var jump_velocity: float = -600.0
@export var gravity: float = 900.0
@export var projectile_scene: PackedScene

@export var dodge_speed: float = 320.0
@export var dodge_time: float = 0.30

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var projectile_spawn: Marker2D = $ProjectileSpawn
@onready var dash_timer: Timer = $DashTimer
@onready var hurtbox: Area2D = $Hurtbox
@onready var hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D

var pause_menu_scene = preload("res://scenes/UI/pause_menu.tscn")
var overlay_menu: CanvasLayer = null
var pause_toggle_lock_frames: int = 0
var is_dead: bool = false

var state: PlayerState = PlayerState.IDLE

var facing: float = 1.0
var attack_facing: float = 1.0
var throw_facing: float = 1.0
var dodge_facing: float = 1.0

var has_spawned_projectile: bool = false

var dodge_flash_timer: float = 0.0
var dodge_flash_interval: float = 0.05

func _ready() -> void:
	_ensure_pause_action_binding()
	attack_area.monitoring = false
	attack_shape.disabled = true
	dash_timer.one_shot = true
	dash_timer.wait_time = dodge_time
	change_state(PlayerState.IDLE)

func _ensure_pause_action_binding() -> void:
	if not InputMap.has_action("pause"):
		InputMap.add_action("pause")

	if InputMap.action_get_events("pause").is_empty():
		var pause_event := InputEventKey.new()
		pause_event.physical_keycode = KEY_ESCAPE
		InputMap.action_add_event("pause", pause_event)

func _physics_process(delta: float) -> void:
	if pause_toggle_lock_frames > 0:
		pause_toggle_lock_frames -= 1

	_handle_pause_input()

	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_x := Input.get_axis("move_left", "move_right")

	if not is_on_floor():
		velocity.y += gravity * delta

	match state:
		PlayerState.IDLE:
			_state_idle(input_x)
		PlayerState.RUN:
			_state_run(input_x)
		PlayerState.JUMP:
			_state_jump(input_x)
		PlayerState.FALL:
			_state_fall(input_x)
		PlayerState.ATTACK:
			_state_attack()
		PlayerState.THROW:
			_state_throw()
		PlayerState.DODGE:
			_state_dodge(delta)

	move_and_slide()
	_update_air_state()

func change_state(new_state: PlayerState) -> void:
	if state == new_state:
		return

	state = new_state

	match state:
		PlayerState.IDLE:
			anim.modulate.a = 1.0
			anim.play("idle")

		PlayerState.RUN:
			anim.modulate.a = 1.0
			anim.play("run")

		PlayerState.JUMP:
			anim.modulate.a = 1.0
			anim.play("jump")

		PlayerState.FALL:
			anim.modulate.a = 1.0
			anim.play("fall")

		PlayerState.ATTACK:
			anim.modulate.a = 1.0
			attack_facing = facing
			attack_area.position.x = abs(attack_area.position.x) * attack_facing
			anim.flip_h = attack_facing < 0
			attack_area.monitoring = true
			attack_shape.disabled = false
			anim.play("attack")

		PlayerState.THROW:
			anim.modulate.a = 1.0
			throw_facing = facing
			projectile_spawn.position.x = abs(projectile_spawn.position.x) * throw_facing
			anim.flip_h = throw_facing < 0
			has_spawned_projectile = false
			anim.play("throw")

		PlayerState.DODGE:
			dodge_facing = facing
			hurtbox.monitoring = false
			hurtbox.monitorable = false
			hurtbox_shape.disabled = true
			dodge_flash_timer = 0.0
			anim.modulate.a = 0.5
			anim.flip_h = dodge_facing < 0
			anim.play("dodge")
			dash_timer.start(dodge_time)

func _state_idle(input_x: float) -> void:
	velocity.x = 0.0

	if input_x < 0:
		facing = -1.0
	elif input_x > 0:
		facing = 1.0

	_update_facing_visuals()

	if Input.is_action_just_pressed("dodge") and is_on_floor():
		if input_x != 0:
			facing = sign(input_x)
		change_state(PlayerState.DODGE)
		return

	if Input.is_action_just_pressed("attack"):
		change_state(PlayerState.ATTACK)
		return

	if Input.is_action_just_pressed("throw"):
		change_state(PlayerState.THROW)
		return

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		change_state(PlayerState.JUMP)
		return

	if abs(input_x) > 0.1:
		change_state(PlayerState.RUN)

func _state_run(input_x: float) -> void:
	velocity.x = input_x * speed

	if input_x < 0:
		facing = -1.0
	elif input_x > 0:
		facing = 1.0

	_update_facing_visuals()

	if Input.is_action_just_pressed("dodge") and is_on_floor():
		if input_x != 0:
			facing = sign(input_x)
		change_state(PlayerState.DODGE)
		return

	if Input.is_action_just_pressed("attack"):
		change_state(PlayerState.ATTACK)
		return

	if Input.is_action_just_pressed("throw"):
		change_state(PlayerState.THROW)
		return

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		change_state(PlayerState.JUMP)
		return

	if abs(input_x) <= 0.1:
		change_state(PlayerState.IDLE)

func _state_jump(input_x: float) -> void:
	velocity.x = input_x * speed

	if input_x < 0:
		facing = -1.0
	elif input_x > 0:
		facing = 1.0

	_update_facing_visuals()

	if velocity.y > 0:
		change_state(PlayerState.FALL)

func _state_fall(input_x: float) -> void:
	velocity.x = input_x * speed

	if input_x < 0:
		facing = -1.0
	elif input_x > 0:
		facing = 1.0

	_update_facing_visuals()

	if is_on_floor():
		if abs(input_x) > 0.1:
			change_state(PlayerState.RUN)
		else:
			change_state(PlayerState.IDLE)

func _state_attack() -> void:
	velocity.x = 0.0
	_update_facing_visuals()

func _state_throw() -> void:
	velocity.x = 0.0
	_update_facing_visuals()

func _state_dodge(delta: float) -> void:
	velocity.x = dodge_facing * dodge_speed
	_update_facing_visuals()

	dodge_flash_timer += delta
	if dodge_flash_timer >= dodge_flash_interval:
		dodge_flash_timer = 0.0

		if anim.modulate.a >= 1.0:
			anim.modulate.a = 0.35
		else:
			anim.modulate.a = 1.0

func _update_air_state() -> void:
	if state == PlayerState.ATTACK or state == PlayerState.THROW or state == PlayerState.DODGE:
		return

	if not is_on_floor():
		if velocity.y < 0 and state != PlayerState.JUMP:
			change_state(PlayerState.JUMP)
		elif velocity.y > 0 and state != PlayerState.FALL:
			change_state(PlayerState.FALL)

func _update_facing_visuals() -> void:
	if state == PlayerState.ATTACK:
		anim.flip_h = attack_facing < 0
		attack_area.position.x = abs(attack_area.position.x) * attack_facing
		projectile_spawn.position.x = abs(projectile_spawn.position.x) * facing
	elif state == PlayerState.THROW:
		anim.flip_h = throw_facing < 0
		attack_area.position.x = abs(attack_area.position.x) * facing
		projectile_spawn.position.x = abs(projectile_spawn.position.x) * throw_facing
	elif state == PlayerState.DODGE:
		anim.flip_h = dodge_facing < 0
		attack_area.position.x = abs(attack_area.position.x) * dodge_facing
		projectile_spawn.position.x = abs(projectile_spawn.position.x) * dodge_facing
	else:
		anim.flip_h = facing < 0
		attack_area.position.x = abs(attack_area.position.x) * facing
		projectile_spawn.position.x = abs(projectile_spawn.position.x) * facing

func spawn_projectile() -> void:
	if projectile_scene == null:
		print("Projectile scene not assigned")
		return

	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = projectile_spawn.global_position
	projectile.setup(throw_facing)
	
func _handle_pause_input() -> void:
	if is_dead:
		return

	if pause_toggle_lock_frames > 0:
		return

	if Input.is_action_just_pressed("pause") and overlay_menu == null and not get_tree().paused:
		_open_overlay(0)

func _open_overlay(mode: int) -> void:
	if overlay_menu != null:
		return

	var menu = pause_menu_scene.instantiate()
	if menu.has_method("configure_mode"):
		menu.configure_mode(mode)

	if menu.has_signal("menu_closed") and not menu.menu_closed.is_connected(_on_overlay_closed):
		menu.menu_closed.connect(_on_overlay_closed)

	menu.tree_exited.connect(_on_overlay_tree_exited)
	get_tree().current_scene.add_child(menu)
	overlay_menu = menu
	pause_toggle_lock_frames = 2
	get_tree().paused = true

func _on_overlay_closed() -> void:
	overlay_menu = null
	pause_toggle_lock_frames = 2

func _on_overlay_tree_exited() -> void:
	overlay_menu = null
	pause_toggle_lock_frames = 2

func take_damage(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	if get_tree().paused:
		return

	player_state.apply_damage(amount)
	if player_state.current_health <= 0:
		_handle_player_death()

func _handle_player_death() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO
	_open_overlay(1)
		

func _on_animated_sprite_2d_frame_changed() -> void:
	if anim.animation == "throw" and anim.frame == 1 and not has_spawned_projectile:
		has_spawned_projectile = true
		spawn_projectile()

func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "attack":
		attack_area.monitoring = false
		attack_shape.disabled = true

		if not is_on_floor():
			change_state(PlayerState.FALL)
		elif abs(Input.get_axis("move_left", "move_right")) > 0.1:
			change_state(PlayerState.RUN)
		else:
			change_state(PlayerState.IDLE)

	elif anim.animation == "throw":
		if not is_on_floor():
			change_state(PlayerState.FALL)
		elif abs(Input.get_axis("move_left", "move_right")) > 0.1:
			change_state(PlayerState.RUN)
		else:
			change_state(PlayerState.IDLE)

func _on_dash_timer_timeout() -> void:
	hurtbox.monitoring = true
	hurtbox.monitorable = true
	hurtbox_shape.disabled = false
	anim.modulate.a = 1.0

	if not is_on_floor():
		change_state(PlayerState.FALL)
	elif abs(Input.get_axis("move_left", "move_right")) > 0.1:
		change_state(PlayerState.RUN)
	else:
		change_state(PlayerState.IDLE)
