extends Area2D

@export var dialogue_key: String = "mother_intro"
@export var entity_id: String = ""
@export var sleep_after: bool = false   # mother at HOME — sleeps after first talk

var _sleeping: bool = false
var _talked:   bool = false

func get_hint() -> String:
	if _sleeping:
		return ""
	return "Поговорить с мамой [E]"

func interact(_player: Node) -> void:
	if _sleeping or DialogueManager.active:
		return
	GameState.hut_visited = true
	if sleep_after and not _talked:
		_talked = true
		GameState.mother_talked = true
		DialogueManager.start(dialogue_key, _on_farewell_done)
	else:
		DialogueManager.start(dialogue_key)

# Called when the farewell dialogue ends — mother goes to sleep
func _on_farewell_done() -> void:
	_sleeping = true
	var spr: Sprite2D = get_node_or_null("Sprite2D")
	if is_instance_valid(spr):
		var tw := create_tween()
		tw.tween_property(spr, "modulate:a", 0.0, 1.6)
	# Small floating label hint
	var label: Label = get_node_or_null("SleepLabel")
	if is_instance_valid(label):
		label.visible = true
