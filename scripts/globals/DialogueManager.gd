extends Node

signal dialogue_started
signal dialogue_finished
signal line_advanced(line_index: int)

var dialogues: Dictionary = {}
var letters: Dictionary = {}
var active: bool = false
var current_lines: Array = []
var current_index: int = 0
var on_complete: Callable

func _ready() -> void:
	_load_data()

func _load_data() -> void:
	var f1 = FileAccess.open("res://data/dialogues.json", FileAccess.READ)
	if f1:
		dialogues = JSON.parse_string(f1.get_as_text())
	var f2 = FileAccess.open("res://data/letters.json", FileAccess.READ)
	if f2:
		letters = JSON.parse_string(f2.get_as_text())

func play_dialogue(key: String, complete_cb: Callable = Callable()) -> void:
	if key not in dialogues:
		push_warning("Dialogue not found: %s" % key)
		return
	var data = dialogues[key]
	current_lines = data if data is Array else [data]
	current_index = 0
	on_complete = complete_cb
	active = true
	AudioManager.play("dialogue")
	dialogue_started.emit()

func play_letter(key: String, complete_cb: Callable = Callable()) -> void:
	if key not in letters:
		return
	current_lines = [letters[key]]
	current_index = 0
	on_complete = complete_cb
	active = true
	AudioManager.play("dialogue")
	dialogue_started.emit()

func advance() -> void:
	current_index += 1
	if current_index >= current_lines.size():
		end()
	else:
		AudioManager.play("dialogue")
		line_advanced.emit(current_index)

func start(key: String, complete_cb: Callable = Callable()) -> void:
	play_dialogue(key, complete_cb)

func end() -> void:
	active = false
	dialogue_finished.emit()
	if on_complete.is_valid():
		on_complete.call()
