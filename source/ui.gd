#@tool
class_name UI
extends CanvasLayer

#region Signals
#endregion

#region Enums
#endregion

#region Constants
const GROUP_SCORE_NOTIFICATION_LABEL: StringName = &"score_notification_label"

const SCORE_NOTIFICATION_RANDOM_DRIFT_H_BOUNDS: Vector2 = Vector2(-50.0, 50.0)
const SCORE_NOTIFICATION_RANDOM_DRIFT_V_BOUNDS: Vector2 = Vector2(-100.0, 120.0)
const SCORE_NOTIFICATION_COLOR_POSITIVE: Color = Color.GREEN
const SCORE_NOTIFICATION_COLOR_NEGATIVE: Color = Color.RED
const SCORE_NOTIFICATION_COLOR_SHADOW: Color = Color.BLACK
const SCORE_NOTIFICATION_SHADOW_OFFSET: int = 2
const SCORE_NOTIFICATION_FONT_SIZE: int = 24
const SCORE_NOTIFICATION_TWEEN_SCALE_SPEED: float = 0.25
const SCORE_NOTIFICATION_TWEEN_MODUlATE_SPEED: float = 0.15
const SCORE_NOTIFICATION_TWEEN_POSITION_SPEED: float = 0.4

const SCORE_GLOBAL_TWEEN_UPDATE_VALUE_SPEED: float = 0.5
const SCORE_GLOBAL_TWEEN_UPDATE_ANIMATION_SPEED: float = 0.25
const SCORE_GLOBAL_TWEEN_SCALE_RATIO: float = 1.5
const SCORE_GLOBAL_TWEEN_COLOR_LIGHTENED_RATIO: float = 0.5

const PAUSE_TWEEN_TIME_SCALE_VALUE: float = 0.2
const PAUSE_TWEEN_TIME_SCALE_SPEED_ON: float = 0.1
const PAUSE_TWEEN_TIME_SCALE_SPEED_OFF: float = 0.5
#endregion

#region Export Variables
@export var session: Session
#endregion

#region Public Variables
#endregion

#region Private Variables
var _engine_time_scale_tween: Tween
#endregion

#region OnReady Variables
@onready var TimerSession := %TimerSession as Timer

@onready var SessionElements := %SessionElements as Control
@onready var LabelScore := %LabelScore as Label
@onready var LabelTimeMinutes := %LabelTimeMinutes as Label
@onready var LabelTimeSeconds := %LabelTimeSeconds as Label

@onready var PanelPauseBackground := %PanelPauseBackground as ColorRect
@onready var MarginPauseBackground := %MarginPauseBackground as MarginContainer
@onready var VBoxBackground := %VBoxBackground as VBoxContainer
@onready var LabelPauseTitle := %LabelPauseTitle as Label

@onready var MarginInfo := %MarginInfo as MarginContainer
@onready var HBoxInfo := %HBoxInfo as HBoxContainer

@onready var PanelInstructions := %PanelInstructions as PanelContainer
@onready var MarginInstructions := %MarginInstructions as MarginContainer
@onready var LabelInstructions := %LabelInstructions as Label

@onready var PanelCredits := %PanelCredits as PanelContainer
@onready var MarginCredits := %MarginCredits as MarginContainer
@onready var LabelCredits := %LabelCredits as Label

@onready var PanelHighScore := %PanelHighScore as PanelContainer
@onready var VBoxHighScore := %VBoxHighScore as VBoxContainer
@onready var LabelHighScore := %LabelHighScore as Label

@onready var VboxButtons := %VboxButtons as VBoxContainer
@onready var ButtonNewGame := %ButtonNewGame as Button
@onready var ButtonResume := %ButtonResume as Button
@onready var ButtonInfo := %ButtonInfo as Button
@onready var ButtonExit := %ButtonExit as Button
#endregion

#region Virtual Methods
func _ready() -> void:
	var is_web: bool = OS.get_name() == "Web"
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	TimerSession.timeout.connect(_on_TimerSession_timeout)
	
	PanelHighScore.visible = false
	MarginInfo.visible = false
	ButtonExit.visible = not is_web
	
	if is_web:
		PanelPauseBackground.material = null
		PanelPauseBackground.color = Color.BLACK
		PanelPauseBackground.color.a = 0.5
	
	for button: Button in [ButtonNewGame, ButtonResume, ButtonInfo, ButtonExit]:
		button.pressed.connect(_on_button_pressed.bind(button))
	
	_set_pause_screen(true)


func _process(_delta: float) -> void:
	LabelTimeMinutes.text = str(int(TimerSession.time_left / 60.0))
	LabelTimeSeconds.text = str(int(TimerSession.time_left) % 60)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_input := event as InputEventKey
		
		if key_input.pressed:
			match key_input.keycode:
				KEY_ESCAPE: _set_pause_screen(not Global.session_is_paused)
#endregion

