#extends CharacterBody2D
extends Node2D

enum State {
	IDLE,
	EATING,
	PLAYING,
	SLEEPING,
	DEAD
}

var state: State = State.IDLE

@export var hunger := 20
@export var energy := 80
@export var happiness := 60

func update_state():
	if hunger >= 100 or energy <= 0:
		change_state(State.DEAD)
	elif energy <= 20:
		change_state(State.SLEEPING)
	else:
		change_state(State.IDLE)


func _process(delta):
	if state == State.DEAD:
		return
	
	hunger += delta * 2
	energy -= delta * 1.5
	happiness -= delta * 0.8

	hunger = clamp(hunger, 0, 100)
	energy = clamp(energy, 0, 100)
	happiness = clamp(happiness, 0, 100)

	update_state()

func change_state(new_state: State):
	if state == new_state:
		return

	state = new_state
	update_animation()
	update_debug_label()



"""
const SPEED = 200.0
const JUMP_VELOCITY = -300.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
"""
	
func update_animation():
	# temporary – we will fill this properly later
	pass


func update_debug_label():
	# temporary – we will fill this properly later
	pass
