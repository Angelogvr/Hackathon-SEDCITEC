extends ScrollContainer

@onready var scroll_container: ScrollContainer = $"."
@export var text_node: RichTextLabel

var tween_creditos: Tween
var velocidade_acelerada: float = 3.0
# Tempo TOTAL da animação, em segundos
var credits_time: float = 30
# Espaço antes do primeiro título (0 = começa imediatamente)
@export_range(0.0, 10000.0, 0.1) var margin_increment: float = 240.0

@onready var margin: MarginContainer = $MarginContainer


func _ready() -> void:
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
	tween_creditos = create_tween()
	tween_creditos.set_trans(Tween.TRANS_LINEAR)

	tween_creditos.tween_method(
		_atualizar_rolagem,
		0.0,
		1.0,
		credits_time
	)

	tween_creditos.finished.connect(_acabou)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and (event.keycode == KEY_DOWN or event.keycode == KEY_S):

		if tween_creditos != null and tween_creditos.is_running():
			if event.pressed:
				# Segurando seta para baixo: acelera
				tween_creditos.set_speed_scale(velocidade_acelerada)
			else:
				# Soltou a tecla: velocidade normal
				tween_creditos.set_speed_scale(1.0)

		# Evita que o ScrollContainer role sozinho com a tecla
		get_viewport().set_input_as_handled()

func _acabou() -> void:
	print("Créditos concluídos!")
	
func _atualizar_rolagem(progresso: float) -> void:
	var barra := get_v_scroll_bar()
	var limite := maxf(0.0, barra.max_value - barra.page)

	scroll_vertical = int(round(limite * progresso))
