extends CharacterBody3D

@export_group("Configurações do Goleiro")
@export var velocidade_goleiro : float = 10.0
@export var limite_da_trave : float = 10.0
@export var mover_no_eixo_x : bool = true

@export_group("Configurações de Pulo")
@export var forca_do_pulo : float = 15
@export var altura_para_pular : float = 5.0 
@export var distancia_de_reacao : float = 50.0 

@export_group("Animações")
@export var anim_idle : String = "Armature|idle"
@export var anim_andar : String = "Armature|novopique"
@export var anim_pular : String = "Armature|goleiro"

@onready var bola_ref: RigidBody3D = get_tree().get_first_node_in_group("bola")

@onready var animation_player: AnimationPlayer = $new_octa_laranja/AnimationPlayer

var posicao_inicial : Vector3

func _ready() -> void:
	posicao_inicial = global_position
	add_to_group("goleiros")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(bola_ref):
		return
	var pulando = false

	if not is_on_floor():
		velocity += get_gravity() * delta
		pulando = true
	else:
		var distancia_bola = global_position.distance_to(bola_ref.global_position)
		var altura_bola = bola_ref.global_position.y - global_position.y		
		if distancia_bola < distancia_de_reacao and altura_bola > altura_para_pular:
			velocity.y = forca_do_pulo
			pulando = true
	velocity.x = 0
	velocity.z = 0

	move_and_slide()

	var alvo_posicao = global_position
	
	if mover_no_eixo_x:
		alvo_posicao.x = bola_ref.global_position.x
		alvo_posicao.x = clamp(alvo_posicao.x, posicao_inicial.x - limite_da_trave, posicao_inicial.x + limite_da_trave)
		alvo_posicao.z = posicao_inicial.z 
	else:
		alvo_posicao.z = bola_ref.global_position.z
		alvo_posicao.z = clamp(alvo_posicao.z, posicao_inicial.z - limite_da_trave, posicao_inicial.z + limite_da_trave)
		alvo_posicao.x = posicao_inicial.x		
	alvo_posicao.y = global_position.y
	
	var pos_anterior = global_position
	
	global_position = global_position.move_toward(alvo_posicao, velocidade_goleiro * delta)
	
	var movendo_lateralmente = global_position.distance_to(pos_anterior) > 0.01

	var olhar_bola = bola_ref.global_position
	olhar_bola.y = global_position.y 
	if global_position.distance_to(olhar_bola) > 0.1:
		look_at(olhar_bola, Vector3.UP)

	if pulando:
		if animation_player.current_animation != anim_pular:
			animation_player.play(anim_pular)
	elif movendo_lateralmente:
		if animation_player.current_animation != anim_andar:
			animation_player.play(anim_andar)
	else:
		if animation_player.current_animation != anim_idle:
			animation_player.play(anim_idle)

func resetar_posicao():
	global_position = posicao_inicial
	velocity = Vector3.ZERO
