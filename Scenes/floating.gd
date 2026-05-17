extends Control

var float_time := 0.0
@export var float_speed := 3.5
@export var float_strength := 1.0   # how much it moves up/down

var base_y := 0.0

func _ready():
	base_y = position.y

func _process(delta):
	float_time += delta * float_speed
	
	# smooth sine wave motion
	var offset = sin(float_time) * float_strength
	position.y = base_y + offset
