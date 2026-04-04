extends CharacterBody2D

@export var move_speed: float = 60.0
@export var gravity: float = 0.0
@export var direction_change_time_min: float = 1.0
@export var direction_change_time_max: float = 2.5
@export var attack_time_min: float = 4.0
@export var attack_time_max: float = 8.0
@export var top_limit_y: float = 80.0
@export var start_facing_left: bool = true

@export var normal_attack_chance: float = 0.85

@export var attack_hitbox_start_frame: int = 6
@export var big_flame_start_frame: int = 6
@export var big_flame_end_frame: int = 15
@export var big_hitbox_start_frame: int = 7
@export var big_hitbox_end_frame: int = 14

@onready var idle_sprite: AnimatedSprite2D = $Idle
@onready var attack_sprite: AnimatedSprite2D = $Attack
@onready var big_attack_sprite: AnimatedSprite2D = $BigAttack
@onready var flame_sprite: AnimatedSprite2D = $Flame

@onready var hurtbox: Area2D = $Hurtbox
@onready var hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D

@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D

@onready var big_hitbox: Area2D = $BigHitbox
@onready var big_hitbox_shape: CollisionShape2D = $BigHitbox/CollisionShape2D

var move_direction: Vector2 = Vector2.RIGHT
var change_direction_timer: float = 0.0
var attack_timer: float = 0.0
var health: int = 3
var is_attacking: bool = false
var current_attack_type: String = ""

func _ready() -> void:
	randomize()

	idle_sprite.visible = true
	attack_sprite.visible = false
	big_attack_sprite.visible = false
	flame_sprite.visible = false

	hurtbox.monitoring = true
	hurtbox.monitorable = true
	hurtbox_shape.disabled = false

	hitbox.monitoring = false
	hitbox.monitorable = false
	hitbox_shape.disabled = true

	big_hitbox.monitoring = false
	big_hitbox.monitorable = false
	big_hitbox_shape.disabled = true

	if start_facing_left:
		move_direction = Vector2.LEFT
	else:
		move_direction = Vector2.RIGHT

	reset_direction_timer()
	reset_attack_timer()
	update_facing()

	if idle_sprite.sprite_frames and idle_sprite.sprite_frames.has_animation("idle"):
		idle_sprite.play("idle")

func _physics_process(delta: float) -> void:
	if not is_attacking:
		change_direction_timer -= delta
		attack_timer -= delta

		if change_direction_timer <= 0.0:
			pick_new_direction()
			reset_direction_timer()
			update_facing()

		if attack_timer <= 0.0:
			start_random_attack()

		velocity = move_direction * move_speed
	else:
		velocity = Vector2.ZERO
		update_attack_boxes_and_flame()

	move_and_slide()

	if not is_attacking and is_on_wall():
		move_direction = move_direction.bounce(get_wall_normal()).normalized()
		reset_direction_timer()
		update_facing()

	if global_position.y < top_limit_y:
		global_position.y = top_limit_y
		move_direction.y = abs(move_direction.y)
		move_direction = move_direction.normalized()

		if not is_attacking:
			reset_direction_timer()
			update_facing()

	play_animation()

func pick_new_direction() -> void:
	var x := randf_range(-1.0, 1.0)
	var y := randf_range(-0.8, 0.8)

	move_direction = Vector2(x, y).normalized()

	if move_direction == Vector2.ZERO:
		move_direction = Vector2.LEFT if start_facing_left else Vector2.RIGHT

	if global_position.y <= top_limit_y + 8.0 and move_direction.y < 0.0:
		move_direction.y = abs(move_direction.y)
		move_direction = move_direction.normalized()

func reset_direction_timer() -> void:
	change_direction_timer = randf_range(direction_change_time_min, direction_change_time_max)

func reset_attack_timer() -> void:
	attack_timer = randf_range(attack_time_min, attack_time_max)

func update_facing() -> void:
	if move_direction.x < 0.0:
		scale.x = -1
	else:
		scale.x = 1

