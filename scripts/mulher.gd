
extends Node2D
class_name Level

@export var dialogos: Array
@export var faceset: Array
@export var tittle: Array
@export_category("Objects")
@export var _hud: CanvasLayer = null
@export_file("*.txt") var caminho_biografia: String = "res://biografias/jaqueline.txt"
@onready var animacao_botao_f: AnimatedSprite2D = $animacao_botaoF


const _DIALOG_SCREEN: PackedScene = preload("res://entidades/dialog_scream.tscn")
var _PERSONAGEM: String = ""

var target: Node2D
var botaoAtivo = false
var _dialogo_ativo: DialogScreen = null

var _campo: LineEdit
var _esperando_ia := false
var _historico: Array = []
enum EstadoIA {
	PARADO,
	CONECTANDO,
	ESPERANDO_RESPOSTA,
	RECEBENDO
}

var _cliente_ia: HTTPClient = null
var _estado_ia: int = EstadoIA.PARADO
var _corpo_ia: String = ""
var _buffer_ia := PackedByteArray()
var _fala_ia: String = ""
var _limite_ia: int = 0


func _ready() -> void:
	animacao_botao_f.visible = false
	get_target()
	if dialogos.size() > 0:
		_PERSONAGEM = dialogos[0]
	else:
		_PERSONAGEM = "Você é um aviso que deve avisar para o jogador tentar novamente conversar com voce. Responda sempre em português de forma curta."
	_carregar_biografia()
	_PERSONAGEM += """

	REGRAS OBRIGATÓRIAS DE RESPOSTA:
	- Responda sempre em português.
	- Responda com no máximo 2 frases curtas.
	- Cada resposta deve ter no máximo 40 palavras.
	- Não escreva parágrafos longos.
	- Seja direta, natural e simpática.
- 	Não forneça explicações extensas, a menos que seja solicitado.
- 	Se a pergunta for simples, responda com apenas uma frase.
- 	Continue interpretando a personagem conforme sua biografia.
"""
	_campo = LineEdit.new()
	_campo.placeholder_text = "Fale com o quadro e aperte Enter..."
	_campo.custom_minimum_size = Vector2(500, 40)
	_campo.position = Vector2(200, 500)
	_campo.visible = false
	_campo.text_submitted.connect(_on_texto_enviado)
	_hud.add_child(_campo)

	_precarregar_ia()


func _process(_delta: float) -> void:
	# Processa a IA enquanto esta cena estiver ativa
	if _cliente_ia != null:
		_atualizar_stream()

	if not is_instance_valid(target):
		return

	if abs(target.position.x - position.x) < 70:
		botaoAtivo = true
	else:
		botaoAtivo = false

	# Fecha o diálogo quando o jogador se afasta
	if not botaoAtivo and is_instance_valid(_dialogo_ativo):
		_dialogo_ativo.queue_free()
		_dialogo_ativo = null

	show_button()
	_dialogo()

func _dialogo() -> void:
	var f_apertou := Input.is_action_just_pressed("interact")
	

	if botaoAtivo and f_apertou and not is_instance_valid(_dialogo_ativo) and not _esperando_ia and not _campo.visible:
		var tela := get_viewport().get_visible_rect().size

		_campo.size = Vector2(500, 40)
		_campo.position = Vector2(
			(tela.x - 500) / 2,
			tela.y - 50
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
		"model": "llama3.2:1b",
		"stream": true,
		"keep_alive": -1,
		"messages": mensagens,
		"options": {
			"num_predict": 128,
			"num_ctx": 2048,
			"temperature": 0.4
		}
	}

	# Abre a caixa de diálogo
	var nova_tela: DialogScreen = _DIALOG_SCREEN.instantiate()

	nova_tela.data = {
		0: {
			"faceset": faceset[0],
			"dialog": "",
			"title": tittle[0]
		}
	}

	_dialogo_ativo = nova_tela
	_hud.add_child(nova_tela)
	nova_tela.iniciar_stream()

	# Inicializa o cliente HTTP
	_cliente_ia = HTTPClient.new()
	_cliente_ia.blocking_mode_enabled = false

	_corpo_ia = JSON.stringify(corpo)
	_buffer_ia.clear()
	_fala_ia = ""

	_limite_ia = Time.get_ticks_msec() + 120000

	var erro := _cliente_ia.connect_to_host(
		"127.0.0.1",
		11434
	)

	if erro != OK:
		_erro_stream("Falha ao conectar ao Ollama.")
		return

	_estado_ia = EstadoIA.CONECTANDO
	

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
		"model": "llama3.2:1b",
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

