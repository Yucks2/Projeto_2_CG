extends CharacterBody3D

## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = false
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = false

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.002
## Normal speed.
@export var base_speed : float = 14.0
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we run?
@export var sprint_speed : float = 20.0
## How fast do we freefly?
@export var freefly_speed : float = 25.0
## Força com que o jogador vai empurrar ou chutar a bola
@export var forca_do_chute : float = 5.0

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "ui_left"
## Name of Input Action to move Right.
@export var input_right : String = "ui_right"
## Name of Input Action to move Forward.
@export var input_forward : String = "ui_up"
## Name of Input Action to move Backward.
@export var input_back : String = "ui_down"
## Name of Input Action to Jump.
@export var input_jump : String = "ui_accept"
## Name of Input Action to Sprint.
@export var input_sprint : String = "sprint"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"

var conduzindo_bola : bool = false

@export_group("Mecânicas de Futebol")
@export var forca_do_passe : float = 50.0
@export var time_laranja : String = "laranja" 
@export var input_passe : String = "passe"
@export_group("Referências Internas")
@export var zonadeposse: Area3D
@export var animation_player: AnimationPlayer
@onready var bola_ref: RigidBody3D = get_tree().get_first_node_in_group("bola")

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
var esta_ativo : bool = false
var cooldown_posse : float = 0.0
var posicao_inicial : Vector3

@export var forca_do_chute_ao_gol : float = 60.0 
@export var input_chute : String = "chute"
@export var caminho_gol_adversario : NodePath = "../travea"

@export_group("Emotes")
@export var input_emote_1 : String = "emote_1"
@export var input_emote_2 : String = "emote_2"
@export var anim_emote_1 : String = "Armature|emote_1" 
@export var anim_emote_2 : String = "Armature|emote_2"

@export_group("Animações Base")
@export var anim_idle : String = "Armature|idle"
@export var anim_correndo : String = "Armature|novocorrendo"
@export var anim_pique : String = "Armature|novopique"
@export var anim_chute : String = "Armature|chute"

## IMPORTANT REFERENCES
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var camera: Camera3D = get_node("../../camera_iso")

func _ready() -> void:
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	posicao_inicial = global_position
	
	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

