extends Area2D

@export var speed: float = 350.0
@export var damage: int = 1

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var direction: float = 1.0
var has_hit: bool = false

func _ready() -> void:
	anim.play("fly")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	notifier.screen_exited.connect(_on_screen_exited)
	anim.animation_finished.connect(_on_animation_finished)

func _process(delta: float) -> void:
	if has_hit:
		return

	position.x += direction * speed * delta

func setup(dir: float) -> void:
	direction = dir

	if direction < 0:
		scale.x = -1
	else:
		scale.x = 1

func hit() -> void:
	if has_hit:
		return

	has_hit = true
	collision_shape.set_deferred("disabled", true)
	anim.play("hit")

func _on_body_entered(body: Node) -> void:
	if has_hit:
		return

	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		hit()
		return

	if body.is_in_group("wall"):
		hit()
		return

	hit()

func _on_area_entered(area: Area2D) -> void:
	if has_hit:
		return

	if area.is_in_group("enemy_attack"):
		return

	if area.get_parent() != null and area.get_parent().is_in_group("enemy"):
		var enemy = area.get_parent()
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)
		hit()
		return

	hit()

func _on_animation_finished() -> void:
	if anim.animation == "hit":
		queue_free()

func _on_screen_exited() -> void:
	queue_free()
