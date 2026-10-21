extends Node2D
class_name Level
@export var dialogos: Array
@export var faceset: Array
@export var titulo: Array

@export_category("Objects")
@export var _hud: CanvasLayer = null

@onready var animacao_botao_f: AnimatedSprite2D = $animacao_botaoF
@onready var _dialog_data: Dictionary = {
	0: {
		"faceset": faceset[0],
		"dialog": dialogos[0],
		"title": titulo[0]
	},
	1: {
		"faceset": faceset[0],
		"dialog": "ESSA É MINHA SEGUNDA FALA DA MULHER LYN",
		"title": titulo[0]
	},
}

const _DIALOG_SCREEN: PackedScene = preload("res://entidades/dialog_scream.tscn")
var target: Node2D
var botaoAtivo = false
var _dialogo_ativo: DialogScreen = null


func _dialogo() -> void:
	if botaoAtivo and Input.is_action_just_pressed("interact") and not is_instance_valid(_dialogo_ativo):
		var _new_dialog: DialogScreen = _DIALOG_SCREEN.instantiate()
		_new_dialog.data = _dialog_data
		_dialogo_ativo = _new_dialog
		_hud.add_child(_new_dialog)
	elif not botaoAtivo and is_instance_valid(_dialogo_ativo):
		_dialogo_ativo.queue_free()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animacao_botao_f.visible = false
	get_target()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if abs(target.position[0] - position[0]) < 50:
		botaoAtivo = true
	else:
		botaoAtivo = false
	show_button()
	_dialogo()
	
	
func get_target():
	var nodes = get_tree().get_nodes_in_group("Player")
	if nodes.size() == 0:
		push_error("Player not found")
		return
	
	target = nodes[0]
	
func show_button():
		if botaoAtivo:
			animacao_botao_f.visible = true
			animacao_botao_f.play()
		else:
			animacao_botao_f.visible = false
			animacao_botao_f.pause()
			animacao_botao_f.frame = 0
