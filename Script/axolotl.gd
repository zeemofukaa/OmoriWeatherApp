extends Node2D

const SAVE_PATH: String = "user://save.cfg"

# --------------------
# STATES
# --------------------
enum State {
	IDLE,
	EATING,
	PLAYING,
	SLEEPING,
	CRITICAL,
	FULL
}

# --------------------
# VARS
# --------------------
var is_hovering    := false
var is_night       := false
var state: State    = State.IDLE
var is_busy        := false

var _bob_tween:    Tween
var _squish_tween: Tween
var _settle_tween: Tween

var float_time     := 0.0
var sleep_time     := 0.0
var base_y         := 0.0
var base_Y         := 0.0

@export var float_speed    := 3.5
@export var float_strength := 4.0

var _sleep_min_timer: float = 0.0
var _sleep_start_time: float = 0.0
const SLEEP_MIN_DURATION: float = 1200.0

var day_streak: int = 0
var _last_save_date: String = ""

# ── Stats ─────────────────────────────────────────────────────────────────
var hunger:    float = 80.0
var energy:    float = 80.0
var happiness: float = 80.0

const STAT_MAX: float = 100.0
const STAT_MIN: float = 0.0

const HUNGER_DECAY:    float = 3.0
const ENERGY_DECAY:    float = 2.0
const HAPPINESS_DECAY: float = 2.5

const EAT_HUNGER:     float = 25.0
const EAT_HAPPINESS:  float = 5.0
const PLAY_HAPPINESS: float = 25.0
const PLAY_ENERGY:    float = -10.0
const SLEEP_ENERGY:   float = 40.0

# ── Signals ───────────────────────────────────────────────────────────────
signal stats_changed(hunger: float, energy: float, happiness: float)
signal entered_critical
signal state_changed(new_state: State)
signal streak_changed(streak: int)

# --------------------
# READY
# --------------------
func _ready() -> void:
	update_animation()
	$StatDecayTimer.wait_time = 30.0
	$StatDecayTimer.one_shot  = false
	$StatDecayTimer.start()
	_load_game()
	emit_signal("stats_changed", hunger, energy, happiness)
	_start_bob()
	base_y = $AnimatedSprite2D.position.y
	base_Y = position.y

# --------------------
# PROCESS
# --------------------
func _process(delta: float) -> void:
	if state == State.SLEEPING:
		if _sleep_min_timer > 0.0:
			_sleep_min_timer -= delta
			sleep_time += delta * 3
			var scale_offset := sin(sleep_time) * -0.015
			$AnimatedSprite2D.scale = Vector2(1, 1) + Vector2(scale_offset, scale_offset)
			$AnimatedSprite2D.position.y = sin(sleep_time) * 1.0
			var secs := ceili(_sleep_min_timer)
			$Control/SleepLabel.text = "wake me after (%ds)" % secs
		else:
			$Control/SleepLabel.text = "click me to wake!"
	else:
		sleep_time = 0.0
		$AnimatedSprite2D.position.y = lerp(
			$AnimatedSprite2D.position.y,
			base_y,
			delta * 6
		)
		float_time += delta * float_speed
		position.y = base_Y + sin(float_time) * float_strength

# --------------------
# STATE CHANGE
# --------------------
func change_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	update_animation()
	$Control/SleepLabel.visible    = (new_state == State.SLEEPING)
	$Control/SleepBar.visible      = (new_state == State.SLEEPING)
	$Control/SleepBarShadow.visible = (new_state == State.SLEEPING)
	if new_state == State.IDLE:
		_start_bob()
	elif new_state == State.SLEEPING or new_state == State.CRITICAL:
		_stop_bob()
	emit_signal("state_changed", new_state)

# --------------------
# ANIMATIONS
# --------------------
func update_animation() -> void:
	match state:
		State.IDLE:
			$AnimatedSprite2D.speed_scale = 0.7 if is_night else 1.0
			$AnimatedSprite2D.play("idle")
		State.EATING:
			$AnimatedSprite2D.speed_scale = 1.2
			$AnimatedSprite2D.play("eat")
		State.PLAYING:
			$AnimatedSprite2D.speed_scale = 1.1
			$AnimatedSprite2D.play("jump")
		State.SLEEPING:
			$AnimatedSprite2D.speed_scale = 0.6
			$AnimatedSprite2D.play("sleep")
		State.CRITICAL:
			$AnimatedSprite2D.speed_scale = 1.1
			$AnimatedSprite2D.play("die")
		State.FULL:
			$AnimatedSprite2D.speed_scale = 1.0
			$AnimatedSprite2D.play("overeat")

