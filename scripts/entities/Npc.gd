extends Area2D

@export var dialogue_key: String = "mother_intro"
@export var entity_id: String = ""

func get_hint() -> String:
	return "Поговорить с мамой"

func interact(_player: Node) -> void:
	GameState.hut_visited = true
	DialogueManager.start(dialogue_key)
