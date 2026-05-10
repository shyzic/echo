extends Area2D

@export var entity_id: String = "home_chest"

var _opened: bool = false

@onready var sprite: Sprite2D = $Sprite2D

func get_hint() -> String:
	if _opened:
		return "Сундук (пуст)"
	return "Открыть сундук [E]"

func interact(_player: Node) -> void:
	if _opened:
		return
	_opened = true
	GameState.chest_opened = true
	AudioManager.play("pickup")
	# Dim the sprite to show it's been used
	if is_instance_valid(sprite):
		var tw := create_tween()
		tw.tween_property(sprite, "modulate", Color(0.55, 0.45, 0.28, 0.55), 0.4)
	DialogueManager.start("chest_intro")
