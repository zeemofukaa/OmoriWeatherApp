extends Node2D

# --------------------
# ONREADY
# --------------------
@onready var axolotl            := $Axolotl
@onready var ui                 := $UI
@onready var background         := $Background
@onready var device_shell       := $UI/Control/DeviceShell
@onready var energy_warning     := $UI/Control/EnergyWarning
@onready var hunger_warning     := $UI/Control/HungerWarning
@onready var happiness_warning  := $UI/Control/HappinessWarning
@onready var stats_slot         := $UI/Control/StatsSlot
@onready var streak_frame       := $UI/Control/StreakFrame
@onready var sleep_bar          := $Axolotl/Control/SleepBar
@onready var bg_music           := $BgMusic
@onready var sfx_eat            := $SfxEat
@onready var sfx_play           := $SfxPlay
@onready var sfx_sleep          := $SfxSleep
@onready var sfx_full           := $SfxFull
@onready var sfx_squish         := $SfxSquish
@onready var sfx_ded            := $SfxDed
@onready var sfx_click          := $SfxClick

# --------------------
# CONSTANTS & VARS
# --------------------
const MUSIC_NORMAL_VOL: float = 0.0
const MUSIC_DUCK_VOL:   float = -12.0

var _is_night:  bool  = false
var _duck_tween: Tween

var _loading: bool = true

# --------------------
# NOTIFICATION
# --------------------
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		axolotl._save_game()
		get_tree().quit()
# --------------------
# READY
# --------------------
func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	axolotl.streak_changed.connect(ui.update_streak)
	ui.button_clicked.connect(play_sfx_click)
	axolotl.stats_changed.connect(ui.update_stats)
	axolotl.state_changed.connect(_on_axolotl_state_changed)
	axolotl.entered_critical.connect(ui.set_critical)
	axolotl.entered_critical.connect(play_sfx_ded)
	ui.reset_pressed.connect(axolotl.reset_pet)
	_check_time_of_day()
	ui.update_streak(axolotl.day_streak)
	call_deferred("_set_loading_done")

# --------------------
# LOADING
# --------------------
func _set_loading_done() -> void:
	_loading = false

# --------------------
# PROCESS
# --------------------
func _process(delta: float) -> void:
	_update_mood(delta)

# --------------------
# MOOD
# --------------------
func _update_mood(delta: float) -> void:
	var avg_stat: float = (axolotl.hunger + axolotl.energy + axolotl.happiness) / 3.0
	var target_color: Color

	if _is_night:
		if avg_stat >= 60.0:
			target_color = Color(0.85, 0.85, 1.0)
		elif avg_stat >= 30.0:
			target_color = Color(0.813, 0.725, 0.898, 1.0)
		else:
			target_color = Color(0.866, 0.56, 0.687)
	else:
		if avg_stat >= 60.0:
			target_color = Color(1.0, 1.0, 1.0)
		elif avg_stat >= 30.0:
			target_color = Color(0.85, 0.85, 1.0)
		else:
			target_color = Color(1.0, 0.547, 0.563, 1.0)

	$Background.modulate = $Background.modulate.lerp(target_color, delta * 0.8)
	$Screen.modulate      = $Screen.modulate.lerp(target_color, delta * 1.5)

# --------------------
# TIME OF DAY
# --------------------
func _check_time_of_day() -> void:
	var hour: int = Time.get_datetime_dict_from_system()["hour"]
	_is_night = (hour >= 20 or hour < 5)
	_apply_time_of_day()

func _apply_time_of_day() -> void:
	if _is_night:
		background.texture     = preload("res://Assets/bg_night.png")
		device_shell.modulate  = Color(0.79,  0.792, 0.959)
		stats_slot.modulate    = Color(0.965, 0.852, 0.96)
		sleep_bar.modulate     = Color(0.951, 0.783, 0.981)
		streak_frame.modulate     = Color(0.978, 0.885, 0.955, 1.0)
		energy_warning.modulate    = Color(0.53,  0.77,  0.832)
		hunger_warning.modulate    = Color(0.951, 0.76,  0.751)
		happiness_warning.modulate = Color(0.744, 0.731, 0.931)
		$Screen.modulate       = Color(0.592, 0.805, 0.993)
	else:
		background.texture     = preload("res://Assets/bg.png")
		device_shell.modulate  = Color(1.0, 1.0, 1.0)
		stats_slot.modulate    = Color(1.0, 1.0, 1.0)
		sleep_bar.modulate     = Color(1.0, 1.0, 1.0)
		streak_frame.modulate     = Color(1.0, 1.0, 1.0)
		energy_warning.modulate    = Color(1.0, 1.0, 1.0)
		hunger_warning.modulate    = Color(1.0, 1.0, 1.0)
		happiness_warning.modulate = Color(1.0, 1.0, 1.0)
		$Screen.modulate       = Color(1.0, 1.0, 1.0)
	_play_bg_music()
	axolotl.set_night_mode(_is_night)

