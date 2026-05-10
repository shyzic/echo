extends CanvasLayer

@onready var overlay: ColorRect = $ColorRect

func _ready() -> void:
	overlay.color = Color(0, 0, 0, 0)
	RealityManager.reality_transition_started.connect(_on_started)

func _on_started() -> void:
	var t := create_tween()
	t.tween_property(overlay, "color:a", 1.0, RealityManager.FADE_TIME / 2.0)
	t.tween_property(overlay, "color:a", 0.0, RealityManager.FADE_TIME / 2.0)
