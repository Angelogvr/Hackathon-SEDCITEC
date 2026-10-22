extends Node2D
@onready var player: CharacterBody2D = $"../Player"
@onready var door: AnimatedSprite2D = $door_animation
@onready var collision: CollisionShape2D = $door_collision

var open = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	door.pause()
	door.frame = 0
	
func _process(delta: float) -> void:
	if abs(player.position.x - position.x) < 100:
		if door.frame < 8:
			door.play()
		else:
			door.pause()
	else:
		if door.frame > 0:
			door.play_backwards()
		else:
			door.pause()
		
