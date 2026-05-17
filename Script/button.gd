extends Button

@export var hover_scale := 1.05
@export var anim_time := 0.12

var tween: Tween

func _ready():
	pivot_offset = size / 2

func _on_mouse_entered():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * hover_scale, anim_time)

func _on_mouse_exited():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, anim_time)
