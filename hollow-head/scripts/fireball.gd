extends Area2D

@export var speed: float = 220.0
@export var life_time: float = 3.0
@export var damage: int = 1

var direction: float = 1.0
var has_hit: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if has_hit:
		return

	position.x += speed * direction * delta

	life_time -= delta
	if life_time <= 0.0:
		queue_free()

func set_direction(dir: float) -> void:
	direction = sign(dir)
	scale.x = direction

func _on_body_entered(body: Node) -> void:
	if has_hit:
		return

	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		has_hit = true
		queue_free()
		return

	if not body.is_in_group("enemy"):
		has_hit = true
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if has_hit:
		return

	if area.is_in_group("player_hurtbox"):
		var p = area.get_parent()
		if p != null and p.has_method("take_damage"):
			p.take_damage(damage)
		has_hit = true
		queue_free()
