extends Area2D

@export var entity_id: String = ""

var _activated := false

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	# Pulse animation
	var tw := create_tween().set_loops()
	tw.tween_property(sprite, "modulate:a", 0.3, 1.2)
	tw.tween_property(sprite, "modulate:a", 1.0, 1.2)

func interact(_player: Node) -> void:
	if _activated:
		return
	_activated = true
	DialogueManager.start("father_climax", _on_climax_done)

func _on_climax_done() -> void:
	var choice_scene = load("res://scenes/ui/ChoiceUI.tscn")
	if choice_scene:
		var ui = choice_scene.instantiate()
		get_tree().root.add_child(ui)
