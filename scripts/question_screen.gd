extends CanvasLayer

signal question_answered(is_correct: bool)

@onready var question_label: Label = $Control/background/question_label
@onready var btn_1: Button = $Control/background/VBoxContainer/btn_1
@onready var btn_2: Button = $Control/background/VBoxContainer/btn_2
@onready var btn_3: Button = $Control/background/VBoxContainer/btn_3
@onready var btn_4: Button = $Control/background/VBoxContainer/btn_4
@onready var question: AudioStreamPlayer = $question

var current_question_index = 0
var correct_answer_index = 0

var questions = [
	{
		"text": "1. Converta 00011101 para hexadecimal.",
		"options": ["A) 1D", "B) 1E", "C) F4", "D) EA"],
		"correct": 0 
	},
	{
		"text": "2. Qual o resultado de 1001 AND 1111?",
		"options": ["A) 1000", "B) 1100", "C) 1001", "D) 0011"],
		"correct": 2
	},
	{
		"text": "3. O barramento de dados é:",
		"options": ["Unidirecional", "De controle", "De endereço.", "Bidirecional."],
		"correct": 3
	},
	{
		"text": "4. O que o contador de programa (PC) armazena?",
		"options": ["O endereço da próxima instrução.", "Os dados da memória", "O resultado da ULA.", "A instrução atual."],
		"correct": 0
	},
	{
		"text": "5. Qual o tipo de acesso da instrução STA:",
		"options": ["MEM(end) ← PC", "AC ← MEM(end)", "MEM(end) ← AC", "AC ← AC + MEM(end)"],
		"correct": 2
	}
]

func _ready():
	hide()
		
	btn_1.pressed.connect(func(): check_answer(0))
	btn_2.pressed.connect(func(): check_answer(1))
	btn_3.pressed.connect(func(): check_answer(2))
	btn_4.pressed.connect(func(): check_answer(3))

func show_question():
	get_tree().paused = true 
		
	if current_question_index < questions.size():
		var q = questions[current_question_index]
		question_label.text = q["text"]
		btn_1.text = q["options"][0]
		btn_2.text = q["options"][1]
		btn_3.text = q["options"][2]
		btn_4.text = q["options"][3]
		correct_answer_index = q["correct"]
		show()
		question.play()
	else:
		get_tree().paused = false

func check_answer(index: int):
	hide()
	question.stop()
	get_tree().paused = false 
	
	if index == correct_answer_index:
		print("Acertou!")
		current_question_index += 1 
		emit_signal("question_answered", true)
	else:
		print("Errou! O Boss vai recuperar vida.")

		emit_signal("question_answered", false)
