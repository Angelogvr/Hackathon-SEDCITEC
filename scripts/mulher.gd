extends StaticBody2D

var target: Node2D
var botaoAtivo = false
@onready var animacao_botao_f: AnimatedSprite2D = $animacao_botaoF

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animacao_botao_f.visible = false
	get_target()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if abs(target.position[0] - position[0]) < 50:
		botaoAtivo = true
		animacao_botao_f.visible = true
		animacao_botao_f.play()
	else:
		animacao_botao_f.visible = false
		animacao_botao_f.pause()
		animacao_botao_f.frame = 0
		
	
	
func get_target():
	var nodes = get_tree().get_nodes_in_group("Player")
	if nodes.size() == 0:
		push_error("Player not found")
		return
	
	target = nodes[0]
	
