extends ScrollContainer

@export var text_node : Control
@export_range(1, 10000, 0.1) var credits_time : float = 12.0 # <--- Diminuído para 12s para subir mais rápido!
@export_range(0, 10000, 0.1) var margin_increment : float = 0.0

@onready var margin : MarginContainer = $MarginContainer

func _ready() -> void:
	if not is_instance_valid(margin) or not is_instance_valid(text_node):
		push_error("Garante que o MarginContainer e o text_node estão atribuídos no Inspector!")
		return

	# Aguarda 1 frame para o Godot calcular os tamanhos de tela reais
	await get_tree().process_frame
	
	var text_box_size = text_node.size.y
	var window_size = DisplayServer.window_get_size().y

	# APROXIMAMOS O TEXTO: Dividimos por 3.0 para ele começar mais perto e aparecer quase de imediato
	var margem_inicial = window_size / 3.0
	
	margin.add_theme_constant_override("margin_top", int(margem_inicial + margin_increment))
	margin.add_theme_constant_override("margin_bottom", int(window_size + margin_increment))

	# Garante que o scroll comece no ponto 0
	scroll_vertical = 0

	# Ajusta o scroll total necessário
	var scroll_amount : int = ceil(text_box_size + margem_inicial + window_size + margin_increment)
	
	var tween = create_tween()
	
	# Movimento contínuo e constante
	tween.set_trans(Tween.TRANS_LINEAR)
	
	tween.tween_property(
		self,
		"scroll_vertical",
		scroll_amount,
		credits_time
	)
	
	tween.finished.connect(_acabou)

func _acabou() -> void:
	print("Créditos concluídos!")
