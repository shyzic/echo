extends Area2D

@export var entity_id: String = ""
@export var reality_filter: String = "both"

var _picked_up := false

func _process(_delta: float) -> void:
	if reality_filter == "both":
		return
	var in_echo := RealityManager.is_echo()
	visible = (reality_filter == "echo" and in_echo) or (reality_filter == "light" and not in_echo)

func get_hint() -> String: return "Подобрать ключ"

func interact(player: Node) -> void:
	if _picked_up:
		return
	_picked_up = true
	AudioManager.play("pickup")
	DialogueManager.play_dialogue("key_pickup")
	if player.has_method("set"):
		player.set("has_key", true)
	queue_free()