func _atualizar_stream() -> void:
	if _cliente_ia == null:
		return

	# Verifica o tempo limite
	if Time.get_ticks_msec() > _limite_ia:
		_erro_stream("Tempo de resposta esgotado.")
		return

	# Atualiza a conexão
	var erro := _cliente_ia.poll()

	if erro != OK:
		_erro_stream("Erro na conexão HTTP.")
		return

	var status := _cliente_ia.get_status()

	match _estado_ia:
		EstadoIA.CONECTANDO:
			if status == HTTPClient.STATUS_CONNECTED:
				erro = _cliente_ia.request(
					HTTPClient.METHOD_POST,
					"/api/chat",
					PackedStringArray([
						"Content-Type: application/json",
						"Connection: close"
					]),
					_corpo_ia
				)

				if erro != OK:
					_erro_stream("Erro ao enviar pergunta.")
					return

				_estado_ia = EstadoIA.ESPERANDO_RESPOSTA

			elif status not in [
				HTTPClient.STATUS_RESOLVING,
				HTTPClient.STATUS_CONNECTING
			]:
				_erro_stream("Não foi possível conectar ao Ollama.")

		EstadoIA.ESPERANDO_RESPOSTA:
			if status == HTTPClient.STATUS_BODY:
				if _cliente_ia.get_response_code() != 200:
					_erro_stream(
						"Erro HTTP: %d" % _cliente_ia.get_response_code()
					)
					return

				_estado_ia = EstadoIA.RECEBENDO
				_ler_stream()

			elif status != HTTPClient.STATUS_REQUESTING:
				_erro_stream("Falha ao receber resposta HTTP.")

		EstadoIA.RECEBENDO:
			if status == HTTPClient.STATUS_BODY:
				_ler_stream()

			elif status != HTTPClient.STATUS_BODY:
				_erro_stream("A conexão terminou antes da resposta.")
				
func _ler_stream() -> void:
	if _cliente_ia == null:
		return

	var bloco := _cliente_ia.read_response_body_chunk()

	if bloco.is_empty():
		return

	_buffer_ia.append_array(bloco)

	var fim: int = _buffer_ia.find(10)

	while fim != -1:
		var linha: String = _buffer_ia.slice(
			0,
			fim
		).get_string_from_utf8().strip_edges()

		_buffer_ia = _buffer_ia.slice(fim + 1)

		if not linha.is_empty():
			var pacote = JSON.parse_string(linha)

			if pacote is Dictionary:
				if pacote.has("error"):
					_erro_stream(str(pacote["error"]))
					return

				var mensagem = pacote.get("message", {})

				if mensagem is Dictionary:
					var parte: String = str(
						mensagem.get("content", "")
					)

					if not parte.is_empty():
						_fala_ia += parte

						if is_instance_valid(_dialogo_ativo):
							_dialogo_ativo.atualizar_texto_stream(
								_fala_ia
							)

				if pacote.get("done", false):
					if _fala_ia.is_empty():
						_erro_stream("A IA retornou uma resposta vazia.")
					else:
						_finalizar_stream()

					return

		fim = _buffer_ia.find(10)
		
func _erro_stream(mensagem: String) -> void:
	if _cliente_ia != null:
		_cliente_ia.close()
		_cliente_ia = null

	_estado_ia = EstadoIA.PARADO
	_esperando_ia = false

	if not _historico.is_empty():
		var ultima = _historico.back()

		if ultima is Dictionary and ultima.get("role", "") == "user":
			_historico.pop_back()

	if is_instance_valid(_dialogo_ativo):
		_dialogo_ativo.atualizar_texto_stream(
			"Desculpe, não consegui responder agora."
		)

		_dialogo_ativo.finalizar_stream()

	push_warning(mensagem)

func _finalizar_stream() -> void:
	if _cliente_ia != null:
		_cliente_ia.close()
		_cliente_ia = null

	_estado_ia = EstadoIA.PARADO
	_esperando_ia = false

	_historico.append({
		"role": "assistant",
		"content": _fala_ia
	})

	if is_instance_valid(_dialogo_ativo):
		_dialogo_ativo.finalizar_stream()
		

func _exit_tree() -> void:
	# Cancela a conexão quando a cena é encerrada
	if _cliente_ia != null:
		_cliente_ia.close()
		_cliente_ia = null

	_estado_ia = EstadoIA.PARADO
	_esperando_ia = false
	
func _carregar_biografia() -> void:
	if caminho_biografia.is_empty():
		push_warning("Nenhuma biografia configurada.")
		return

	if not FileAccess.file_exists(caminho_biografia):
		push_warning("Biografia não encontrada: " + caminho_biografia)
		return

	var biografia: String = FileAccess.get_file_as_string(
		caminho_biografia
	).strip_edges()

	if biografia.is_empty():
		push_warning("O arquivo da biografia está vazio.")
		return

	var nome: String = "personagem"

	if tittle.size() > 0:
		nome = str(tittle[0])

	_PERSONAGEM += """

Você está interpretando %s em uma simulação interativa.

REGRAS:
- Responda em primeira pessoa, como o personagem.
- Utilize a biografia como fonte principal de informações.
- Responda sempre em português.
- Mantenha a personalidade descrita.
- Se perguntarem sobre sua vida, consulte os fatos da biografia.
- Não invente acontecimentos, datas ou informações biográficas.
- Se não houver informação suficiente, admita que não sabe.
- Não confunda acontecimentos do jogador com sua própria história.
- Responda de forma natural, como uma conversa.

BIOGRAFIA DO PERSONAGEM:
%s
""" % [nome, biografia]

	print("Biografia carregada: ", caminho_biografia)


func get_target() -> void:
	var nodes = get_tree().get_nodes_in_group("Player")

	if nodes.size() == 0:
		push_error("Player not found")
		return

	target = nodes[0]


func show_button() -> void:
	if botaoAtivo and not target.interacting:
		animacao_botao_f.visible = true
		animacao_botao_f.play()
	else:
		animacao_botao_f.visible = false
		animacao_botao_f.pause()
		animacao_botao_f.frame = 0
