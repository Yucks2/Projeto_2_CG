extends Node3D

#variáveis para guardar a pontuação
var gols_time_a : int = 0
var gols_time_b : int = 0
var pode_marcar_gol : bool = true

#referências para os textos do placar
@onready var label_placar_a: Label = $HUD/Control/HBoxContainer/score_a
@onready var label_placar_b: Label = $HUD/Control/HBoxContainer/score_b

#referência para a bola para podermos reiniciá-la no centro do campo
@onready var bola: RigidBody3D = $bola 

var posicao_inicial_bola : Vector3

func _ready() -> void:
	#guarda a posição onde a bola começou para resetar após o gol
	if bola:
		posicao_inicial_bola = bola.global_position
	atualizar_texto_placar()

#função que atualiza a interface visual
func atualizar_texto_placar():
	label_placar_a.text = str(gols_time_a)
	label_placar_b.text = str(gols_time_b)

#função para resetar a bola de forma segura no centro do campo
# função para resetar a bola e os jogadores de forma segura
func reiniciar_partida():
	if bola:
		bola.freeze = false # SEGURANÇA: Garante que a bola ligue a física de novo após o gol
		# reseta a posição física
		bola.global_position = posicao_inicial_bola
		# zera completamente as forças e velocidades para ela não continuar correndo
		bola.linear_velocity = Vector3.ZERO
		bola.angular_velocity = Vector3.ZERO
		
	# --- NOVO: RESETAR POSIÇÃO DOS JOGADORES ---
	# Pega todos os jogadores do time laranja
	var jogadores_laranja = get_tree().get_nodes_in_group("laranja")
	for jogador in jogadores_laranja:
		# Verifica se o script do jogador tem a função antes de chamar (proteção contra erros)
		if jogador.has_method("resetar_posicao"):
			jogador.resetar_posicao()
			
	# DICA FUTURA: Quando criar o time adversário (ex: grupo "azul"), 
	# basta copiar o bloco acima, mudar o nome do grupo e colar aqui embaixo!

# Função que será chamada quando o Time A sofrer um gol (ponto do Time B)
func _on_travea_body_entered(body: Node3D) -> void:
	# Só conta o gol se a trava estiver liberada e for a bola
	if pode_marcar_gol and body.is_in_group("bola"):
		pode_marcar_gol = false # Bloqueia novas detecções imediatamente
		
		print("Gol do Time B!")
		gols_time_b += 1
		atualizar_texto_placar()
		
		# --- SINAL DE ESPERA DE 5 SEGUNDOS ---
		# O 'await' faz o código congelar nesta linha exata pelo tempo determinado
		await get_tree().create_timer(5.0).timeout
		
		# Após os 5 segundos, o código continua aqui:
		reiniciar_partida()
		pode_marcar_gol = true # Libera a trava para o próximo gol da partida

# Função que será chamada quando o Time B sofrer um gol (ponto do Time A)
func _on_traveb_body_entered(body: Node3D) -> void:
	if pode_marcar_gol and body.is_in_group("bola"):
		pode_marcar_gol = false # Bloqueia novas detecções imediatamente
		
		print("Gol do Time A!")
		gols_time_a += 1
		atualizar_texto_placar()
		
		# --- SINAL DE ESPERA DE 5 SEGUNDOS ---
		await get_tree().create_timer(5.0).timeout
		
		reiniciar_partida()
		pode_marcar_gol = true # Libera a trava para o próximo gol da partida
func _process(delta: float) -> void:
	gerenciar_selecao_de_jogador()

func gerenciar_selecao_de_jogador():
	# Pega todos os jogadores do seu time em campo
	var jogadores = get_tree().get_nodes_in_group("laranja")
	var jogador_mais_proximo: Node3D = null
	var menor_distancia: float = 99999.0

	# 1. Varre o mapa para encontrar quem está mais perto da bola
	for jogador in jogadores:
		if bola:
			var distancia = jogador.global_position.distance_to(bola.global_position)
			if distancia < menor_distancia:
				menor_distancia = distancia
				jogador_mais_proximo = jogador

	# 2. Ativa o jogador mais próximo e desativa todos os outros
	for jogador in jogadores:
		if jogador == jogador_mais_proximo:
			jogador.esta_ativo = true
		else:
			jogador.esta_ativo = false		
