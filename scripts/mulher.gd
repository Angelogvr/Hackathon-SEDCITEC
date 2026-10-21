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
	},
}

const _DIALOG_SCREEN: PackedScene = preload("res://entidades/dialog_scream.tscn")
const _PERSONAGEM := "Você é Lyn, uma personagem simpática de um jogo. Responda sempre em português, em no máximo 2 frases curtas."

var target: Node2D
var botaoAtivo = false
var _dialogo_ativo: DialogScreen = null

# --- novo ---
var _http: HTTPRequest
var _campo: LineEdit
var _esperando_ia := false

var _historico: Array = []


func _dialogo() -> void:
	var f_apertou := Input.is_action_just_pressed("interact")

	if f_apertou:
		print("F apertado | botaoAtivo: ", botaoAtivo, " | dialogo ativo: ", is_instance_valid(_dialogo_ativo), " | esperando IA: ", _esperando_ia)

	# se o player se afastar, fecha a caixa de texto
	if not botaoAtivo and _campo.visible:
		_campo.hide()

	if botaoAtivo and f_apertou and not is_instance_valid(_dialogo_ativo) and not _esperando_ia and not _campo.visible:
		var tela := get_viewport().get_visible_rect().size
		_campo.size = Vector2(500, 40)
		_campo.position = Vector2((tela.x - 500) / 2, tela.y - 100)
		_campo.z_index = 100
		_campo.text = ""
		_campo.show()
		_campo.grab_focus()
		print("Caixa mostrada em: ", _campo.position, " | tela: ", tela)

	# se o player se afastar, fecha a caixa de texto
	if not botaoAtivo and _campo.visible:
		_campo.hide()

	if botaoAtivo and f_apertou and not is_instance_valid(_dialogo_ativo) and not _esperando_ia and not _campo.visible:
		_campo.text = ""
		_campo.show()
		_campo.grab_focus()


func _on_texto_enviado(texto: String) -> void:
	texto = texto.strip_edges()
	if texto.is_empty():
		return

	_campo.hide()
	_campo.release_focus()
	_esperando_ia = true
	_historico.append({"role": "user", "content": texto})
	_perguntar_ia()


func _perguntar_ia() -> void:
	while _historico.size() > 10:  # lembra só das últimas mensagens
		_historico.pop_front()

	var mensagens: Array = [{"role": "system", "content": _PERSONAGEM}]
	mensagens.append_array(_historico)

	var corpo := {
		"model": "llama3.2",
		"stream": false,
		"messages": mensagens,
	}
	_http.request(
		"http://localhost:11434/api/chat",
		["content-type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(corpo)
	)


func _on_http_completed(_result, code: int, _headers, body: PackedByteArray) -> void:
	_esperando_ia = false
	var data_ia := _dialog_data  # plano B: suas falas fixas

	if code == 200:
		var resposta = JSON.parse_string(body.get_string_from_utf8())
		if resposta and resposta.has("message"):
			var fala: String = resposta["message"]["content"]
			_historico.append({"role": "assistant", "content": fala})
			data_ia = {
				0: {
					"faceset": "res://Sprites/lynn.jpeg",
					"dialog": fala,
					"title": "Lyn"
				},
			}
	else:
		_historico.pop_back()  # descarta a pergunta que falhou
		push_warning("Ollama não respondeu (código %d). Ele está aberto?" % code)

	var _new_dialog: DialogScreen = _DIALOG_SCREEN.instantiate()
	_new_dialog.data = data_ia
	_dialogo_ativo = _new_dialog
	_hud.add_child(_new_dialog)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animacao_botao_f.visible = false
	get_target()

	_http = HTTPRequest.new()
	_http.timeout = 60
	add_child(_http)
	_http.request_completed.connect(_on_http_completed)

	_campo = LineEdit.new()
	_campo.placeholder_text = "Fale com a Lyn e aperte Enter..."
	_campo.custom_minimum_size = Vector2(500, 40)
	_campo.position = Vector2(200, 500)  # ajuste para o tamanho da sua tela
	_campo.visible = false
	_campo.text_submitted.connect(_on_texto_enviado)
	_hud.add_child(_campo)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if abs(target.position[0] - position[0]) < 50:
		botaoAtivo = true
		animacao_botao_f.visible = true
		animacao_botao_f.play()
	else:
		botaoAtivo = false
		animacao_botao_f.visible = false
		animacao_botao_f.pause()
		animacao_botao_f.frame = 0
	_dialogo()


func get_target():
	var nodes = get_tree().get_nodes_in_group("Player")
	if nodes.size() == 0:
		push_error("Player not found")
		return

	target = nodes[0]
