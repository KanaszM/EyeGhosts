#@tool
class_name Session
extends Control

#region Signals
#endregion

#region Enums
#endregion

#region Constants
const AXIS_DRAW_COLOR: Color = Color("cccccc")
const AXIS_DRAW_WIDTH: int = 4

const SHADER_MOVE_MAX_OFFSET: float = 40.0

const SHADER_PARAM_COLOR_TOP_LEFT: StringName = &"top_left"
const SHADER_PARAM_COLOR_TOP_RIGHT: StringName = &"top_right"
const SHADER_PARAM_COLOR_BOTTOM_LEFT: StringName = &"bottom_left"
const SHADER_PARAM_COLOR_BOTTOM_RIGHT: StringName = &"bottom_right"

const DAMAGE_TWEEN_MODULATE_ON_SPEED: float = 0.10
const DAMAGE_TWEEN_MODULATE_OFF_SPEED: float = 0.25
const DAMAGE_TWEEN_MODULATE_COLOR: Color = Color.ORANGE_RED
const DAMAGE_TWEEN_SHAKES_COUNT: int = 5
const DAMAGE_TWEEN_SHAKES_SPEED_ON: float = 0.03
const DAMAGE_TWEEN_SHAKES_SPEED_OFF: float = 0.1
const DAMAGE_TWEEN_SHAKES_H_OFFSET: float = 10.0
const DAMAGE_TWEEN_SHAKES_V_OFFSET: float = 5.0

const BLINK_TWEEN_SPEED_ON: float = 0.15
const BLINK_TWEEN_SPEED_OFF: float = 0.5
const BLINK_TWEEN_VALUE: float = 0.5
#endregion

#region Export Variables
#endregion

#region Public Variables
#endregion

#region Private Variables
var _circle_background_half_size: Vector2
var _circle_foreground_half_size: Vector2

var _half_viewport_size: Vector2
var _half_viewport_length: float

var _axes: Dictionary[int, Axis]
#endregion

#region OnReady Variables
@onready var UIRef := %UIRef as UI

@onready var TimerSpawnCooldown := %TimerSpawnCooldown as Timer
@onready var TimerBlinkCooldown := %TimerBlinkCooldown as Timer

@onready var ColorBackground := %ColorBackground as ColorRect
@onready var ColorShader := %ColorShader as ColorRect
@onready var ColorShaderShader := ColorShader.material as ShaderMaterial

@onready var PanelVignetteBackground := %PanelVignetteBackground as PanelContainer
@onready var PanelVignetteForegroundTop := %PanelVignetteForegroundTop as PanelContainer
@onready var PanelVignetteForegroundTopPanel := PanelVignetteForegroundTop.get_theme_stylebox(&"panel") as StyleBoxTexture
@onready var PanelVignetteForegroundTopTexture := PanelVignetteForegroundTopPanel.texture as GradientTexture2D
@onready var PanelVignetteForegroundTopGradient := PanelVignetteForegroundTopTexture.gradient as Gradient
@onready var PanelVignetteForegroundBottom := %PanelVignetteForegroundBottom as PanelContainer
@onready var PanelVignetteForegroundBottomPanel := PanelVignetteForegroundBottom.get_theme_stylebox(&"panel") as StyleBoxTexture
@onready var PanelVignetteForegroundBottomTexture := PanelVignetteForegroundBottomPanel.texture as GradientTexture2D
@onready var PanelVignetteForegroundBottomGradient := PanelVignetteForegroundBottomTexture.gradient as Gradient

@onready var MarginBackground := %MarginBackground as MarginContainer
@onready var AspectBackground := %AspectBackground as AspectRatioContainer

@onready var RoundPanelOuter := %RoundPanelOuter as RoundPanel
@onready var PanelGradient := %PanelGradient as PanelContainer
@onready var RoundPanelInner := %RoundPanelInner as RoundPanel

@onready var AreaBase := %AreaBase as Area2D
@onready var CollisionContainerBase := %CollisionContainerBase as CollisionShape2D
@onready var CollisionShapeBase := CollisionContainerBase.shape as CircleShape2D
@onready var PanelBase := %PanelBase as PanelContainer

@onready var AreaCursor := %AreaCursor as Area2D
@onready var CollisionContainerCursor := %CollisionContainerCursor as CollisionShape2D
@onready var CollisionShapeCursor := CollisionContainerCursor.shape as CircleShape2D
@onready var RoundPanelCursor := %RoundPanelCursor as RoundPanel

@onready var EnemyContainer := %EnemyContainer as Node2D
#endregion

#region Virtual Methods
func _ready() -> void:
	stop()
	
	UIRef.visible = true
	TimerSpawnCooldown.timeout.connect(_on_TimerSpawnCooldown_timeout)
	TimerBlinkCooldown.timeout.connect(_animate_blink)
	
	_half_viewport_size = get_viewport_rect().size / 2.0
	_half_viewport_length = _half_viewport_size.length()
	
	var callbacks: Array[Callable] = [
		_recalculate_half_sizes,
		_reposition_panels,
		_reposition_areas,
		_generate_axes,
		queue_redraw,
		]
	
	for callback: Callable in callbacks:
		callback.call_deferred()
		await get_tree().process_frame


