extends StaticBody2D

@onready var player: CharacterBody2D = $"../Player"
@onready var door: AnimatedSprite2D = $door_animation
@onready var collision: CollisionShape2D = $door_collision
@onready var fade_rect: ColorRect = $"../CanvasLayer/FadeRect"

var is_transitioning = false

func _ready() -> void:
	door.pause()
	door.frame = 0

func _process(_delta: float) -> void:
	if is_transitioning:
		return

	var dist = abs(player.position.x - position.x)

	if dist < 100:
		if door.frame < 8:
			door.play()
		else:
			door.pause()
			collision.disabled = true
			
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
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 1.1)
	
	tween.finished.connect(func():
		get_tree().change_scene_to_file("res://cenas/Creditos.tscn")
	)
