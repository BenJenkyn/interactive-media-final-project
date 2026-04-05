extends CharacterBody2D

enum PlayerState {
	IDLE,
	RUN,
	JUMP,
	FALL,
	ATTACK,
	THROW,
	DODGE,
	HURT,
	DEAD
}

@export var speed: float = 230.0
@export var jump_velocity: float = -600.0
@export var gravity: float = 900.0
@export var projectile_scene: PackedScene

@export var dodge_speed: float = 500.0
@export var dodge_time: float = 0.30

@export var max_health: int = 5
@export var invincibility_time: float = 0.5

@export var contact_knockback_x: float = 220.0
@export var contact_knockback_y: float = -160.0
@export var hurt_time: float = 0.18

@export var throw_unlocked: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var projectile_spawn: Marker2D = $ProjectileSpawn
@onready var dash_timer: Timer = $DashTimer
@onready var hurtbox: Area2D = $Hurtbox
@onready var hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D

var state: PlayerState = PlayerState.IDLE

var facing: float = 1.0
var attack_facing: float = 1.0
var throw_facing: float = 1.0
var dodge_facing: float = 1.0

var has_spawned_projectile: bool = false

var dodge_flash_timer: float = 0.0
var dodge_flash_interval: float = 0.05

var current_health: int
var can_take_damage: bool = true
var hurt_source_x: float = 0.0

func _ready() -> void:
	current_health = max_health
	player_state.max_health = max_health
	player_state.current_health = current_health

	throw_unlocked = player_state.throw_unlocked

	attack_area.monitoring = false
	attack_shape.disabled = true
	dash_timer.one_shot = true
	dash_timer.wait_time = dodge_time
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	change_state(PlayerState.IDLE)

func _physics_process(delta: float) -> void:
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
		PlayerState.HURT:
			_state_hurt()
		PlayerState.DEAD:
			_state_dead()

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

		PlayerState.HURT:
			anim.modulate.a = 1.0
			if anim.sprite_frames.has_animation("hurt"):
				anim.play("hurt")
			else:
				anim.play("idle")

		PlayerState.DEAD:
			anim.modulate.a = 1.0
			if anim.sprite_frames.has_animation("dead"):
				anim.play("dead")
			else:
				anim.play("idle")

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

	if throw_unlocked and Input.is_action_just_pressed("throw"):
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

	if throw_unlocked and Input.is_action_just_pressed("throw"):
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

	if Input.is_action_just_pressed("attack"):
		change_state(PlayerState.ATTACK)
		return

	if throw_unlocked and Input.is_action_just_pressed("throw"):
		change_state(PlayerState.THROW)
		return

	if velocity.y > 0:
		change_state(PlayerState.FALL)

func _state_fall(input_x: float) -> void:
	velocity.x = input_x * speed

	if input_x < 0:
		facing = -1.0
	elif input_x > 0:
		facing = 1.0

	_update_facing_visuals()

	if Input.is_action_just_pressed("attack"):
		change_state(PlayerState.ATTACK)
		return

	if throw_unlocked and Input.is_action_just_pressed("throw"):
		change_state(PlayerState.THROW)
		return

	if is_on_floor():
		if abs(input_x) > 0.1:
			change_state(PlayerState.RUN)
		else:
			change_state(PlayerState.IDLE)

func _state_attack() -> void:
	var input_x := Input.get_axis("move_left", "move_right")

	velocity.x = input_x * speed

	if input_x < 0:
		facing = -1.0
	elif input_x > 0:
		facing = 1.0

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

func _state_hurt() -> void:
	_update_facing_visuals()

func _state_dead() -> void:
	velocity.x = 0.0

func _update_air_state() -> void:
	if state == PlayerState.ATTACK or state == PlayerState.THROW or state == PlayerState.DODGE or state == PlayerState.HURT or state == PlayerState.DEAD:
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

func unlock_throw() -> void:
	throw_unlocked = true
	player_state.throw_unlocked = true
	print("Throw unlocked")

func take_damage(amount: int) -> void:
	if state == PlayerState.DODGE:
		return

	if not can_take_damage:
		return

	if state == PlayerState.DEAD:
		return

	can_take_damage = false
	current_health -= amount
	current_health = max(current_health, 0)
	player_state.current_health = current_health

	print("Player health: ", current_health)

	if current_health <= 0:
		change_state(PlayerState.DEAD)
		return

	var knockback_dir := 1.0
	if global_position.x < hurt_source_x:
		knockback_dir = -1.0

	velocity.x = contact_knockback_x * knockback_dir
	velocity.y = contact_knockback_y

	change_state(PlayerState.HURT)

	await get_tree().create_timer(hurt_time).timeout

	if state != PlayerState.DEAD:
		if not is_on_floor():
			change_state(PlayerState.FALL)
		else:
			change_state(PlayerState.IDLE)

	await get_tree().create_timer(invincibility_time).timeout

	if state != PlayerState.DEAD:
		can_take_damage = true

func heal(amount: int) -> void:
	current_health += amount
	current_health = min(current_health, max_health)
	player_state.current_health = current_health

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if not can_take_damage:
		return

	if area.is_in_group("enemy_attack"):
		take_damage(1)

func _on_hurtbox_body_entered(body: Node) -> void:
	if not can_take_damage:
		return

	if body.is_in_group("enemy"):
		if body is Node2D:
			hurt_source_x = body.global_position.x
		else:
			hurt_source_x = global_position.x

		take_damage(1)

func _on_animated_sprite_2d_frame_changed() -> void:
	if anim.animation == "throw" and anim.frame == 1 and not has_spawned_projectile:
		has_spawned_projectile = true
		spawn_projectile()

func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "attack":
		attack_area.monitoring = false
		attack_shape.disabled = true

		var input_x := Input.get_axis("move_left", "move_right")

		if not is_on_floor():
			if velocity.y < 0:
				change_state(PlayerState.JUMP)
			else:
				change_state(PlayerState.FALL)
		elif abs(input_x) > 0.1:
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
