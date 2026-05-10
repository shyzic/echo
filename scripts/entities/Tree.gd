extends StaticBody2D

@export var entity_id: String = ""
@export var reality_filter: String = "both"

# Echo tint: charred, ashen look
const ECHO_TINT := Color(0.30, 0.18, 0.14, 1.0)

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	RealityManager.reality_changed.connect(_on_reality_changed)
	_on_reality_changed(RealityManager.current)

func _process(_delta: float) -> void:
	if reality_filter == "both":
		return
	var in_echo := RealityManager.is_echo()
	visible = (reality_filter == "echo" and in_echo) or (reality_filter == "light" and not in_echo)

func _on_reality_changed(_r: Variant) -> void:
	if not is_instance_valid(sprite):
		return
	if RealityManager.is_echo():
		# Burnt / dead tree look in Echo world
		var tw := create_tween()
		tw.tween_property(sprite, "modulate", ECHO_TINT, 0.4)
	else:
		var tw := create_tween()
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.4)
