
extends Node2D
class_name Level

@export var dialogos: Array

@export_category("Objects")
@export var _hud: CanvasLayer = null

@onready var animacao_botao_f: AnimatedSprite2D = $animacao_botaoF

@onready var _dialog_data: Dictionary = {
	0: {
		"faceset": "res://Sprites/lynn.jpeg",
		"dialog": dialogos[0],
		"title": "Lyn"
	},
	1: {
		"faceset": "res://Sprites/lynn.jpeg",
		"dialog": "ESSA É MINHA SEGUNDA FALA DA MULHER LYN",
		"title": "Lyn"
	}
}

const _DIALOG_SCREEN: PackedScene = preload("res://entidades/dialog_scream.tscn")
const _PERSONAGEM := "Você é Lyn, uma personagem simpática de um jogo. Responda sempre em português, em no máximo 2 frases curtas."

var target: Node2D
var botaoAtivo = false
var _dialogo_ativo: DialogScreen = null

var _campo: LineEdit
var _esperando_ia := false
var _historico: Array = []


func _ready() -> void:
	animacao_botao_f.visible = false
	get_target()

	_campo = LineEdit.new()
	_campo.placeholder_text = "Fale com a Lyn e aperte Enter..."
	_campo.custom_minimum_size = Vector2(500, 40)
	_campo.position = Vector2(200, 500)
	_campo.visible = false
	_campo.text_submitted.connect(_on_texto_enviado)
	_hud.add_child(_campo)

	_precarregar_ia()


func _process(_delta: float) -> void:
	if not is_instance_valid(target):
		return

	if abs(target.position.x - position.x) < 70 and not target.interacting:
		botaoAtivo = true
	else:
		botaoAtivo = false

	show_button()
	_dialogo()


func _dialogo() -> void:
	var f_apertou := Input.is_action_just_pressed("interact")

	if botaoAtivo and f_apertou and not is_instance_valid(_dialogo_ativo) and not _esperando_ia and not _campo.visible:
		var tela := get_viewport().get_visible_rect().size

		_campo.size = Vector2(500, 40)
		_campo.position = Vector2(
			(tela.x - 500) / 2,
			tela.y - 100
		)

		_campo.z_index = 100
		_campo.text = ""
		_campo.show()
		_campo.grab_focus()

		target.interacting = true


func _on_texto_enviado(texto: String) -> void:
	texto = texto.strip_edges()

	if texto.is_empty():
		return

	target.interacting = false
	_campo.hide()
	_campo.release_focus()

	_esperando_ia = true

	_historico.append({
		"role": "user",
		"content": texto
	})

	_perguntar_ia()