# --------------------
# MUSIC
# --------------------
func _play_bg_music() -> void:
	bg_music.stop()
	bg_music.stream = preload("res://Assets/Audio/bg_night.mp3") if _is_night \
					else preload("res://Assets/Audio/bg_day.mp3")
	bg_music.stream.loop = true
	bg_music.volume_db   = MUSIC_NORMAL_VOL
	bg_music.play()

func _duck_music() -> void:
	if _duck_tween:
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_property(bg_music, "volume_db", MUSIC_DUCK_VOL, 0.15)

func _unduck_music(after_seconds: float) -> void:
	if _duck_tween:
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_interval(after_seconds)
	_duck_tween.tween_property(bg_music, "volume_db", MUSIC_NORMAL_VOL, 0.4)

# --------------------
# SFX
# --------------------
func play_sfx_eat() -> void:
	_duck_music()
	sfx_eat.play()
	await get_tree().create_timer(2.0).timeout
	sfx_eat.stop()
	_unduck_music(0.0)

func play_sfx_play() -> void:
	_duck_music()
	sfx_play.play()
	if sfx_play.stream:
		_unduck_music(sfx_play.stream.get_length())
	else:
		_unduck_music(1.0)

func play_sfx_sleep() -> void:
	_duck_music()
	sfx_sleep.play()
	if sfx_sleep.stream:
		_unduck_music(sfx_sleep.stream.get_length())
	else:
		_unduck_music(1.0)

func play_sfx_full() -> void:
	_duck_music()
	sfx_full.play()
	if sfx_full.stream:
		_unduck_music(sfx_full.stream.get_length())
	else:
		_unduck_music(1.0)

func play_sfx_squish() -> void:
	_duck_music()
	sfx_squish.play()
	if sfx_squish.stream:
		_unduck_music(sfx_squish.stream.get_length())
	else:
		_unduck_music(1.0)
		
func play_sfx_ded() -> void:
	_duck_music()
	sfx_ded.play()
	if sfx_ded.stream:
		_unduck_music(sfx_ded.stream.get_length())
	else:
		_unduck_music(2.0)

func play_sfx_click() -> void:
	sfx_click.play()

# --------------------
# STATE CHANGES
# --------------------
func _on_axolotl_state_changed(new_state) -> void:
	match new_state:
		axolotl.State.SLEEPING:
			ui.set_sleeping(true)
			if not _loading:
				play_sfx_sleep()
		axolotl.State.IDLE:
			ui.set_sleeping(false)
			ui.set_busy(false)
			if axolotl.energy <= 20.0:
				ui.play_btn.disabled = true
		axolotl.State.EATING:
			ui.set_busy(true)
			if not _loading:  
				play_sfx_eat()
		axolotl.State.PLAYING:
			ui.set_busy(true)  
			if not _loading:
				play_sfx_play()
		axolotl.State.FULL:
			ui.set_busy(true) 
			if not _loading: 
				play_sfx_full()
		axolotl.State.CRITICAL:
			if not _loading:
				play_sfx_ded()
			ui.set_critical()
		_:
			ui.set_busy(true)

# --------------------
# UI CALLBACKS
# --------------------
func _on_ui_feed()  -> void: axolotl.eat()
func _on_ui_play()  -> void: axolotl.play()
func _on_ui_sleep() -> void: axolotl.sleep()

# --------------------
# INPUT
# --------------------
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SLASH:
			_is_night = !_is_night
			_apply_time_of_day()
			axolotl.set_night_mode(_is_night)
		if event.keycode == KEY_W:
					if axolotl.state == axolotl.State.SLEEPING:
						sfx_sleep.stop()
						_unduck_music(0.0)
						axolotl.is_busy = false
						axolotl._sleep_min_timer = 0.0
						axolotl._modify_stats(0.0, axolotl.SLEEP_ENERGY, 0.0)
						axolotl.change_state(axolotl.State.IDLE)
