#@tool
class_name Enemy
extends Area2D

#region Signals
signal interacted(type: InteractionType)
#endregion

#region Enums
enum InteractionType {HIT_BY_PLAYER, KILLED_BY_PLAYER, ATTACKED_BASE, ATTACKED_PLAYER}
#endregion

#region Constants
const Z_INDEX: int = 2
const COLLISION_RADIUS: float = 16.0
const COLOR_LIGHTENED_RATIO: float = 0.25
const MOVE_BACK_SPEED: float = 4.0

const ANIM_DAMAGE: StringName = &"damage"
const ANIM_DEAD: StringName = &"dead"
const ANIM_WALK: StringName = &"walk"

const DETECTION_CHECK_INTERVAL: float = 0.1
const ANIMATION_SPEED_SCALE: float = 2.0
const ALPHA_MODULATE_SPEED: float = 0.25

const RES_SPRITE_FRAMES: SpriteFrames = preload("res://resources/enemy_sprite_frames.tres")
#endregion

#region Export Variables
#endregion

#region Public Variables
var axis: Axis
#endregion

#region Private Variables
var _collision_container: CollisionShape2D
var _collision_shape: CircleShape2D

var _sprite: AnimatedSprite2D
var _timer: Timer
var _tween: Tween

var _mode: bool
var _health: int
var _max_alpha: float
#endregion

#region OnReady Variables
#endregion

#region Virtual Methods
func _ready() -> void:
	if axis == null:
		push_error("Axis reference not provided!")
		queue_free()
		return
	
	_health = randi_range(1, Global.enemy_max_health)
	_max_alpha = randf_range(Global.enemy_alpha_bounds.x, Global.enemy_alpha_bounds.y)
	
	z_index = Z_INDEX
	position = axis.end_point
	rotation = axis.angle
	
	axis.spawned = true
	
	_collision_container = CollisionShape2D.new()
	_collision_container.rotation_degrees = 90.0
	add_child(_collision_container, false, Node.INTERNAL_MODE_BACK)
	
	_collision_shape = CircleShape2D.new()
	_collision_shape.radius = COLLISION_RADIUS
	_collision_container.shape = _collision_shape
	
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = RES_SPRITE_FRAMES
	_sprite.speed_scale = ANIMATION_SPEED_SCALE
	_sprite.modulate.a = 0.0
	_sprite.flip_v = rotation_degrees > 90.0 and rotation_degrees < 270.0
	_sprite.animation_finished.connect(_on_sprite_animation_finished)
	add_child(_sprite, false, Node.INTERNAL_MODE_BACK)
	
	_timer = Timer.new()
	_timer.wait_time = DETECTION_CHECK_INTERVAL
	_timer.autostart = true
	_timer.timeout.connect(_check_detections)
	add_child(_timer, false, Node.INTERNAL_MODE_BACK)
	
	create_tween().tween_property(_sprite, ^"modulate:a", _max_alpha, ALPHA_MODULATE_SPEED)
	
	_move(true)


func _check_detections() -> void:
	var detected_areas: Array[Area2D] = get_overlapping_areas()
	
	if detected_areas.is_empty():
		return
	
	for area: Area2D in detected_areas:
		if area is Base:
			interacted.emit(InteractionType.ATTACKED_BASE)
			remove()
			return
		
		elif area is Cursor:
			if Global.cursor_mode == _mode:
				_health -= 1
				
				if _health == 0:
					interacted.emit(InteractionType.KILLED_BY_PLAYER)
					remove()
					return
				
				interacted.emit(InteractionType.HIT_BY_PLAYER)
				_move(false)
				return
			
			else:
				interacted.emit(InteractionType.ATTACKED_PLAYER)
				remove()
				return
#endregion

#region Public Methods
func remove(instant: bool = false) -> void:
	set_physics_process(false)
	_kill_timer()
	
	axis.spawned = false
	
	if instant:
		queue_free()
		return
	
	_collision_container.disabled = true
	_sprite.play(ANIM_DEAD)
#endregion

#region Private Methods
func _move(state: bool) -> void:
	_kill_timer()
	
	_tween = create_tween()
	
	if state:
		_mode = bool(randf() > 0.5)
		
		var tweener_move: PropertyTweener
		var tweener_animate: CallbackTweener
		var tweener_modulate: PropertyTweener
		
		var speed: float = randf_range(Global.enemy_speed_bounds.x, Global.enemy_speed_bounds.y)
		var delay: float = randf_range(Global.enemy_delay_bounds.x, Global.enemy_delay_bounds.y)
		var color: Color = (Global.color_1 if _mode else Global.color_2).lightened(COLOR_LIGHTENED_RATIO)
		
		color.a = _max_alpha
		
		tweener_move = _tween.tween_property(self, ^"position", axis.start_point, speed)
		tweener_move.set_ease(Tween.EASE_IN_OUT)
		tweener_move.set_trans(Tween.TRANS_BACK)
		tweener_move.set_delay(delay)
		
		tweener_modulate = _tween.parallel().tween_property(_sprite, ^"modulate", color, speed / 2.0)
		tweener_modulate.set_delay(delay)
		
		tweener_animate = _tween.parallel().tween_callback(_sprite.play.bind(ANIM_WALK))
		tweener_animate.set_delay(delay)
	
	else:
		var tweener_move: PropertyTweener
		
		_sprite.modulate = Color.WHITE
		
		_tween.tween_callback(_sprite.play.bind(ANIM_DAMAGE))
		
		tweener_move = _tween.tween_property(self, ^"position", axis.end_point, MOVE_BACK_SPEED)
		tweener_move.set_ease(Tween.EASE_OUT)
		tweener_move.set_trans(Tween.TRANS_ELASTIC)
		
		_tween.finished.connect(_move.bind(true))


func _kill_timer() -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
#endregion

#region Static Methods
#endregion

#region Signal Callbacks
func _on_sprite_animation_finished() -> void:
	if _sprite.animation == ANIM_DEAD:
		queue_free()
#endregion

#region SubClasses
#endregion

#region Setter Methods
#endregion

#region Getter Methods
#endregion
