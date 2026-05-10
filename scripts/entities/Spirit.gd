extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

var _origin: Vector2
var _vel: Vector2 = Vector2.ZERO
var _change_timer: float = 0.0
var _active: bool = false
var _bob_offset: float = 0.0

func _ready() -> void:
	_origin = global_position
	_randomize_dir()
	_bob_offset = randf() * TAU
	RealityManager.reality_changed.connect(_on_reality_changed)
	_on_reality_changed(RealityManager.current)

func _process(delta: float) -> void:
	if not _active:
		return

	_change_timer -= delta
	if _change_timer <= 0.0:
		_randomize_dir()

	position += _vel * delta

	# Drift back toward spawn origin when too far
	var dist: float = position.distance_to(_origin)
	if dist > 80.0:
		position = position.move_toward(_origin, (dist - 80.0) * delta * 3.0)

	# Vertical bobbing
	sprite.position.y = sin(Time.get_ticks_msec() * 0.002 + _bob_offset) * 5.0

	# Alpha flicker — ethereal pulse
	sprite.modulate.a = 0.5 + sin(Time.get_ticks_msec() * 0.0015 + _bob_offset * 1.7) * 0.22

func _randomize_dir() -> void:
	var angle := randf() * TAU
	_vel = Vector2(cos(angle), sin(angle)) * randf_range(12.0, 32.0)
	_change_timer = randf_range(1.5, 4.0)

func _on_reality_changed(_r: Variant) -> void:
	_active = RealityManager.is_echo()
	visible = _active
