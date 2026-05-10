extends Node

signal letters_changed(count: int, total: int)
signal puzzle_solved(puzzle_id: String)
signal player_died

var current_seed: int = 0
var letters_collected: Dictionary = {}
var puzzle_states: Dictionary = {}
var anchors_visited: Array[String] = []
var play_time_seconds: float = 0.0
var hidden_endings_qualifying: bool = false

# Narrative gates (mandatory story order)
var chest_opened:  bool = false   # grabbed medallion from home chest
var mother_talked: bool = false   # spoke with mother before leaving
var hut_visited:   bool = false   # reached father's hut
var diary_read:    bool = false   # read the diary → unlocks HeartShrine

# Used by SceneRouter.goto_ending so EndingScreen knows which cutscene to play
var pending_ending: String = "free"

const TOTAL_LETTERS: int = 6

func _process(delta: float) -> void:
	play_time_seconds += delta

func collect_letter(id: String) -> void:
	if id in letters_collected:
		return
	letters_collected[id] = true
	if letters_collected.size() >= TOTAL_LETTERS:
		hidden_endings_qualifying = true
	letters_changed.emit(letters_collected.size(), TOTAL_LETTERS)

func is_letter_collected(id: String) -> bool:
	return id in letters_collected

func reset() -> void:
	letters_collected.clear()
	puzzle_states.clear()
	anchors_visited.clear()
	play_time_seconds   = 0.0
	hidden_endings_qualifying = false
	chest_opened  = false
	mother_talked = false
	hut_visited   = false
	diary_read    = false
	pending_ending = "free"