func _perguntar_ia() -> void:
	while _historico.size() > 4:
		_historico.pop_front()

	var mensagens: Array = [
		{
			"role": "system",
			"content": _PERSONAGEM
		}
	]

	mensagens.append_array(_historico)

	var corpo := {
		"model": "llama3.2",
		"stream": true,
		"keep_alive": -1,
		"messages": mensagens,
		"options": {
			"num_predict": 60,
			"num_ctx": 1024,
			"temperature": 0.6
		}
	}

	# Abre a caixa de diálogo antes da resposta
	var nova_tela: DialogScreen = _DIALOG_SCREEN.instantiate()

	nova_tela.data = {
		0: {
			"faceset": "res://Sprites/lynn.jpeg",
			"dialog": "",
			"title": "Lyn"
		}
	}

	_dialogo_ativo = nova_tela
	_hud.add_child(nova_tela)

	nova_tela.iniciar_stream()

	# Cria conexão com Ollama
	var cliente := HTTPClient.new()
	cliente.blocking_mode_enabled = false

	var erro: int = cliente.connect_to_host(
		"127.0.0.1",
		11434
	)

	if erro != OK:
		_erro_stream(cliente, "Falha ao conectar ao Ollama.")
		return

	var limite: int = Time.get_ticks_msec() + 60000

	# Aguarda estabelecer conexão
	while cliente.get_status() in [
		HTTPClient.STATUS_RESOLVING,
		HTTPClient.STATUS_CONNECTING
	]:
		if Time.get_ticks_msec() > limite:
			_erro_stream(cliente, "Conexão demorou demais.")
			return

		erro = cliente.poll()

		if erro != OK:
			_erro_stream(cliente, "Erro na conexão HTTP.")
			return

		await get_tree().process_frame

	if cliente.get_status() != HTTPClient.STATUS_CONNECTED:
		_erro_stream(cliente, "O Ollama está indisponível.")
		return

	# Envia a pergunta
	erro = cliente.request(
		HTTPClient.METHOD_POST,
		"/api/chat",
		PackedStringArray([
			"Content-Type: application/json",
			"Connection: close"
		]),
		JSON.stringify(corpo)
	)

	if erro != OK:
		_erro_stream(cliente, "Erro ao enviar pergunta.")
		return

	# Espera os cabeçalhos HTTP
	while cliente.get_status() == HTTPClient.STATUS_REQUESTING:
		if Time.get_ticks_msec() > limite:
			_erro_stream(cliente, "O Ollama demorou demais.")
			return

		erro = cliente.poll()

		if erro != OK:
			_erro_stream(cliente, "Erro ao receber resposta.")
			return

		await get_tree().process_frame

	if cliente.get_response_code() != 200:
		_erro_stream(
			cliente,
			"Erro HTTP: %d" % cliente.get_response_code()
		)
		return

	if cliente.get_status() != HTTPClient.STATUS_BODY:
		_erro_stream(cliente, "Resposta HTTP sem corpo.")
		return

	# Recebe os fragmentos da IA
	var buffer := PackedByteArray()
	var fala: String = ""
	var terminou: bool = false
	var falha: String = ""

	while cliente.get_status() == HTTPClient.STATUS_BODY:
		if Time.get_ticks_msec() > limite:
			falha = "Tempo de resposta esgotado."
			break

		erro = cliente.poll()

		if erro != OK:
			falha = "Erro durante o streaming."
			break

		var bloco := cliente.read_response_body_chunk()

		if not bloco.is_empty():
			buffer.append_array(bloco)

			# Cada linha contém um JSON do Ollama
			var fim: int = buffer.find(10)

			while fim != -1:
				var linha: String = buffer.slice(
					0,
					fim
				).get_string_from_utf8().strip_edges()

				buffer = buffer.slice(fim + 1)

				if not linha.is_empty():
					var pacote = JSON.parse_string(linha)

					if pacote is Dictionary:
						if pacote.has("error"):
							falha = str(pacote["error"])
							break

						var mensagem = pacote.get(
							"message",
							{}
						)

						if mensagem is Dictionary:
							var parte: String = str(
								mensagem.get("content", "")
							)

							if not parte.is_empty():
								fala += parte

								# Atualiza texto em tempo real
								if is_instance_valid(_dialogo_ativo):
									_dialogo_ativo.atualizar_texto_stream(fala)

						if pacote.get("done", false):
							terminou = true
							break

				fim = buffer.find(10)

		if terminou or not falha.is_empty():
			break

		await get_tree().process_frame

	# Verifica se a resposta foi concluída
	if not terminou or not falha.is_empty() or fala.is_empty():
		_erro_stream(
			cliente,
			falha if not falha.is_empty()
			else "O Ollama não completou a resposta."
		)
		return

	cliente.close()

	# Guarda a fala completa no histórico
	_historico.append({
		"role": "assistant",
		"content": fala
	})

	_esperando_ia = false

	# Libera o botão F para fechar a caixa
	if is_instance_valid(_dialogo_ativo):
		_dialogo_ativo.finalizar_stream()

	print("Resposta final da Lyn: ", fala)


func _erro_stream(cliente: HTTPClient, mensagem: String) -> void:
	cliente.close()

	_esperando_ia = false

	if not _historico.is_empty():
		_historico.pop_back()

	if is_instance_valid(_dialogo_ativo):
		_dialogo_ativo.atualizar_texto_stream(
			"Desculpe, não consegui responder agora."
		)

		_dialogo_ativo.finalizar_stream()

	push_warning(mensagem)


func _precarregar_ia() -> void:
	var aquecimento := HTTPRequest.new()
	aquecimento.use_threads = true
	aquecimento.timeout = 60.0

	add_child(aquecimento)

	aquecimento.request_completed.connect(
		func(_result, _code, _headers, _body):
			aquecimento.queue_free()
	)

	var corpo := {
		"model": "llama3.2",
		"messages": [],
		"stream": false,
		"keep_alive": -1
	}

	var erro := aquecimento.request(
		"http://127.0.0.1:11434/api/chat",
		[
			"Content-Type: application/json",
			"Connection: close"
		],
		HTTPClient.METHOD_POST,
		JSON.stringify(corpo)
	)

	if erro != OK:
		aquecimento.queue_free()


func get_target() -> void:
	var nodes = get_tree().get_nodes_in_group("Player")

	if nodes.size() == 0:
		push_error("Player not found")
		return

	target = nodes[0]


func show_button() -> void:
	if botaoAtivo:
		animacao_botao_f.visible = true
		animacao_botao_f.play()
	else:
		animacao_botao_f.visible = false
		animacao_botao_f.pause()
		animacao_botao_f.frame = 0
