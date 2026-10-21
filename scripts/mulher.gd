extends StaticBody2D

var target: Node2D
@onready var animacao_botao_f: AnimatedSprite2D = $animacao_botaoF

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animacao_botao_f.visible = false
	get_target()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#if target.x - position.x < 5:
		animacao_botao_f.visible = true
	#	animacao_botao_f.frame = 0 
	#else:
	#	animacao_botao_f.visible = false
		
	
func get_target():
	var nodes = get_tree().get_nodes_in_group("Player")
	if nodes.size() == 0:
		push_error("Player not found")
		return
	
	target = nodes[0]
