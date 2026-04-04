extends Area2D

@export var speed: float = 220.0
@export var life_time: float = 3.0
var direction: float = 1.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	position.x += speed * direction * delta

	life_time -= delta
	if life_time <= 0.0:
		queue_free()

func set_direction(dir: float) -> void:
	direction = sign(dir)
	scale.x = direction

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# body.take_damage(1)
		queue_free()
	elif not body.is_in_group("enemy"):
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		# var p = area.get_parent()
		# if p.has_method("take_damage"):
		# 	p.take_damage(1)
		queue_free()
