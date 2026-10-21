extends CharacterBody2D

@onready var animacao: AnimatedSprite2D = $AnimatedSprite2D
@export var interacting = false

var direction = 0
const SPEED = 100
const JUMP_VELOCITY = -300.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		animacao.play("jump")
		velocity += get_gravity() * delta
		if Input.is_action_pressed("move_down"):
			velocity += get_gravity() * delta

	# Handle jump.
	#if Input.is_action_just_pressed("move_up") and is_on_floor():
	#	velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	if interacting:
		animacao.play("idle")
		return
	
	direction = 0
	if Input.is_action_pressed("move_right"):
		direction += 1
	if Input.is_action_pressed("move_left"):
		direction -= 1
		
	if direction:
		velocity.x = direction * SPEED
		animacao.flip_h = direction - 1
		animacao.play("walk")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor():
			animacao.play("idle")
		
	move_and_slide()
	
