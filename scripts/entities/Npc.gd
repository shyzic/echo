extends Area2D

@export var dialogue_key: String = "mother_intro"
@export var entity_id: String = ""

var _talked := false

func interact(_player: Node) -> void:
	DialogueManager.start(dialogue_key)
	_talked = true
