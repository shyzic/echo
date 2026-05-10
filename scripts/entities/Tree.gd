extends StaticBody2D

@export var entity_id: String = ""
@export var reality_filter: String = "both"
@export var echo_texture: Texture2D
@export var echo_frame: int = -1

# Echo tint: charred, ashen look
const ECHO_TINT := Color(0.30, 0.18, 0.14, 1.0)

@onready var sprite: Sprite2D = $Sprite2D
var _light_texture: Texture2D
var _light_frame: int = 0

func _ready() -> void:
	if sprite:
		_light_texture = sprite.texture
		_light_frame = sprite.frame
	RealityManager.reality_changed.connect(_on_reality_changed)
	_on_reality_changed(RealityManager.current)

func _process(_delta: float) -> void:
	if reality_filter == "both":
		return
	var in_echo := RealityManager.is_echo()
	var should_show := (reality_filter == "echo" and in_echo) or (reality_filter == "light" and not in_echo)
	visible = should_show
	
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = not should_show

func _on_reality_changed(_r: Variant) -> void:
	if not is_instance_valid(sprite):
		return
	if RealityManager.is_echo():
		if echo_texture:
			sprite.texture = echo_texture
		if echo_frame >= 0:
			sprite.frame = echo_frame
			
		if not echo_texture and echo_frame < 0:
			var tw := create_tween()
			tw.tween_property(sprite, "modulate", ECHO_TINT, 0.4)
	else:
		if echo_texture and _light_texture:
			sprite.texture = _light_texture
		if echo_frame >= 0:
			sprite.frame = _light_frame
			
		var tw := create_tween()
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.4)
