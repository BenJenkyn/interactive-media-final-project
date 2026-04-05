extends CharacterBody2D

enum State {
	IDLE,
	HIGH_DASH_ATTACK,
	CLOSE_ATTACK,
	DEAD
}

@export var move_speed: float = 60.0
@export var direction_change_time_min: float = 1.0
@export var direction_change_time_max: float = 2.5
@export var attack_time_min: float = 4.0
@export var attack_time_max: float = 8.0
@export var top_limit_y: float = 80.0
@export var start_facing_left: bool = true

@export var max_health: int = 2
@export var big_attack_damage: int = 1
@export var small_attack_damage: int = 1

@export var big_flame_start_frame: int = 6
@export var big_flame_end_frame: int = 15
@export var big_hitbox_start_frame: int = 7
@export var big_hitbox_end_frame: int = 14

@export var waypoint_radius: float = 80.0
@export var high_dash_attack_dash_speed: float = 400.0

@export var close_attack_speed: float = 150.0
@export var close_attack_range: float = 200.0
@export var close_attack_flame_start_frame: int = 6
@export var close_attack_flame_end_frame: int = 15
@export var close_attack_hitbox_start_frame: int = 7
@export var close_attack_hitbox_end_frame: int = 14

@onready var idle_sprite: AnimatedSprite2D = $Idle
@onready var high_dash_attack_sprite: AnimatedSprite2D = $BigAttack
@onready var blue_flame_sprite: AnimatedSprite2D = $FlameBlue
@onready var orange_flame_sprite: AnimatedSprite2D = $FlameOrange

@onready var hurtbox: Area2D = $Hurtbox
@onready var hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D

@onready var big_hitbox: Area2D = $BigHitbox
@onready var big_hitbox_shape: CollisionShape2D = $BigHitbox/CollisionShape2D

@onready var small_hitbox: Area2D = $SmallHitbox
@onready var small_hitbox_shape: CollisionShape2D = $SmallHitbox/CollisionShape2D

var state: State = State.IDLE
var move_direction: Vector2 = Vector2.RIGHT
var change_direction_timer: float = 0.0
var attack_timer: float = 0.0
var health: int = 0
var assigned_waypoint: Node2D = null
var dash_velocity: Vector2 = Vector2.ZERO
var close_attack_target: Vector2 = Vector2.ZERO
var close_attack_returning: bool = false
var is_dead: bool = false

var big_attack_hit_targets: Array[Node] = []
var small_attack_hit_targets: Array[Node] = []

func _ready() -> void:
	randomize()
	health = max_health
	move_direction = Vector2.LEFT if start_facing_left else Vector2.RIGHT

	hurtbox.area_entered.connect(_on_hurtbox_area_entered)

	big_hitbox.body_entered.connect(_on_big_hitbox_body_entered)
	big_hitbox.area_entered.connect(_on_big_hitbox_area_entered)

	small_hitbox.body_entered.connect(_on_small_hitbox_body_entered)
	small_hitbox.area_entered.connect(_on_small_hitbox_area_entered)

	reset_direction_timer()
	reset_attack_timer()
	_change_state(State.IDLE)
	_assign_nearest_waypoint()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	match state:
		State.IDLE:
			_process_idle(delta)

		State.HIGH_DASH_ATTACK:
			velocity = dash_velocity
			velocity.y = 0.0
			_update_attack_boxes_and_flame()

		State.CLOSE_ATTACK:
			_process_close_attack(delta)

		State.DEAD:
			velocity = Vector2.ZERO

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

	if nearest == null:
		return

	var is_right := nearest.name.contains("Right")
	var side := "Right" if is_right else "Left"
	var vertical := "Top" if randf() < 0.5 else "Bottom"
	var target_name := vertical + side + "Marker"

	for wp in waypoints:
		if wp.name == target_name:
			assigned_waypoint = wp
			return

func _change_state(new_state: State) -> void:
	match state:
		State.HIGH_DASH_ATTACK:
			high_dash_attack_sprite.stop()
			blue_flame_sprite.visible = false
			blue_flame_sprite.stop()
			_assign_nearest_waypoint()
			update_facing()

		State.CLOSE_ATTACK:
			high_dash_attack_sprite.stop()
			orange_flame_sprite.visible = false
			orange_flame_sprite.stop()
			_assign_nearest_waypoint()
			close_attack_returning = false

	state = new_state

	_set_hitbox(big_hitbox, big_hitbox_shape, false)
	_set_hitbox(small_hitbox, small_hitbox_shape, false)

	idle_sprite.visible = false
	high_dash_attack_sprite.visible = false
	blue_flame_sprite.visible = false
	orange_flame_sprite.visible = false

	big_attack_hit_targets.clear()
	small_attack_hit_targets.clear()

	match state:
		State.IDLE:
			hurtbox.monitoring = true
			hurtbox.monitorable = true
			hurtbox_shape.disabled = false
			idle_sprite.visible = true
			idle_sprite.play("idle")
			reset_attack_timer()
			reset_direction_timer()

		State.HIGH_DASH_ATTACK:
			high_dash_attack_sprite.visible = true
			high_dash_attack_sprite.play("attack")
			high_dash_attack_sprite.frame = 0

			var center := get_viewport_rect().size / 2.0
			var to_center := (center - global_position).normalized()
			dash_velocity = Vector2(to_center.x, 0.0) * high_dash_attack_dash_speed
			move_direction = to_center

		State.CLOSE_ATTACK:
			var player = get_tree().get_first_node_in_group("player")
			if player != null:
				close_attack_target = player.global_position

			high_dash_attack_sprite.visible = true
			high_dash_attack_sprite.play("attack")
			high_dash_attack_sprite.frame = 0
			close_attack_returning = false

		State.DEAD:
			_set_hitbox(hurtbox, hurtbox_shape, false)
			_set_hitbox(big_hitbox, big_hitbox_shape, false)
			_set_hitbox(small_hitbox, small_hitbox_shape, false)
			queue_free()
			level_state.change_state(level_state.LevelStateEnum.LEVEL3)