func _physics_process(delta: float) -> void:
	# If freeflying, handle freefly and nothing else
	if cooldown_posse > 0.0:
		cooldown_posse -= delta
		
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return
	
	# Apply gravity to velocity
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * delta

	# Apply jumping
	if can_jump:
		if Input.is_action_just_pressed(input_jump) and is_on_floor():
			velocity.y = jump_velocity

	# Modify speed based on sprinting
	if can_sprint and Input.is_action_pressed(input_sprint):
		move_speed = sprint_speed
	else:
		move_speed = base_speed

	# Apply desired movement to velocity
	if can_move:
		var input_dir := Vector2.ZERO

		if esta_ativo:
			input_dir = Input.get_vector(input_left, input_right, input_forward, input_back)
			
		var cam_basis := camera.global_transform.basis
		var forward := Vector3(cam_basis.z.x, 0, cam_basis.z.z).normalized()
		var right := Vector3(cam_basis.x.x, 0, cam_basis.x.z).normalized()
		var move_dir := (forward * input_dir.y + right * input_dir.x).normalized()
		
		if esta_ativo and not conduzindo_bola and cooldown_posse <= 0.0:
			var corpos_na_zona = zonadeposse.get_overlapping_bodies()
			for corpo in corpos_na_zona:
				if corpo.is_in_group("bola"):
					conduzindo_bola = true
					corpo.freeze = true 
					desarmar_outros_jogadores()
					break

		if conduzindo_bola and is_instance_valid(bola_ref):
			bola_ref.global_position = $PosicaoDaBola.global_position
			bola_ref.linear_velocity = Vector3.ZERO
			bola_ref.angular_velocity = Vector3.ZERO
			
			if move_dir != Vector3.ZERO:
				var eixo_de_giro = Vector3.UP.cross(move_dir).normalized()
				var velocidade_do_giro = move_speed * delta * 2.0 
				bola_ref.rotate(eixo_de_giro, velocidade_do_giro)

		if not esta_ativo and conduzindo_bola:
			conduzindo_bola = false
			if is_instance_valid(bola_ref):
				bola_ref.freeze = false

		if esta_ativo and not move_dir:
			if Input.is_action_just_pressed(input_emote_1):
				animation_player.play(anim_emote_1)
			elif Input.is_action_just_pressed(input_emote_2):
				animation_player.play(anim_emote_2)
					

		if move_dir:
			if can_sprint and Input.is_action_pressed(input_sprint):
				if animation_player.current_animation != anim_correndo:
					animation_player.play(anim_correndo)
			else:
				if animation_player.current_animation != anim_pique:
					animation_player.play(anim_pique)
					
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
			
			var direcao_olhar = global_position + move_dir
			look_at(direcao_olhar, Vector3.UP)
		else:
			var anim_atual = animation_player.current_animation
			if anim_atual != anim_chute and anim_atual != anim_emote_1 and anim_atual != anim_emote_2 and anim_atual != anim_idle:
				animation_player.play(anim_idle)
				
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.y = 0

	if esta_ativo and Input.is_action_just_pressed(input_passe):
		if conduzindo_bola:
			conduzindo_bola = false
			cooldown_posse = 0.4
			if is_instance_valid(bola_ref):
				bola_ref.freeze = false 
				
				var receptor = encontrar_parceiro_mais_proximo()
				if receptor != null:
					print("Passando a bola para: ", receptor.name)
					var direcao_do_passe = bola_ref.global_position.direction_to(receptor.global_position)
					direcao_do_passe.y = 0.15 
					direcao_do_passe = direcao_do_passe.normalized()
					
					bola_ref.apply_central_impulse(direcao_do_passe * forca_do_passe)
				else:
					print("Nenhum companheiro de time encontrado em campo!")

	if esta_ativo and Input.is_action_just_pressed(input_chute):
		if conduzindo_bola:
			conduzindo_bola = false
			cooldown_posse = 0.5 
			
			if is_instance_valid(bola_ref):
				bola_ref.freeze = false
				
				var gol = get_node(caminho_gol_adversario)
				if gol:
					print("Chute bombástico em direção ao gol!")
					var direcao_do_chute = bola_ref.global_position.direction_to(gol.global_position)
					direcao_do_chute.y = 0.35 
					direcao_do_chute = direcao_do_chute.normalized()
					
					bola_ref.linear_velocity = Vector3.ZERO
					bola_ref.angular_velocity = Vector3.ZERO
					bola_ref.apply_central_impulse(direcao_do_chute * forca_do_chute_ao_gol)
					
	for i in get_slide_collision_count():
		var colisao = get_slide_collision(i)
		var objeto = colisao.get_collider()
		
		if objeto is RigidBody3D:
			var direcao = -colisao.get_normal()
			objeto.apply_central_impulse(direcao * forca_do_chute)
	# Use velocity to actually move
	move_and_slide()

	for i in get_slide_collision_count():
		var colisao = get_slide_collision(i)
		var objeto = colisao.get_collider()
		
		if objeto is RigidBody3D:
			var direcao = -colisao.get_normal()
			objeto.apply_central_impulse(direcao * forca_do_chute)

## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)


func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


## Checks if some Input Actions haven't been created.
## Disables functionality accordingly.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false

func encontrar_parceiro_mais_proximo() -> Node3D:
	var parceiros = get_tree().get_nodes_in_group(time_laranja)
	var melhor_parceiro : Node3D = null
	var menor_distancia : float = 99999.0
	for parceiro in parceiros:
		if parceiro == self:
			continue
			
		var distancia = global_position.distance_to(parceiro.global_position)
		if distancia < menor_distancia:
			menor_distancia = distancia
			melhor_parceiro = parceiro
			
	return melhor_parceiro
	
func resetar_posicao():
	global_position = posicao_inicial
	velocity = Vector3.ZERO
	conduzindo_bola = false
	
func desarmar_outros_jogadores():
	var todos_jogadores = get_tree().get_nodes_in_group("laranja") + get_tree().get_nodes_in_group("roxo")
	
	for jogador in todos_jogadores:
		if jogador != self and jogador.conduzindo_bola:
			jogador.conduzindo_bola = false
			jogador.cooldown_posse = 0.6
