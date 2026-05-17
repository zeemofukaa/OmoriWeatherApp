extends CanvasLayer

signal feed_pressed
signal play_pressed
signal sleep_pressed
signal reset_pressed
signal button_clicked

@onready var hunger_bar    := $Control/StatsSlot/HungerBar
@onready var energy_bar    := $Control/StatsSlot/EnergyBar
@onready var happiness_bar := $Control/StatsSlot/HappinessBar

@onready var feed_btn  := $Control/DeviceShell/FeedButton
@onready var play_btn  := $Control/DeviceShell/PlayButton
@onready var sleep_btn := $Control/DeviceShell/SleepButton

@onready var critical_overlay := $Control/CriticalOverlay
@onready var dialogue_box := $Control/CriticalOverlay/DialogueBox
@onready var reset_btn        := $Control/CriticalOverlay/DialogueBox/ResetButton

@onready var hunger_warn    := $Control/HungerWarning
@onready var energy_warn    := $Control/EnergyWarning
@onready var happiness_warn := $Control/HappinessWarning

@onready var streak_label := $Control/StreakFrame/StreakLabel

func _ready():
	feed_btn.pressed.connect(_on_feed)
	play_btn.pressed.connect(_on_play)
	sleep_btn.pressed.connect(_on_sleep)
	reset_btn.pressed.connect(_on_reset)
	critical_overlay.visible = false 
	critical_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	hunger_warn.visible = false
	energy_warn.visible = false
	happiness_warn.visible = false

func _on_reset():
	emit_signal("button_clicked") 
	critical_overlay.visible = false
	emit_signal("reset_pressed")  
	hunger_warn.visible = false
	energy_warn.visible = false
	happiness_warn.visible = false
	
func _on_feed():
	emit_signal("button_clicked") 
	_pop_button(feed_btn)
	emit_signal("feed_pressed")

func _on_play():
	emit_signal("button_clicked") 
	_pop_button(play_btn)
	emit_signal("play_pressed")

func _on_sleep():
	emit_signal("button_clicked") 
	_pop_button(sleep_btn)
	emit_signal("sleep_pressed")

# ── Stat bars ──────────────────────────────────────────────────────────────
func update_stats(hunger: float, energy: float, happiness: float) -> void:
	_update_bar(hunger_bar,    hunger)
	_update_bar(energy_bar,    energy)
	_update_bar(happiness_bar, happiness)

	_update_warnings(hunger, energy, happiness)

func _update_bar(bar: ProgressBar, value: float) -> void:
	bar.value = value
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left     = 0  
	style.corner_radius_top_right    = 0  
	style.corner_radius_bottom_left  = 3 
	style.corner_radius_bottom_right = 3 
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_color = Color(0.855, 0.683, 0.81, 0.7)  
	if value >= 60.0:
		style.bg_color = Color(0.533, 0.83, 0.647, 1.0)  
	elif value >= 30.0:
		style.bg_color = Color(0.98, 0.86, 0.55)  
	else:
		style.bg_color = Color(0.913, 0.411, 0.516, 1.0)  
	bar.add_theme_stylebox_override("fill", style)
	

# ── Button state ───────────────────────────────────────────────────────────
func set_busy(busy: bool) -> void:
	feed_btn.disabled = busy
	play_btn.disabled = busy

	sleep_btn.disabled = busy

func set_sleeping(is_sleeping: bool) -> void:
	sleep_btn.text = "Sleep"
	feed_btn.disabled = is_sleeping
	play_btn.disabled = is_sleeping
	sleep_btn.disabled = is_sleeping  

func set_critical() -> void:
	hunger_warn.visible = false
	energy_warn.visible = false
	happiness_warn.visible = false
	feed_btn.disabled = true
	play_btn.disabled = true
	sleep_btn.disabled = true
	
	await get_tree().create_timer(4).timeout

	critical_overlay.visible = true

	# start above screen then drop in
	dialogue_box.position.y = -200
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(dialogue_box, "position:y", 300.0, 1)

func _pop_button(btn: Button) -> void:
	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.tween_property(btn, "scale", Vector2(1.04, 1.08), 0.08)
	t.tween_property(btn, "scale", Vector2(1.0,  1.0),  0.12)

func _pop_warning(node: Control) -> void:
	node.visible = true
	node.scale = Vector2(0.8, 0.8)
	node.modulate.a = 0.0

	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_BACK)

	t.parallel().tween_property(node, "scale", Vector2(1, 1), 0.25)
	t.parallel().tween_property(node, "modulate:a", 1.0, 0.2)
	
func _update_warnings(hunger: float, energy: float, happiness: float) -> void:

	# Hunger
	if hunger < 30.0:
		if not hunger_warn.visible:
			_pop_warning(hunger_warn)
	else:
		hunger_warn.visible = false

	# Energy
	if energy < 30.0:
		if not energy_warn.visible:
			_pop_warning(energy_warn)
	else:
		energy_warn.visible = false

	# Happiness
	if happiness < 30.0:
		if not happiness_warn.visible:
			_pop_warning(happiness_warn)
	else:
		happiness_warn.visible = false

#--------------------------
# DAY STREAK
#--------------------------
func update_streak(streak: int) -> void:
	$Control/StreakFrame.visible = streak > 0
	streak_label.text = str(streak)
