extends Control
var paused = false
@onready var pause_menu: Control = $"."
@onready var resume: TextureButton = $ContainerPixelArtFundoTransparente/MarginContainer/VBoxContainer/Resume
@onready var quit: TextureButton = $ContainerPixelArtFundoTransparente/MarginContainer/VBoxContainer/Quit
@onready var container: Sprite2D = $ContainerPixelArtFundoTransparente
@onready var tutorial: Sprite2D = $PixelWoodcraftControlsSign

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	container.show()
	tutorial.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pause()

func pause():
	if paused:
		pause_menu.hide()
		container.show()
		tutorial.hide()
		get_tree().paused = false
	else:
		pause_menu.show()
		get_tree().paused = true
	paused = !paused

func _on_resume_pressed() -> void:
	pause()
func _on_quit_pressed() -> void:
	get_tree().quit()
func _on_tutorial_pressed() -> void:
	container.hide() 
	tutorial.show()
func _on_back_pressed() -> void:
	container.show()
	tutorial.hide()
