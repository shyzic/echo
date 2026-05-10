extends Node

func goto_title() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/ui/TitleScreen.tscn")

func goto_world() -> void:
	GameState.reset()
	SaveManager.has_checkpoint = false
	get_tree().change_scene_to_file.call_deferred("res://scenes/world/World.tscn")

func goto_ending(which: String) -> void:
	var packed = load("res://scenes/ui/EndingScreen.tscn")
	if not packed:
		return
	var inst = packed.instantiate()
	inst.ending_id = which
	get_tree().root.call_deferred("add_child", inst)
	if get_tree().current_scene:
		get_tree().current_scene.queue_free()
	get_tree().current_scene = inst
