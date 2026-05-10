extends Area2D

@export var entity_id: String = ""
@export var reality_filter: String = "both"

var _collected := false

func _process(_delta: float) -> void:
	if reality_filter == "both":
		return
	var in_echo := RealityManager.is_echo()
	visible = (reality_filter == "echo" and in_echo) or (reality_filter == "light" and not in_echo)

func interact(_player: Node) -> void:
	if _collected:
		return
	if GameState.is_letter_collected(entity_id):
		return
	DialogueManager.play_letter(entity_id, _on_read)

func _on_read() -> void:
	_collected = true
	GameState.collect_letter(entity_id)
	queue_free()
