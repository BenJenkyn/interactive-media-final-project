extends Area2D

@export var speed: float = 350.0

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
	collision_shape.disabled = true
	anim.play("hit")

func _on_body_entered(_body: Node) -> void:
	hit()

func _on_area_entered(_area: Area2D) -> void:
	hit()

func _on_animation_finished() -> void:
	if anim.animation == "hit":
		queue_free()

func _on_screen_exited() -> void:
	queue_free()