# --------------------
# ACTIONS
# --------------------
func eat() -> void:
	if is_busy or state == State.SLEEPING:
		return
	if hunger >= 100:
		is_busy = true
		change_state(State.FULL)
		_modify_stats(0.0, 0.0, -5.0)
		$ActionTimer.start(2.0)
		return
	is_busy = true
	change_state(State.EATING)
	_modify_stats(EAT_HUNGER, 0.0, EAT_HAPPINESS)
	$ActionTimer.stop()
	$ActionTimer.start(2.0)

func play() -> void:
	if is_busy or state == State.SLEEPING:
		return
	is_busy = true
	change_state(State.PLAYING)
	_modify_stats(0.0, PLAY_ENERGY, PLAY_HAPPINESS)
	$ActionTimer.stop()
	$ActionTimer.start(1.0)

func sleep() -> void:
	if is_busy:
		return
	is_busy = true
	_sleep_min_timer = SLEEP_MIN_DURATION
	_sleep_start_time = Time.get_unix_time_from_system()
	change_state(State.SLEEPING)

# --------------------
# TIMER CALLBACK
# --------------------
func _on_action_timer_timeout() -> void:
	is_busy = false
	if state != State.SLEEPING and state != State.CRITICAL:
		change_state(State.IDLE)

# --------------------
# INPUT
# --------------------
func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton
	and event.button_index == MOUSE_BUTTON_LEFT
	and event.pressed):
		if state == State.SLEEPING:
			if _sleep_min_timer <= 0.0:
				is_busy = false
				_modify_stats(0.0, SLEEP_ENERGY, 0.0)
				change_state(State.IDLE)
				get_tree().current_scene.sfx_sleep.stop()
				get_tree().current_scene._unduck_music(0.0)
			else:
				$Control/SleepLabel.text = "💤 Still sleeping..."
		elif state != State.CRITICAL and is_hovering:
			_do_squish()

# --------------------
# STAT DECAY
# --------------------
func _on_stat_decay_timer_timeout() -> void:
	if state == State.SLEEPING:
		_modify_stats(-HUNGER_DECAY, SLEEP_ENERGY * 0.1, -HAPPINESS_DECAY * 0.5)
	else:
		_modify_stats(-HUNGER_DECAY, -ENERGY_DECAY, -HAPPINESS_DECAY)
	_save_game()

# --------------------
# STAT HELPERS
# --------------------
func _modify_stats(d_hunger: float, d_energy: float, d_happiness: float) -> void:
	hunger    = clampf(hunger    + d_hunger,    STAT_MIN, STAT_MAX)
	energy    = clampf(energy    + d_energy,    STAT_MIN, STAT_MAX)
	happiness = clampf(happiness + d_happiness, STAT_MIN, STAT_MAX)
	emit_signal("stats_changed", hunger, energy, happiness)
	_check_critical()

func _check_critical() -> void:
	if hunger <= STAT_MIN and energy <= STAT_MIN and happiness <= STAT_MIN:
		day_streak = 0
		emit_signal("streak_changed", day_streak)
		is_busy = true
		$StatDecayTimer.stop()
		change_state(State.CRITICAL)
		emit_signal("entered_critical")

func reset_pet() -> void:
	hunger    = 80.0
	energy    = 80.0
	happiness = 80.0
	is_busy   = false
	change_state(State.IDLE)
	$StatDecayTimer.start()
	emit_signal("stats_changed", hunger, energy, happiness)
	_save_game()

# --------------------
# IDLE BOB
# --------------------
func _start_bob() -> void:
	if _bob_tween:
		_bob_tween.kill()
	_bob_tween = create_tween()
	_bob_tween.set_loops()
	_bob_tween.set_trans(Tween.TRANS_SINE)
	_bob_tween.set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property($AnimatedSprite2D, "position:y", 4.0, 0.6)
	_bob_tween.tween_property($AnimatedSprite2D, "position:y", 0.0, 0.6)

func _stop_bob() -> void:
	if _bob_tween:
		_bob_tween.kill()
	$AnimatedSprite2D.position.y = 0.0

# --------------------
# SQUISH
# --------------------
func _do_squish() -> void:
	if _squish_tween:
		_squish_tween.kill()
	#var prev_anim = $AnimatedSprite2D.animation   

	$AnimatedSprite2D.play("squish") 
	_squish_tween = create_tween()
	_squish_tween.set_trans(Tween.TRANS_SINE)
	_squish_tween.tween_property($AnimatedSprite2D, "scale:y", 0.8, 0.08)
	_squish_tween.tween_property($AnimatedSprite2D, "scale:y", 1.0, 0.12)
	await _squish_tween.finished   

	update_animation()  
	get_tree().current_scene.play_sfx_squish()
