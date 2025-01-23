#@tool
#class_name Global
extends Node

#region Signals
#endregion

#region Enums
#endregion

#region Constants
const MAX_SCORE: int = 9999999
#endregion

#region Export Variables
#endregion

#region Public Variables
var color_1: Color = Color.MEDIUM_SEA_GREEN.darkened(0.5)
var color_2: Color = Color.DARK_SLATE_BLUE

var session_axes_max_count: int = 12
var session_axes_draw_enabled: bool
var session_score_bounds_on_enemy_hit: Vector2 = Vector2(5.0, 15.0)
var session_score_bounds_on_enemy_killed: Vector2 = Vector2(15.0, 35.0)
var session_score_bounds_on_base_attacked: Vector2 = Vector2(25.0, 75.0)
var session_score_bounds_on_player_attacked: Vector2 = Vector2(10.0, 50.0)
var session_score: int: set = _set_session_score
var session_is_paused: bool
var session_is_started: bool
var session_blink_cooldown_range: Vector2 = Vector2(1.0, 60.0)
var session_time: float = 300.0

var cursor_move_weight: float = 0.05
var cursor_mode: bool

var enemy_spawn_cooldown: float = 0.5
var enemy_spawn_chance: float = 0.5
var enemy_max_health: int = 5
var enemy_alpha_bounds: Vector2 = Vector2(0.75, 1.0)
var enemy_speed_bounds: Vector2 = Vector2(8.0, 16.0)
var enemy_delay_bounds: Vector2 = Vector2(0.0, 10.0)
#endregion

#region Private Variables
#endregion

#region OnReady Variables
#endregion

#region Virtual Methods
func _ready() -> void:
	cursor_move_weight = clampf(cursor_move_weight, 0.0, 1.0)
	
	session_axes_max_count = clampi(session_axes_max_count, 1, 32)
	session_score_bounds_on_enemy_hit = session_score_bounds_on_enemy_hit.max(Vector2.ZERO)
	session_score_bounds_on_enemy_killed = session_score_bounds_on_enemy_killed.max(Vector2.ZERO)
	session_score_bounds_on_base_attacked = session_score_bounds_on_base_attacked.max(Vector2.ZERO)
	session_score_bounds_on_player_attacked = session_score_bounds_on_player_attacked.max(Vector2.ZERO)
	session_blink_cooldown_range = session_blink_cooldown_range.max(Vector2.ONE * 0.001)
	session_time = maxf(60.0, session_time)
	
	enemy_spawn_cooldown = maxf(0.01, enemy_spawn_cooldown)
	enemy_spawn_chance = clampf(enemy_spawn_chance, 0.0, 1.0)
	enemy_max_health = maxi(1, enemy_max_health)
	enemy_alpha_bounds = enemy_alpha_bounds.clamp(Vector2.ZERO, Vector2.ONE)
	enemy_speed_bounds = enemy_speed_bounds.max(Vector2.ONE)
	enemy_delay_bounds = enemy_delay_bounds.max(Vector2.ZERO)
#endregion

#region Public Methods
#endregion

#region Private Methods
#endregion

#region Static Methods
#endregion

#region Signal Callbacks
#endregion

#region SubClasses
#endregion

#region Setter Methods
func _set_session_score(arg: int) -> void:
	session_score = mini(MAX_SCORE, arg)
#endregion

#region Getter Methods
#endregion