func _physics_process(_delta: float) -> void:
	AreaCursor.global_position = AreaCursor.global_position.lerp(_get_calculated_cursor_position(), Global.cursor_move_weight)
	ColorShader.position = ColorShader.position.lerp(
		(_half_viewport_size - get_global_mouse_position()).normalized() * SHADER_MOVE_MAX_OFFSET, Global.cursor_move_weight
		)


func _draw() -> void:
	if Global.session_axes_draw_enabled:
		for axis_idx: int in _axes:
			var axis: Axis = _axes[axis_idx]
			
			draw_line(axis.start_point, axis.end_point, AXIS_DRAW_COLOR, AXIS_DRAW_WIDTH)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_input := event as InputEventMouseButton
		
		if mouse_button_input.pressed:
			match mouse_button_input.button_index:
				MOUSE_BUTTON_LEFT: _set_cursor_mode(true)
				MOUSE_BUTTON_RIGHT: _set_cursor_mode(false)
				MOUSE_BUTTON_MIDDLE:
					pass
					#UIRef.update_score(randi_range(-1000, 1000), get_global_mouse_position())
					#_animate_damage()
					#_animate_blink()
					#restart()
#endregion

#region Public Methods
func restart() -> void:
	stop()
	
	await get_tree().process_frame
	
	TimerSpawnCooldown.start(Global.enemy_spawn_cooldown)
	TimerBlinkCooldown.start(randf_range(Global.session_blink_cooldown_range.x, Global.session_blink_cooldown_range.y))
	
	Global.session_score = 0
	Global.session_is_started = true
	
	AreaCursor.visible = true
	
	_set_cursor_mode(true)
	set_physics_process(true)


func stop() -> void:
	set_physics_process(false)
	AreaCursor.visible = false
	
	Global.session_is_started = false
	
	if not TimerSpawnCooldown.is_stopped():
		TimerSpawnCooldown.stop()
	
	if not TimerBlinkCooldown.is_stopped():
		TimerBlinkCooldown.stop()
	
	_get_enemies().map(func(enemy: Enemy) -> void: enemy.remove(true))
#endregion

#region Private Methods
func _get_enemies() -> Array[Enemy]:
	return Array(EnemyContainer.get_children(), TYPE_OBJECT, &"Area2D", Enemy)


func _add_enemy(axis_idx: int) -> void:
	if axis_idx not in _axes:
		push_error("Invalid axis index: %d" % axis_idx)
		return
	
	var axis: Axis = _axes[axis_idx]
	var enemy: Enemy = Enemy.new()
	
	enemy.axis = axis
	enemy.interacted.connect(_on_enemy_interacted.bind(enemy))
	
	EnemyContainer.add_child(enemy)


func _get_calculated_cursor_position() -> Vector2:
	return Utils.clamp_vector(
		AreaCursor.get_global_mouse_position(),
		RoundPanelInner.global_position + _circle_foreground_half_size,
		_circle_foreground_half_size.x - CollisionShapeCursor.radius - float(RoundPanelInner.border_width_all)
		)


func _recalculate_half_sizes() -> void:
	_circle_background_half_size = RoundPanelOuter.size / 2.0
	_circle_foreground_half_size = RoundPanelInner.size / 2.0


func _reposition_panels() -> void:
	RoundPanelCursor.size = Vector2.ONE * CollisionShapeCursor.radius * 2.0
	RoundPanelCursor.position -= RoundPanelCursor.size / 2.0
	
	PanelBase.size = Vector2.ONE * CollisionShapeBase.radius * 2.0
	PanelBase.position -= PanelBase.size / 2.0


func _reposition_areas() -> void:
	AreaCursor.global_position = _get_calculated_cursor_position()
	AreaBase.global_position = RoundPanelInner.global_position + _circle_foreground_half_size


func _generate_axes() -> void:
	var center: Vector2 = RoundPanelInner.global_position + _circle_foreground_half_size
	var angle_step: float = 2.0 * PI / Global.session_axes_max_count
	
	_axes.clear()
	
	for axis_idx: int in Global.session_axes_max_count:
		var angle: float = axis_idx * angle_step
		var direction: Vector2 = Vector2(cos(angle), sin(angle))
		var axis: Axis = Axis.new()
		
		axis.angle = angle
		axis.start_point = center + direction * CollisionShapeBase.radius
		axis.end_point = center + direction * (_circle_background_half_size.x - float(RoundPanelOuter.border_width_all))
		
		_axes[axis_idx] = axis


