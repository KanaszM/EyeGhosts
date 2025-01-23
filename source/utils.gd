#@tool
class_name Utils
extends RefCounted

#region Signals
#endregion

#region Enums
#endregion

#region Constants
#endregion

#region Export Variables
#endregion

#region Public Variables
#endregion

#region Private Variables
#endregion

#region OnReady Variables
#endregion

#region Virtual Methods
#endregion

#region Public Methods
#endregion

#region Private Methods
#endregion

#region Static Methods
static func clamp_vector(vector: Vector2, clamp_origin: Vector2, clamp_length: float) -> Vector2:
	return clamp_origin + (vector - clamp_origin).limit_length(clamp_length)


static func generate_alternative_colors(base_color: Color, count: int, hue_strength: float = 0.01) -> PackedColorArray:
	hue_strength = maxf(0.0, hue_strength)
	
	var results: PackedColorArray
	
	for __: int in count:
		results.append(Color.from_hsv(wrapf(base_color.h + randf_range(-hue_strength, hue_strength), 0.0, 1.0), base_color.s, base_color.v))
	
	return results
#endregion

#region Signal Callbacks
#endregion

#region SubClasses
#endregion

#region Setter Methods
#endregion

#region Getter Methods
#endregion
