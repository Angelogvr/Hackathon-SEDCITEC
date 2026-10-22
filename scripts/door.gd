extends StaticBody2D

@onready var player: CharacterBody2D = $"../Player"
@onready var door: AnimatedSprite2D = $door_animation
@onready var collision: CollisionShape2D = $door_collision
@onready var fade_rect: ColorRect = $"../CanvasLayer/FadeRect"

var is_transitioning = false

func _ready() -> void:
	door.pause()
	door.frame = 0

func _process(delta: float) -> void:
	if is_transitioning:
		return

	var dist = abs(player.position.x - position.x)

	if dist < 100:
		if door.frame < 8:
			door.play()
		else:
			door.pause()
			# Libera a passagem quando a porta estiver totalmente aberta
			collision.disabled = true
			
			# Quando o jogador passar pelo meio da porta, inicia o Fade Out
			if dist < 20:
				start_fade_out()
	else:
		collision.disabled = false
		if door.frame > 0:
			door.play_backwards()
		else:
			door.pause()

func start_fade_out() -> void:
	is_transitioning = true
	
	# Cria uma animação suave de 1.5 segundos mudando o Alpha (transparência) para 1.0 (totalmente preto)
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 1.01)
	
	tween.finished.connect(func():
		get_tree().change_scene_to_file("res://cenas/Creditos.tscn")
	)
