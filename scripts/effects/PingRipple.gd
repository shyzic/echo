extends Node2D

@onready var light: PointLight2D = $Light2D

func _ready() -> void:
	var t := create_tween()
	t.tween_property(light, "texture_scale", Const.PING_RADIUS_MAX / 256.0, Const.PING_GROW_TIME)
	t.tween_interval(Const.PING_HOLD_TIME)
	t.tween_property(light, "energy", 0.0, Const.PING_FADE_TIME)
	t.tween_callback(queue_free)
