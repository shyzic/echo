extends Area2D

@export var entity_id: String = ""
@export var reality_filter: String = "both"

@onready var sprite: Sprite2D = $Sprite2D

var _pulse_tween: Tween

func _ready() -> void:
	_start_pulse()

func _start_pulse() -> void:
	if not is_instance_valid(sprite):
		return
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(sprite, "modulate:a", 0.4, 0.9)
	_pulse_tween.tween_property(sprite, "modulate:a", 1.0, 0.9)

func _process(_delta: float) -> void:
	if reality_filter == "both":
		return
	var in_echo := RealityManager.is_echo()
	visible = (reality_filter == "echo" and in_echo) or (reality_filter == "light" and not in_echo)

func get_hint() -> String: return "Сохранить прогресс"

func interact(player: Node) -> void:
	SaveManager.save_checkpoint(player.global_position, RealityManager.current)
	AudioManager.play("anchor")
	GameState.anchors_visited.append(entity_id)
	DialogueManager.start("anchor_activated")
