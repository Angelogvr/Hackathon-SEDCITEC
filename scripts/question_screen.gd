extends CanvasLayer

signal question_answered(is_correct: bool)
signal quiz_finished(final_score: int) # Novo sinal para quando o quiz acabar

@onready var question_label: Label = $Control/background/question_label
@onready var btn_1: Button = $Control/background/VBoxContainer/btn_1
@onready var btn_2: Button = $Control/background/VBoxContainer/btn_2
@onready var btn_3: Button = $Control/background/VBoxContainer/btn_3
@onready var btn_4: Button = $Control/background/VBoxContainer/btn_4
@onready var question: AudioStreamPlayer = $question

var current_question_index = 0
var correct_answer_index = 0
var score = 0
var is_showing_results = false # Controla se estamos na tela final de pontuação

var questions = [
	{
		"text": "1. Qual o apelido que Ada Lovelace recebeu pelas suas descobertas?",
		"options": ["A) Rainha da matemática", "B) Mãe da programação", "C) Mestre dos algoritmos", "D) Princesa dos Paralelogramos"],
		"correct": 1
	},
	{
		"text": "2. Em quais áreas Marie Curie recebeu prêmios Nobel?",
		"options": ["A) Física e Química", "B) Química e Biologia", "C) Física e Matemática", "D) Biologia e Medicina"],
		"correct": 0
	},
	{
		"text": "3. Apesar dos grandes avanços promovidos por Lynn, ela não recebeu seu devido reconhecimento e foi demitida pois:",
		"options": ["Começou sua transição de gênero", "Matou colegas de trabalho", "Roubou senhorinhas no parque", "Espalhou informações confidenciais"],
		"correct": 0
	},
	{
		"text": "4. Além do sequenciamento do genoma do coronavírus, quais outros vírus Jaqueline pesquisou?",
		"options": ["Zika vírus", "Dengue", "HIV", "Todos os anteriores"],
		"correct": 3
	}
]

func _ready():
	hide()
		
	btn_1.pressed.connect(func(): _on_button_pressed(0))
	btn_2.pressed.connect(func(): _on_button_pressed(1))
	btn_3.pressed.connect(func(): _on_button_pressed(2))
	btn_4.pressed.connect(func(): _on_button_pressed(3))

# Chame esta função pelo script do Jogo quando o jogador tocar na Area2D
func show_question():
	get_tree().paused = true 
	current_question_index = 0
	score = 0
	is_showing_results = false
	
	# Garante que todos os botões estejam visíveis ao iniciar o quiz
	btn_1.show()
	btn_2.show()
	btn_3.show()
	btn_4.show()
	
	show()
	question.play()
	load_current_question()

func load_current_question():
	if current_question_index < questions.size():
		var q = questions[current_question_index]
		question_label.text = q["text"]
		btn_1.text = q["options"][0]
		btn_2.text = q["options"][1]
		btn_3.text = q["options"][2]
		btn_4.text = q["options"][3]
		correct_answer_index = q["correct"]
	else:
		show_results()

func _on_button_pressed(index: int):
	# Se já estiver na tela de pontuação, clicar no botão 1 fecha o quiz
	if is_showing_results:
		close_quiz()
		return
		
	if index == correct_answer_index:
		print("Acertou!")
		score += 1
		emit_signal("question_answered", true)
	else:
		print("Errou! O Boss vai recuperar vida.")
		emit_signal("question_answered", false)
	
	# Avança para a próxima pergunta (acertando ou errando) e atualiza a tela
	current_question_index += 1
	load_current_question()

func show_results():
	is_showing_results = true
	question_label.text = "Quiz finalizado!\nSua pontuação: %d de %d" % [score, questions.size()]
	
	# Transforma o btn_1 no botão de "Continuar" e esconde os demais
	btn_1.text = "Continuar"
	btn_2.hide()
	btn_3.hide()
	btn_4.hide()

func close_quiz():
	hide()
	question.stop()
	get_tree().paused = false
	emit_signal("quiz_finished", score)
