extends Node

func goto_title() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/ui/TitleScreen.tscn")

func goto_world() -> void:
	GameState.reset()
	SaveManager.has_checkpoint = false
	get_tree().change_scene_to_file.call_deferred("res://scenes/world/World.tscn")

# Store ending id in GameState, then do a normal scene swap.
# This avoids the manual current_scene manipulation that causes the restart freeze.
func goto_ending(which: String) -> void:
	GameState.pending_ending = which
	get_tree().change_scene_to_file.call_deferred("res://scenes/ui/EndingScreen.tscn")
