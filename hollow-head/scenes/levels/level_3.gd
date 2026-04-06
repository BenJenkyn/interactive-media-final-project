extends Node2D

@export var spawn_effect_scene: PackedScene
@export var lava_flow_speed: float = 1.4
@export var lava_flow_distance: float = 18.0

@onready var beast = $Beast
@onready var player = $Player
@onready var respawn_point = $TeleportPoints/Point3
@onready var lava_flow_image: TextureRect = $CanvasLayer/LavaFlowImage
@onready var lava_flow_image_2: TextureRect = $CanvasLayer/LavaFlowImage2
@onready var lava_flow_image_3: TextureRect = $CanvasLayer/LavaFlowImage3

var lava_flow_time: float = 0.0
var lava_flow_base_x: float = 0.0
var lava_flow_2_base_x: float = 0.0
var lava_flow_3_base_x: float = 0.0

func _ready() -> void:
	player.set_respawn_point(respawn_point)
	lava_flow_base_x = lava_flow_image.position.x
	lava_flow_2_base_x = lava_flow_image_2.position.x
	lava_flow_3_base_x = lava_flow_image_3.position.x
	
	beast.visible = false
	spawn_beast_effect()

func _process(delta: float) -> void:
	lava_flow_time += delta
	lava_flow_image.position.x = lava_flow_base_x + sin((lava_flow_time * lava_flow_speed)/2) * lava_flow_distance
	lava_flow_image_2.position.x = lava_flow_2_base_x + cos(lava_flow_time * lava_flow_speed) * lava_flow_distance
	lava_flow_image_3.position.x = lava_flow_3_base_x + sin(lava_flow_time * lava_flow_speed) * lava_flow_distance

func spawn_beast_effect() -> void:
	if spawn_effect_scene == null:
		return

	var effect = spawn_effect_scene.instantiate()
	effect.global_position = beast.global_position
	add_child(effect)

	effect.spawn_finished.connect(_on_spawn_finished)

func _on_spawn_finished() -> void:
	beast.visible = true
