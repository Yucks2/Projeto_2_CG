extends Camera3D

# O recuo diagonal que calculamos nos passos anteriores
@export var offset: Vector3 = Vector3(60, 25, 5)

var bola_alvo: RigidBody3D

func _ready() -> void:
	# Busca o nó da bola automaticamente na cena principal
	bola_alvo = get_node("../bola") 

func _process(delta: float) -> void:
	if bola_alvo:
		# A câmera segue suavemente ou diretamente a posição da bola no campo
		global_position = bola_alvo.global_position + offset
