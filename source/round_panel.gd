@tool
class_name RoundPanel
extends PanelContainer

#region Signals
#endregion

#region Enums
#endregion

#region Constants
#endregion

#region Export Variables
@export var style: StyleBoxFlat: set = _set_style
@export var border_width_all: int: set = _set_border_width_all
#endregion

#region Public Variables
#endregion

#region Private Variables
#endregion

#region OnReady Variables
#endregion

#region Virtual Methods
func _ready() -> void:
	resized.connect(_on_resized)
#endregion

#region Public Methods
#endregion

#region Private Methods
func _update_corners() -> void:
	if style == null:
		return
	
	style.set_corner_radius_all(int(int(min(size.x, size.y) / 2.0)) - 1)
#endregion

#region Static Methods
#endregion

#region Signal Callbacks
func _on_resized() -> void:
	_update_corners.call_deferred()
#endregion

#region SubClasses
#endregion

#region Setter Methods
func _set_style(arg: StyleBoxFlat) -> void:
	style = arg
	add_theme_stylebox_override(&"panel", style)
	_update_corners.call_deferred()


func _set_border_width_all(arg: int) -> void:
	border_width_all = maxi(0, arg)
	
	if style != null:
		style.set_border_width_all(border_width_all)
#endregion

#region Getter Methods
#endregion