func _process_idle(delta: float) -> void:
	change_direction_timer -= delta
	attack_timer -= delta

	if change_direction_timer <= 0.0:
		pick_new_direction()
		reset_direction_timer()

	if attack_timer <= 0.0:
		var player = get_tree().get_first_node_in_group("player")
		var attack_choice: State = State.HIGH_DASH_ATTACK

		if player != null:
			var distance_to_player := global_position.distance_to(player.global_position)
			if distance_to_player < close_attack_range and randf() < 0.5:
				attack_choice = State.CLOSE_ATTACK

		_change_state(attack_choice)
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

func _process_close_attack(delta: float) -> void:
	if not close_attack_returning:
		var to_target := close_attack_target - global_position
		if to_target.length() > 20.0:
			velocity = to_target.normalized() * close_attack_speed
			move_direction = to_target.normalized()
		else:
			velocity = Vector2.ZERO
			if high_dash_attack_sprite.frame >= close_attack_flame_start_frame:
				close_attack_returning = true
	else:
		if assigned_waypoint != null:
			var to_waypoint := assigned_waypoint.global_position - global_position
			if to_waypoint.length() > 10.0:
				velocity = to_waypoint.normalized() * close_attack_speed
			else:
				velocity = Vector2.ZERO

	_update_attack_boxes_and_flame()

func _update_attack_boxes_and_flame() -> void:
	match state:
		State.HIGH_DASH_ATTACK:
			if high_dash_attack_sprite.animation == "attack":
				var f := high_dash_attack_sprite.frame
				var flame_active := f >= big_flame_start_frame and f <= big_flame_end_frame
				var hit_active := f >= big_hitbox_start_frame and f <= big_hitbox_end_frame

				_set_hitbox(big_hitbox, big_hitbox_shape, hit_active)
				_set_hitbox(small_hitbox, small_hitbox_shape, false)

				if flame_active:
					blue_flame_sprite.visible = true
					if not blue_flame_sprite.is_playing():
						blue_flame_sprite.play("flame")
				else:
					blue_flame_sprite.visible = false
					blue_flame_sprite.stop()
			else:
				_set_hitbox(big_hitbox, big_hitbox_shape, false)
				_set_hitbox(small_hitbox, small_hitbox_shape, false)
				blue_flame_sprite.visible = false
				blue_flame_sprite.stop()

		State.CLOSE_ATTACK:
			if high_dash_attack_sprite.animation == "attack":
				var f := high_dash_attack_sprite.frame
				var flame_active := f >= close_attack_flame_start_frame and f <= close_attack_flame_end_frame
				var hit_active := f >= close_attack_hitbox_start_frame and f <= close_attack_hitbox_end_frame

				_set_hitbox(small_hitbox, small_hitbox_shape, hit_active)
				_set_hitbox(big_hitbox, big_hitbox_shape, false)

				if flame_active:
					orange_flame_sprite.visible = true
					if not orange_flame_sprite.is_playing():
						orange_flame_sprite.play("flame")
				else:
					orange_flame_sprite.visible = false
					orange_flame_sprite.stop()
			else:
				_set_hitbox(small_hitbox, small_hitbox_shape, false)
				_set_hitbox(big_hitbox, big_hitbox_shape, false)
				orange_flame_sprite.visible = false
				orange_flame_sprite.stop()

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
	if is_dead:
		return

	health -= amount
	print("Dragon health: ", health)

	idle_sprite.modulate = Color(1, 0.3, 0.3)
	high_dash_attack_sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout

	if not is_dead:
		idle_sprite.modulate = Color(1, 1, 1)
		high_dash_attack_sprite.modulate = Color(1, 1, 1)

	if health <= 0:
		is_dead = true
		_change_state(State.DEAD)

func _damage_node_once(target: Node, damage: int, hit_list: Array[Node]) -> void:
	if target == null:
		return

	if target in hit_list:
		return

	hit_list.append(target)

	if target.has_method("take_damage"):
		target.take_damage(damage)
	elif target.get_parent() != null and target.get_parent().has_method("take_damage"):
		target.get_parent().take_damage(damage)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if is_dead:
		return

	if area.is_in_group("player_attack"):
		take_damage(1)

func _on_big_hitbox_body_entered(body: Node) -> void:
	if is_dead:
		return

	if body.is_in_group("player"):
		_damage_node_once(body, big_attack_damage, big_attack_hit_targets)

func _on_big_hitbox_area_entered(area: Area2D) -> void:
	if is_dead:
		return

	if area.is_in_group("player_hurtbox"):
		_damage_node_once(area, big_attack_damage, big_attack_hit_targets)

func _on_small_hitbox_body_entered(body: Node) -> void:
	if is_dead:
		return

	if body.is_in_group("player"):
		_damage_node_once(body, small_attack_damage, small_attack_hit_targets)

func _on_small_hitbox_area_entered(area: Area2D) -> void:
	if is_dead:
		return

	if area.is_in_group("player_hurtbox"):
		_damage_node_once(area, small_attack_damage, small_attack_hit_targets)

func _on_big_attack_animation_finished() -> void:
	if state == State.HIGH_DASH_ATTACK:
		_change_state(State.IDLE)
	elif state == State.CLOSE_ATTACK:
		_change_state(State.IDLE)
