extends Node3D

var gols_time_a : int = 0
var gols_time_b : int = 0
var pode_marcar_gol : bool = true

@onready var score_label: Label = $CanvasLayer/MarginContainer/VBoxContainer/PanelContainer/HBoxContainer/ScoreLabel
@onready var bola: RigidBody3D = $bola
@onready var gol: AudioStreamPlayer3D = $sons/gol
@onready var apito: AudioStreamPlayer3D = $sons/apito

var posicao_inicial_bola : Vector3

func _ready() -> void:
	if bola:
		posicao_inicial_bola = bola.global_position

	atualizar_texto_placar()


func atualizar_texto_placar():
	score_label.text = str(gols_time_a) + " - " + str(gols_time_b)


func reiniciar_partida():
	if apito:
			apito.play()
	if bola:
		bola.freeze = false
		bola.global_position = posicao_inicial_bola
		bola.linear_velocity = Vector3.ZERO
		bola.angular_velocity = Vector3.ZERO

	var jogadores_laranja = get_tree().get_nodes_in_group("laranja")
	for jogador in jogadores_laranja:
		if jogador.has_method("resetar_posicao"):
			jogador.resetar_posicao()

	var jogadores_roxos = get_tree().get_nodes_in_group("roxo")
	for jogador in jogadores_roxos:
		if jogador.has_method("resetar_posicao"):
			jogador.resetar_posicao()

	var goleiros = get_tree().get_nodes_in_group("goleiros")
	for goleiro in goleiros:
		if goleiro.has_method("resetar_posicao"):
			goleiro.resetar_posicao()


func _process(delta: float) -> void:
	gerenciar_selecao_de_jogador()


func gerenciar_selecao_de_jogador():

	var jogadores_laranja = get_tree().get_nodes_in_group("laranja")
	var mais_prox_laranja: Node3D = null
	var dist_laranja: float = 99999.0

	for jogador in jogadores_laranja:
		if bola:
			var distancia = jogador.global_position.distance_to(bola.global_position)

			if distancia < dist_laranja:
				dist_laranja = distancia
				mais_prox_laranja = jogador

	for jogador in jogadores_laranja:
		if "esta_ativo" in jogador:
			jogador.esta_ativo = (jogador == mais_prox_laranja)

	var jogadores_roxos = get_tree().get_nodes_in_group("roxo")
	var mais_prox_roxo: Node3D = null
	var dist_roxo: float = 99999.0

	for jogador in jogadores_roxos:
		if bola:
			var distancia = jogador.global_position.distance_to(bola.global_position)

			if distancia < dist_roxo:
				dist_roxo = distancia
				mais_prox_roxo = jogador

	for jogador in jogadores_roxos:
		if "esta_ativo" in jogador:
			jogador.esta_ativo = (jogador == mais_prox_roxo)


func _on_travea_body_entered(body: Node3D) -> void:
	if pode_marcar_gol and body.is_in_group("bola"):
		if gol:
			gol.play()
		pode_marcar_gol = false

		print("Gol do Time A!")
		gols_time_a += 1

		atualizar_texto_placar()

		await get_tree().create_timer(5.0).timeout

		reiniciar_partida()

		pode_marcar_gol = true


func _on_traveb_body_entered(body: Node3D) -> void:
	if pode_marcar_gol and body.is_in_group("bola"):
		if gol:
			gol.play()
		pode_marcar_gol = false

		print("Gol do Time B!")
		gols_time_b += 1

		atualizar_texto_placar()

		await get_tree().create_timer(5.0).timeout

		reiniciar_partida()

		pode_marcar_gol = true


func _on_limitesdocampo_body_exited(body: Node3D) -> void:
	if pode_marcar_gol and body.is_in_group("bola"):

		pode_marcar_gol = false

		print("Bola fora de campo!")

		await get_tree().create_timer(3.0).timeout

		reiniciar_partida()

		pode_marcar_gol = true
