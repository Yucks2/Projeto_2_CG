extends Camera3D

@export var offset: Vector3 = Vector3(60, 25, 5)

var bola_alvo: RigidBody3D

func _ready() -> void:
	bola_alvo = get_node("../bola") 

func _process(delta: float) -> void:
	if bola_alvo:
		global_position = bola_alvo.global_position + offset