func play_animation() -> void:
	if is_attacking:
		idle_sprite.visible = false

		if current_attack_type == "normal":
			attack_sprite.visible = true
			big_attack_sprite.visible = false

			if attack_sprite.sprite_frames and attack_sprite.sprite_frames.has_animation("attack"):
				if attack_sprite.animation != "attack" or not attack_sprite.is_playing():
					attack_sprite.play("attack")

		elif current_attack_type == "big":
			attack_sprite.visible = false
			big_attack_sprite.visible = true

			if big_attack_sprite.sprite_frames and big_attack_sprite.sprite_frames.has_animation("attack"):
				if big_attack_sprite.animation != "attack" or not big_attack_sprite.is_playing():
					big_attack_sprite.play("attack")
		return

	attack_sprite.visible = false
	big_attack_sprite.visible = false
	flame_sprite.visible = false
	idle_sprite.visible = true

	if idle_sprite.sprite_frames and idle_sprite.sprite_frames.has_animation("idle"):
		if idle_sprite.animation != "idle" or not idle_sprite.is_playing():
			idle_sprite.play("idle")

func update_attack_boxes_and_flame() -> void:
	hitbox.monitoring = false
	hitbox.monitorable = false
	hitbox_shape.disabled = true

	big_hitbox.monitoring = false
	big_hitbox.monitorable = false
	big_hitbox_shape.disabled = true

	if current_attack_type == "normal":
		flame_sprite.visible = false
		flame_sprite.stop()

		if attack_sprite.animation == "attack" and attack_sprite.frame >= attack_hitbox_start_frame:
			hitbox.monitoring = true
			hitbox.monitorable = true
			hitbox_shape.disabled = false

	elif current_attack_type == "big":
		if big_attack_sprite.animation == "attack":
			var frame := big_attack_sprite.frame
			var flame_active := frame >= big_flame_start_frame and frame <= big_flame_end_frame
			var hitbox_active := frame >= big_hitbox_start_frame and frame <= big_hitbox_end_frame

			if flame_active:
				flame_sprite.visible = true

				if flame_sprite.sprite_frames and flame_sprite.sprite_frames.has_animation("flame"):
					if flame_sprite.animation != "flame":
						flame_sprite.play("flame")
					elif not flame_sprite.is_playing():
						flame_sprite.play()

			else:
				flame_sprite.visible = false
				flame_sprite.stop()

			if hitbox_active:
				big_hitbox.monitoring = true
				big_hitbox.monitorable = true
				big_hitbox_shape.disabled = false
		else:
			flame_sprite.visible = false
			flame_sprite.stop()
	else:
		flame_sprite.visible = false
		flame_sprite.stop()

func start_random_attack() -> void:
	if is_attacking:
		return

	var roll := randf()

	if roll <= normal_attack_chance:
		start_attack()
	else:
		start_big_attack()

func start_attack() -> void:
	if is_attacking:
		return

	is_attacking = true
	current_attack_type = "normal"

	hitbox.monitoring = false
	hitbox.monitorable = false
	hitbox_shape.disabled = true

	big_hitbox.monitoring = false
	big_hitbox.monitorable = false
	big_hitbox_shape.disabled = true

	flame_sprite.visible = false
	flame_sprite.stop()

	idle_sprite.visible = false
	attack_sprite.visible = true
	big_attack_sprite.visible = false

	if attack_sprite.sprite_frames and attack_sprite.sprite_frames.has_animation("attack"):
		attack_sprite.play("attack")
		attack_sprite.frame = 0

func start_big_attack() -> void:
	if is_attacking:
		return

	is_attacking = true
	current_attack_type = "big"

	hitbox.monitoring = false
	hitbox.monitorable = false
	hitbox_shape.disabled = true

	big_hitbox.monitoring = false
	big_hitbox.monitorable = false
	big_hitbox_shape.disabled = true

	flame_sprite.visible = false
	flame_sprite.stop()

	idle_sprite.visible = false
	attack_sprite.visible = false
	big_attack_sprite.visible = true

	if big_attack_sprite.sprite_frames and big_attack_sprite.sprite_frames.has_animation("attack"):
		big_attack_sprite.play("attack")
		big_attack_sprite.frame = 0

func end_attack() -> void:
	is_attacking = false
	current_attack_type = ""

	hitbox.monitoring = false
	hitbox.monitorable = false
	hitbox_shape.disabled = true

	big_hitbox.monitoring = false
	big_hitbox.monitorable = false
	big_hitbox_shape.disabled = true

	flame_sprite.visible = false
	flame_sprite.stop()

	attack_sprite.visible = false
	big_attack_sprite.visible = false

	reset_attack_timer()
	reset_direction_timer()
	play_animation()

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()

func _on_attack_animation_finished() -> void:
	if current_attack_type == "normal":
		end_attack()

func _on_big_attack_animation_finished() -> void:
	if current_attack_type == "big":
		end_attack()
