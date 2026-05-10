extends Area2D

@export var entity_id: String = "diary"

var _read := false

func get_hint() -> String:
	return "Прочитать дневник отца"

func interact(_player: Node) -> void:
	if _read:
		DialogueManager.start("father_diary")
		return
	_read = true
	GameState.diary_read = true
	GameState.hut_visited = true
	DialogueManager.start("father_diary")
