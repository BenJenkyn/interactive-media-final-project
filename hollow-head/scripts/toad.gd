extends CharacterBody2D

@export var move_speed: float = 60.0
@export var gravity: float = 900.0
@export var jump_force: float = -300.0
@export var min_jump_wait: float = 1.5
@export var max_jump_wait: float = 3.5

@export var jump_hurtbox_offset_y: float = -12.0

@export var max_health: int = 3
@export var attack_damage: int = 1
@export var attack_range: float = 45.0
@export var attack_cooldown: float = 1.2
@export var attack_active_time: float = 0.2
@export var attack_area_x_offset: float = 28.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D

var player: Node2D = null
var jump_timer: float = 0.0

var hurtbox_start_pos: Vector2
var body_collision_start_pos: Vector2
var attack_area_start_pos: Vector2

var health: int = 0
var is_attacking: bool = false
var can_attack: bool = true
var attack_has_hit: bool = false
var is_dead: bool = false

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D

	hurtbox_start_pos = hurtbox.position
	body_collision_start_pos = body_collision.position
	attack_area_start_pos = attack_area.position

	health = max_health

	attack_area.monitoring = true
	attack_shape.disabled = true

	attack_area.body_entered.connect(_on_attack_area_body_entered)

	anim.play("idle")
	_reset_jump_timer()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if player != null and not is_attacking:
		var distance_to_player: float = global_position.distance_to(player.global_position)
		var direction: float = sign(player.global_position.x - global_position.x)

		if direction != 0.0:
			anim.flip_h = direction < 0.0
			_update_attack_area_side(direction)

		if distance_to_player > attack_range:
			velocity.x = direction * move_speed
		else:
			velocity.x = 0.0
			if can_attack and is_on_floor():
				_start_attack()
	else:
		if not is_attacking:
			velocity.x = 0.0

	if is_on_floor() and not is_attacking:
		jump_timer -= delta
		if jump_timer <= 0.0:
			_do_jump()

	if not is_attacking:
		if not is_on_floor():
			if anim.animation != "jump":
				anim.play("jump")
			_apply_jump_offsets()
		else:
			if anim.animation != "idle":
				anim.play("idle")
			_reset_jump_offsets()

	move_and_slide()

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

func _start_attack() -> void:
	if is_dead:
		return

	is_attacking = true
	can_attack = false
	attack_has_hit = false
	velocity.x = 0.0
	_reset_jump_offsets()
	anim.play("attack")

func _finish_attack() -> void:
	is_attacking = false
	_disable_attack_hitbox()

	await get_tree().create_timer(attack_cooldown).timeout

	if not is_dead:
		can_attack = true

func _enable_attack_hitbox() -> void:
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

func _update_attack_area_side(direction: float) -> void:
	var new_x: float = abs(attack_area_x_offset)

	if direction < 0.0:
		new_x = -new_x

	attack_area.position.x = new_x

func _do_jump() -> void:
	velocity.y = jump_force
	anim.play("jump")
	_reset_jump_timer()

func _reset_jump_timer() -> void:
	jump_timer = randf_range(min_jump_wait, max_jump_wait)

func _apply_jump_offsets() -> void:
	hurtbox.position = hurtbox_start_pos + Vector2(0.0, jump_hurtbox_offset_y)
	body_collision.position = body_collision_start_pos + Vector2(0.0, jump_hurtbox_offset_y)
	attack_area.position.y = attack_area_start_pos.y + jump_hurtbox_offset_y

func _reset_jump_offsets() -> void:
	hurtbox.position = hurtbox_start_pos
	body_collision.position = body_collision_start_pos
	attack_area.position.y = attack_area_start_pos.y

func take_damage(amount: int) -> void:
	if is_dead:
		return

	health -= amount

	if health <= 0:
		die()

func die() -> void:
	is_dead = true
	queue_free()