func _set_cursor_mode(state: bool) -> void:
	if state == Global.cursor_mode:
		return
	
	Global.cursor_mode = state
	RoundPanelCursor.modulate = Global.color_1 if state else Global.color_2
	
	var colors: PackedColorArray = Utils.generate_alternative_colors(RoundPanelCursor.modulate, 4)
	
	ColorShaderShader.set_shader_parameter(SHADER_PARAM_COLOR_TOP_LEFT, colors[0])
	ColorShaderShader.set_shader_parameter(SHADER_PARAM_COLOR_TOP_RIGHT, colors[1])
	ColorShaderShader.set_shader_parameter(SHADER_PARAM_COLOR_BOTTOM_LEFT, colors[2])
	ColorShaderShader.set_shader_parameter(SHADER_PARAM_COLOR_BOTTOM_RIGHT, colors[3])


func _animate_damage() -> void:
	var tween: Tween = create_tween()
	var original_position: Vector2 = RoundPanelInner.position
	
	tween.tween_property(
		RoundPanelInner, ^"modulate", DAMAGE_TWEEN_MODULATE_COLOR, DAMAGE_TWEEN_MODULATE_ON_SPEED
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	for __: int in DAMAGE_TWEEN_SHAKES_COUNT:
		var random_position_offset: Vector2 = Vector2(
			randf_range(-DAMAGE_TWEEN_SHAKES_H_OFFSET, DAMAGE_TWEEN_SHAKES_H_OFFSET),
			randf_range(-DAMAGE_TWEEN_SHAKES_V_OFFSET, DAMAGE_TWEEN_SHAKES_V_OFFSET)
			)
		
		tween.chain().tween_property(
			RoundPanelInner, ^"position", original_position + random_position_offset, DAMAGE_TWEEN_SHAKES_SPEED_ON
			).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	tween.chain().tween_property(
		RoundPanelInner, ^"modulate", Color.WHITE, DAMAGE_TWEEN_MODULATE_OFF_SPEED
		).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	
	tween.parallel().tween_property(
		RoundPanelInner, ^"position", original_position, DAMAGE_TWEEN_SHAKES_SPEED_OFF
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)


func _animate_blink() -> void:
	var tween: Tween = create_tween()
	
	tween.tween_property(
		PanelVignetteForegroundTopTexture, ^"fill_to:y", BLINK_TWEEN_VALUE, BLINK_TWEEN_SPEED_ON
		).from(0.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	tween.parallel().tween_property(
		PanelVignetteForegroundBottomTexture, ^"fill_to:y", BLINK_TWEEN_VALUE, BLINK_TWEEN_SPEED_ON
		).from(1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	tween.chain().tween_property(
		PanelVignetteForegroundTopTexture, ^"fill_to:y", 0.0, BLINK_TWEEN_SPEED_OFF
		).from(BLINK_TWEEN_VALUE)
	
	tween.parallel().tween_property(
		PanelVignetteForegroundBottomTexture, ^"fill_to:y", 1.0, BLINK_TWEEN_SPEED_OFF
		).from(BLINK_TWEEN_VALUE)
	
	TimerBlinkCooldown.start(randf_range(Global.session_blink_cooldown_range.x, Global.session_blink_cooldown_range.y))
#endregion

#region Static Methods
#endregion

#region Signal Callbacks
func _on_TimerSpawnCooldown_timeout() -> void:
	if randf() > Global.enemy_spawn_chance:
		var free_axis_indexes: PackedInt32Array
		
		for axis_idx: int in _axes:
			var axis: Axis = _axes[axis_idx]
			
			if not axis.spawned:
				free_axis_indexes.append(axis_idx)
		
		if not free_axis_indexes.is_empty():
			_add_enemy(free_axis_indexes[randi_range(0, free_axis_indexes.size() - 1)])
	
	TimerSpawnCooldown.start(Global.enemy_spawn_cooldown)


func _on_enemy_interacted(interaction_type: Enemy.InteractionType, enemy: Enemy) -> void:
	var distance_to_center: float = (enemy.global_position - _half_viewport_size).length() - CollisionShapeBase.radius * 2.0
	var distance_factor: float = 1.0 - clampf(distance_to_center / _half_viewport_length, 0.0, 1.0)
	var calculated_score: int
	
	match interaction_type:
		Enemy.InteractionType.HIT_BY_PLAYER:
			calculated_score = int(lerpf(Global.session_score_bounds_on_enemy_hit.x, Global.session_score_bounds_on_enemy_hit.y, distance_factor))
		
		Enemy.InteractionType.KILLED_BY_PLAYER:
			calculated_score = int(lerpf(Global.session_score_bounds_on_enemy_killed.x, Global.session_score_bounds_on_enemy_killed.y, distance_factor))
		
		Enemy.InteractionType.ATTACKED_BASE:
			calculated_score = int(lerpf(-Global.session_score_bounds_on_base_attacked.x, -Global.session_score_bounds_on_base_attacked.y, distance_factor))
			_animate_damage()
		
		Enemy.InteractionType.ATTACKED_PLAYER:
			calculated_score = int(lerpf(-Global.session_score_bounds_on_player_attacked.x, -Global.session_score_bounds_on_player_attacked.y, distance_factor))
			_animate_damage()
	
	UIRef.update_score(calculated_score, enemy.global_position)
#endregion

#region SubClasses
#endregion

#region Setter Methods
#endregion

#region Getter Methods
#endregion
