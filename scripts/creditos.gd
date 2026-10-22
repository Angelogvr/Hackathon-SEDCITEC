extends ScrollContainer

@onready var scroll_container: ScrollContainer = $"."
@export var text_node: RichTextLabel

# Tempo TOTAL da animação, em segundos
var credits_time: float = 30
# Espaço antes do primeiro título (0 = começa imediatamente)
@export_range(0.0, 10000.0, 0.1) var margin_increment: float = 240.0

@onready var margin: MarginContainer = $MarginContainer


func _ready() -> void:
	print("aqui ", credits_time)
	if not is_instance_valid(margin) or not is_instance_valid(text_node):
		push_error("Verifique o MarginContainer e o text_node!")
		return

	# Configura o texto dos créditos
	text_node.bbcode_enabled = true
	text_node.fit_content = true
	text_node.scroll_active = false

	# Aguarda os tamanhos dos elementos serem calculados
	await get_tree().process_frame

	# Sem espaço vazio no início
	margin.add_theme_constant_override(
		"margin_top",
		int(margin_increment)
	)

	# Espaço no final para o último texto sair completamente
	margin.add_theme_constant_override(
		"margin_bottom",
		int(size.y)
	)

	# Aguarda a atualização das margens
	await get_tree().process_frame

	# Começa no início, com o texto já visível
	scroll_vertical = 0

	# Calcula a distância REAL disponível para rolagem
	var barra := get_v_scroll_bar()
	var distancia_total: float = maxf(
		0.0,
		barra.max_value - barra.page
	)

	if distancia_total <= 0.0:
		push_warning("Não há conteúdo suficiente para rolar!")
		return

	# Cria a animação com duração controlada
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		self,
		"scroll_vertical",
		int(round(distancia_total)),
		credits_time
	)

	tween.finished.connect(_acabou)


func _acabou() -> void:
	print("Créditos concluídos!")
