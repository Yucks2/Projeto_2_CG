extends Camera3D

@export_group("Configurações da Câmera")
@export var velocidade_suavizacao : float = 5.0

@onready var alvo: RigidBody3D = get_tree().get_first_node_in_group("bola")

var deslocamento_inicial : Vector3

func _ready() -> void:
	if is_instance_valid(alvo):
		deslocamento_inicial = global_position - alvo.global_position

func _physics_process(delta: float) -> void:
	if is_instance_valid(alvo):
		var posicao_desejada = alvo.global_position + deslocamento_inicial
		
		global_position = global_position.lerp(posicao_desejada, velocidade_suavizacao * delta)
