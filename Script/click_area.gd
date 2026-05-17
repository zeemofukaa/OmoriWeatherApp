extends Area2D

@onready var axolotl = get_parent()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		print("CLICK REGISTERED")
		if axolotl.state == axolotl.State.SLEEPING:
			axolotl.is_busy = false
			axolotl.change_state(axolotl.State.IDLE)
