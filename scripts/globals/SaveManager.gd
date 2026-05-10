extends Node

var checkpoint_data: Dictionary = {}
var has_checkpoint: bool = false

func save_checkpoint(player_pos: Vector2, reality: int) -> void:
	checkpoint_data = {
		"pos": player_pos,
		"reality": reality,
		"letters": GameState.letters_collected.duplicate(),
		"puzzles": GameState.puzzle_states.duplicate(),
		"anchors": GameState.anchors_visited.duplicate(),
	}
	has_checkpoint = true

func restore() -> Dictionary:
	return checkpoint_data