#region Public Methods
func update_score(value: int, position: Vector2) -> void:
	Global.session_score += value
	
	_update_global_score_label()
	
	if position == Vector2.ZERO:
		return
	
	var label: Label = Label.new()
	var tween: Tween = create_tween()
	var random_drift: float = randf_range(SCORE_NOTIFICATION_RANDOM_DRIFT_H_BOUNDS.x, SCORE_NOTIFICATION_RANDOM_DRIFT_H_BOUNDS.y)
	
	label.text = str(value)
	label.modulate.a = 0.0
	label.global_position = position
	label.position.x -= label.size.x / 2.0
	label.scale = Vector2.ZERO
	
	label.add_to_group(GROUP_SCORE_NOTIFICATION_LABEL)
	label.add_theme_color_override(&"font_color", SCORE_NOTIFICATION_COLOR_POSITIVE if value > 0 else SCORE_NOTIFICATION_COLOR_NEGATIVE)
	label.add_theme_color_override(&"font_shadow_color", SCORE_NOTIFICATION_COLOR_SHADOW)
	label.add_theme_constant_override(&"shadow_offset_x", SCORE_NOTIFICATION_SHADOW_OFFSET)
	label.add_theme_constant_override(&"shadow_offset_y", SCORE_NOTIFICATION_SHADOW_OFFSET)
	label.add_theme_font_size_override(&"font_size", SCORE_NOTIFICATION_FONT_SIZE)
	
	SessionElements.add_child(label)
	
	tween.tween_property(
		label, ^"scale", Vector2.ONE, SCORE_NOTIFICATION_TWEEN_SCALE_SPEED
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	
	tween.parallel().tween_property(
		label, ^"modulate:a", 1.0, SCORE_NOTIFICATION_TWEEN_MODUlATE_SPEED
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	tween.parallel().tween_property(
		label, ^"global_position", position + Vector2(random_drift, SCORE_NOTIFICATION_RANDOM_DRIFT_V_BOUNDS.x), SCORE_NOTIFICATION_TWEEN_POSITION_SPEED
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	
	tween.chain().tween_property(
		label, ^"modulate:a", 0.0, SCORE_NOTIFICATION_TWEEN_MODUlATE_SPEED * 2.0
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	
	tween.parallel().tween_property(
		label, ^"global_position", position + Vector2(random_drift, SCORE_NOTIFICATION_RANDOM_DRIFT_V_BOUNDS.y), SCORE_NOTIFICATION_TWEEN_POSITION_SPEED * 2.0
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	
	tween.finished.connect(label.queue_free)
#endregion

#region Private Methods
func _set_pause_screen(state: bool) -> void:
	if not state and not Global.session_is_started:
		return
	
	set_process(not state)
	get_tree().paused = state
	
	Global.session_is_paused = state
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if state else Input.MOUSE_MODE_CONFINED_HIDDEN
	
	TimerSession.paused = state
	SessionElements.visible = not state
	PanelPauseBackground.visible = state
	ButtonResume.visible = Global.session_is_started
	
	if _engine_time_scale_tween != null:
		_engine_time_scale_tween.kill()
	
	_engine_time_scale_tween = create_tween()
	_engine_time_scale_tween.tween_property(
		Engine, ^"time_scale", PAUSE_TWEEN_TIME_SCALE_VALUE if state else 1.0, PAUSE_TWEEN_TIME_SCALE_SPEED_ON if state else PAUSE_TWEEN_TIME_SCALE_SPEED_OFF
		)


func _start_new_game() -> void:
	PanelHighScore.visible = false
	
	LabelScore.text = ""
	LabelTimeMinutes.text = ""
	LabelTimeSeconds.text = ""
	
	get_tree().get_nodes_in_group(GROUP_SCORE_NOTIFICATION_LABEL).map(func(node: Node) -> void: node.queue_free())
	
	session.restart()
	
	await get_tree().process_frame
	
	_set_pause_screen(false)
	TimerSession.start(Global.session_time)


func _update_global_score_label() -> void:
	var func_update_score_display: Callable = func(current_score: int) -> void: LabelScore.text = str(current_score)
	var color: Color = (Color.GREEN if Global.session_score > 0 else Color.RED).lightened(SCORE_GLOBAL_TWEEN_COLOR_LIGHTENED_RATIO)
	var tween: Tween = create_tween()
	
	tween.tween_method(
		func_update_score_display, int(LabelScore.text), Global.session_score, SCORE_GLOBAL_TWEEN_UPDATE_VALUE_SPEED
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	
	tween.parallel().tween_property(
		LabelScore, ^"modulate", color, SCORE_GLOBAL_TWEEN_UPDATE_ANIMATION_SPEED
		)
	
	tween.parallel().tween_property(
		LabelScore, ^"scale", Vector2.ONE * SCORE_GLOBAL_TWEEN_SCALE_RATIO, SCORE_GLOBAL_TWEEN_UPDATE_ANIMATION_SPEED
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	
	tween.chain().tween_property(
		LabelScore, ^"scale", Vector2.ONE, SCORE_GLOBAL_TWEEN_UPDATE_ANIMATION_SPEED
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
#endregion

#region Static Methods
#endregion

#region Signal Callbacks
func _on_TimerSession_timeout() -> void:
	var func_update_score_display: Callable = func(current_score: int) -> void: LabelHighScore.text = str(current_score)
	var color: Color = Color.GREEN if Global.session_score > 0 else Color.RED
	var tween: Tween = create_tween()
	
	PanelHighScore.visible = true
	
	tween.tween_method(
		func_update_score_display, int(LabelHighScore.text), Global.session_score, SCORE_GLOBAL_TWEEN_UPDATE_VALUE_SPEED
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	
	tween.tween_property(
		LabelHighScore, ^"modulate", color, SCORE_GLOBAL_TWEEN_UPDATE_ANIMATION_SPEED
		)
	
	session.stop()
	
	await get_tree().process_frame
	
	_set_pause_screen(true)


func _on_button_pressed(button: Button) -> void:
	match button:
		ButtonNewGame: _start_new_game()
		ButtonResume: _set_pause_screen(false)
		ButtonInfo: MarginInfo.visible = not MarginInfo.visible
		ButtonExit: get_tree().quit()
#endregion

#region SubClasses
#endregion

#region Setter Methods
#endregion

#region Getter Methods
#endregion
