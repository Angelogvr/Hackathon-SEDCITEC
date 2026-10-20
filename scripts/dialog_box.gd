extends MarginContainer

signal dialog_finished()

var texts_to_display: Array[String] = []
var current_index : int = 0
var typing_speed : float = 0.05
var is_typing : bool = false

@onready var text_label: Label = $text_container/text_label

@onready var tween : Tween = get_tree().create_tween()

func _ready() -> void:
	pivot_offset = size / 2
	self.scale = Vector2.ZERO
	
	
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	
	if texts_to_display.size() > 0:
		show_text()
```[cite: 2]
