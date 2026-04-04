extends CharacterBody2D

enum State { 
	IDLE, 
	NORMAL_ATTACK, 
	BIG_ATTACK, 
	DEAD 
}

@export var move_speed: float = 60.0
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
@export var waypoint_radius: float = 80.0
@export var big_attack_dash_speed: float = 400.0
@export var big_attack_dash_start_frame: int = 3

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

var state: State = State.IDLE
var move_direction: Vector2 = Vector2.RIGHT
var change_direction_timer: float = 0.0
var attack_timer: float = 0.0
var health: int = 3
var assigned_waypoint: Node2D = null
var dash_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	randomize()
	move_direction = Vector2.LEFT if start_facing_left else Vector2.RIGHT
	reset_direction_timer()
	reset_attack_timer()
	_change_state(State.IDLE)

func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			_process_idle(delta)
		State.NORMAL_ATTACK, State.BIG_ATTACK:
			velocity = dash_velocity
			velocity.y = 0.0
			_update_attack_boxes_and_flame()

	move_and_slide()
	_enforce_bounds()

func _assign_nearest_waypoint() -> void:
	var waypoints := get_tree().get_nodes_in_group("waypoints")
	if waypoints.is_empty():
		return
	var nearest: Node2D = null
	var nearest_dist := INF
	for wp in waypoints:
		var d: float = global_position.distance_to(wp.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = wp
	assigned_waypoint = nearest

# ── State transitions ──────────────────────────────────────────

func _change_state(new_state: State) -> void:
	# --- exit current state ---
	match state:
		State.NORMAL_ATTACK:
			attack_sprite.stop()
			_assign_nearest_waypoint()
			update_facing()
		State.BIG_ATTACK:
			big_attack_sprite.stop()
			flame_sprite.visible = false
			flame_sprite.stop()
			_assign_nearest_waypoint()
			update_facing()

	state = new_state

	# --- disable all hitboxes and sprites ---
	_set_hitbox(hitbox, hitbox_shape, false)
	_set_hitbox(big_hitbox, big_hitbox_shape, false)
	idle_sprite.visible = false
	attack_sprite.visible = false
	big_attack_sprite.visible = false
	flame_sprite.visible = false

	# --- enter new state ---
	match state:
		State.IDLE:
			hurtbox.monitoring = true
			hurtbox.monitorable = true
			hurtbox_shape.disabled = false
			idle_sprite.visible = true
			idle_sprite.play("idle")
			reset_attack_timer()
			reset_direction_timer()

		State.NORMAL_ATTACK:
			attack_sprite.visible = true
			attack_sprite.play("attack")
			attack_sprite.frame = 0
			var center := get_viewport_rect().size / 2
			var to_center := (center - global_position).normalized()
			dash_velocity = Vector2(to_center.x, 0) * big_attack_dash_speed
			move_direction = to_center

		State.BIG_ATTACK:
			big_attack_sprite.visible = true
			big_attack_sprite.play("attack")
			big_attack_sprite.frame = 0
			var center := get_viewport_rect().size / 2
			var to_center := (center - global_position).normalized()
			dash_velocity = Vector2(to_center.x, 0) * big_attack_dash_speed
			move_direction = to_center

		State.DEAD:
			_set_hitbox(hurtbox, hurtbox_shape, false)
			queue_free()

# ── IDLE processing ────────────────────────────────────────────

func _process_idle(delta: float) -> void:
	change_direction_timer -= delta
	attack_timer -= delta

	if change_direction_timer <= 0.0:
		pick_new_direction()
		reset_direction_timer()

	if attack_timer <= 0.0:
		var next := State.NORMAL_ATTACK if randf() <= normal_attack_chance else State.BIG_ATTACK
		_change_state(next)
		return

	velocity = move_direction * move_speed
	
	if assigned_waypoint != null:
		var to_waypoint := assigned_waypoint.global_position - global_position
		if to_waypoint.length() > waypoint_radius:
			move_direction = to_waypoint.normalized()
			reset_direction_timer()

	if is_on_wall():
		move_direction = move_direction.bounce(get_wall_normal()).normalized()
		reset_direction_timer()

# ── Attack box / flame logic ───────────────────────────────────

func _update_attack_boxes_and_flame() -> void:
	match state:
		State.NORMAL_ATTACK:
			var active := attack_sprite.animation == "attack" \
				and attack_sprite.frame >= attack_hitbox_start_frame
			_set_hitbox(hitbox, hitbox_shape, active)

		State.BIG_ATTACK:
			if big_attack_sprite.animation == "attack":
				var f := big_attack_sprite.frame
				var flame_active := f >= big_flame_start_frame and f <= big_flame_end_frame
				var hit_active := f >= big_hitbox_start_frame and f <= big_hitbox_end_frame

				_set_hitbox(big_hitbox, big_hitbox_shape, hit_active)

				if flame_active:
					flame_sprite.visible = true
					if not flame_sprite.is_playing():
						flame_sprite.play("flame")
				else:
					flame_sprite.visible = false
					flame_sprite.stop()
			else:
				_set_hitbox(big_hitbox, big_hitbox_shape, false)
				flame_sprite.visible = false
				flame_sprite.stop()

# ── Helpers ────────────────────────────────────────────────────

func _enforce_bounds() -> void:
	if global_position.y < top_limit_y:
		global_position.y = top_limit_y
		if move_direction.y < 0.0:
			move_direction.y = abs(move_direction.y)
			move_direction = move_direction.normalized()
		if state == State.IDLE:
			reset_direction_timer()

func _set_hitbox(box: Area2D, shape: CollisionShape2D, active: bool) -> void:
	box.monitoring = active
	box.monitorable = active
	shape.disabled = not active

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
	scale.x = -scale.x

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		_change_state(State.DEAD)

# ── Animation signals ──────────────────────────────────────────

func _on_attack_animation_finished() -> void:
	if state == State.NORMAL_ATTACK:
		_change_state(State.IDLE)

func _on_big_attack_animation_finished() -> void:
	if state == State.BIG_ATTACK:
		_change_state(State.IDLE)