# --------------------
# HOVER
# --------------------
func _on_hover_area_mouse_entered() -> void:
	is_hovering = true
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	if state == State.IDLE:
		if _bob_tween:
			_bob_tween.kill()
		_settle_tween = create_tween()
		_settle_tween.set_trans(Tween.TRANS_SINE)
		_settle_tween.set_ease(Tween.EASE_OUT)
		_settle_tween.tween_property($AnimatedSprite2D, "position:y", 0.0, 0.3)
		await _settle_tween.finished
		$AnimatedSprite2D.pause()

func _on_hover_area_mouse_exited() -> void:
	is_hovering = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	if _settle_tween:
		_settle_tween.kill()
	if state == State.IDLE:
		$AnimatedSprite2D.play("idle")
		_start_bob()

# --------------------
# NIGHT MODE
# --------------------
func set_night_mode(night: bool) -> void:
	is_night = night
	if state == State.IDLE:
		$AnimatedSprite2D.speed_scale = 0.7 if is_night else 1.0

# --------------------
# SAVE / LOAD
# --------------------
func _save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("stats", "hunger",    hunger)
	config.set_value("stats", "energy",    energy)
	config.set_value("stats", "happiness", happiness)
	config.set_value("meta",  "state",     state)
	config.set_value("meta",  "timestamp", Time.get_unix_time_from_system())
	config.set_value("meta", "day_streak",      day_streak)
	config.set_value("meta", "last_save_date",  _last_save_date)
	config.set_value("meta", "sleep_start_time", _sleep_start_time)
	config.save(SAVE_PATH)
	

func _load_game() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	hunger    = config.get_value("stats", "hunger",    80.0)
	energy    = config.get_value("stats", "energy",    80.0)
	happiness = config.get_value("stats", "happiness", 80.0)
	
	_sleep_start_time = config.get_value("meta", "sleep_start_time", 0.0)

	day_streak      = config.get_value("meta", "day_streak",     0)
	_last_save_date = config.get_value("meta", "last_save_date", "")
	_check_day_streak()

	var saved_time: float = config.get_value("meta", "timestamp", 0.0)
	if saved_time > 0.0:
		var elapsed: float    = Time.get_unix_time_from_system() - saved_time
		var ticks: int        = int(elapsed / 30.0)
		var capped_ticks: int = min(ticks, 2880)
		if ticks > 0:
			hunger    = clampf(hunger    - HUNGER_DECAY    * capped_ticks, STAT_MIN, STAT_MAX)
			energy    = clampf(energy    - ENERGY_DECAY    * capped_ticks, STAT_MIN, STAT_MAX)
			happiness = clampf(happiness - HAPPINESS_DECAY * capped_ticks, STAT_MIN, STAT_MAX)

	var saved_state: int = config.get_value("meta", "state", State.IDLE)
	if saved_state == State.CRITICAL or hunger <= STAT_MIN or energy <= STAT_MIN or happiness <= STAT_MIN:
		state   = State.CRITICAL
		is_busy = true
		$StatDecayTimer.stop()
		call_deferred("_emit_critical")
	elif saved_state == State.SLEEPING:
		state   = State.SLEEPING
		is_busy = true
		if _sleep_start_time > 0.0:
			var slept_so_far: float = Time.get_unix_time_from_system() - _sleep_start_time
			_sleep_min_timer = maxf(SLEEP_MIN_DURATION - slept_so_far, 0.0)
		else:
			_sleep_min_timer = 0.0
		call_deferred("_emit_sleeping")
	else:
		state = State.IDLE

	emit_signal("stats_changed", hunger, energy, happiness)

func _emit_sleeping() -> void:
	update_animation()
	_stop_bob()
	$Control/SleepLabel.visible     = true
	$Control/SleepBar.visible       = true
	$Control/SleepBarShadow.visible = true
	$Control/SleepLabel.text        = "click me to wake!" if _sleep_min_timer <= 0.0 \
									  else "wake me after (%ds)" % ceili(_sleep_min_timer)
	emit_signal("state_changed", State.SLEEPING)

func _emit_critical() -> void:
	_stop_bob()
	update_animation()
	emit_signal("entered_critical")

# --------------------
# DAY STREAK
# --------------------
func _check_day_streak() -> void:
	var today := _get_today_string()
	if _last_save_date == "":
		_last_save_date = today
		return
	if today == _last_save_date:
		return
	var last := Time.get_datetime_dict_from_datetime_string(_last_save_date, false)
	var now  := Time.get_datetime_dict_from_system()
	var last_unix := Time.get_unix_time_from_datetime_dict(last)
	var now_unix  := Time.get_unix_time_from_datetime_dict(now)
	var days_passed := int((now_unix - last_unix) / 86400.0)
	if days_passed == 1:
		day_streak += 1 
	elif days_passed > 1:
		day_streak = 0 
	_last_save_date = today
	
	emit_signal("streak_changed", day_streak)

func _get_today_string() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%d-%02d-%02d" % [d["year"], d["month"], d["day"]]
