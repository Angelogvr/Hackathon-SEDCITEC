extends Control
var paused = false
@onready var pause_menu: Control = $"."
@onready var resume: TextureButton = $MarginContainer/VBoxContainer/Resume
@onready var quit: TextureButton = $MarginContainer/VBoxContainer/Quit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pause()

func pause():
	if paused:
		pause_menu.hide()
		get_tree().paused = false
	else:
		pause_menu.show()
		get_tree().paused = true
	paused = !paused

func _on_resume_pressed() -> void:
	pause()
func _on_quit_pressed() -> void:
	get_tree().quit()
