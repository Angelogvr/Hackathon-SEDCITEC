
extends Control
class_name DialogScreen

var _step: float = 0.02
var _tempo_digitar: float = 0.0

var _id: int = 0
var data: Dictionary = {}

var _stream_ativo: bool = false

@export_category("Objects")
@export var _name: Label = null
@export var _dialog: RichTextLabel = null
@export var _faceset: TextureRect = null


func _ready() -> void:
	_initialize_dialog()


func _process(delta: float) -> void:
	# Acelera a digitação ao segurar F
	var intervalo := 0.01 if Input.is_action_pressed("interact") else _step

	# Controla o avanço do diálogo
	if Input.is_action_just_pressed("interact"):
		if not _stream_ativo:
			if _dialog.visible_characters >= _dialog.get_total_character_count():
				_id += 1

				if _id >= data.size():
					queue_free()
					return

				_initialize_dialog()

	# Revela progressivamente os caracteres
	var total := _dialog.get_total_character_count()

	if _dialog.visible_characters < total:
		_tempo_digitar += delta

		while _tempo_digitar >= intervalo and _dialog.visible_characters < total:
			_dialog.visible_characters += 1
			_tempo_digitar -= intervalo
	else:
		_tempo_digitar = 0.0


func _initialize_dialog() -> void:
	_name.text = data[_id]["title"]
	_dialog.text = data[_id]["dialog"]
	_faceset.texture = load(data[_id]["faceset"])

	_dialog.visible_characters = 0
	_tempo_digitar = 0.0


func iniciar_stream() -> void:
	_stream_ativo = true

	_dialog.text = ""
	_dialog.visible_characters = 0
	_tempo_digitar = 0.0


func atualizar_texto_stream(texto: String) -> void:
	if not _stream_ativo:
		return

	# Preserva os caracteres já exibidos
	var caracteres_visiveis: int = max(
		_dialog.visible_characters,
		0
	)

	_dialog.text = texto
	_dialog.visible_characters = caracteres_visiveis

	data[_id]["dialog"] = texto


func finalizar_stream() -> void:
	_stream_ativo = false
