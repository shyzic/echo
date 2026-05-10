extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var label: RichTextLabel = $Panel/RichTextLabel
@onready var arrow: Label = $Panel/ContinueArrow

var _full_text: String = ""
var _visible_chars: int = 0
var _typing: bool = false
var _accum: float = 0.0
const CHARS_PER_SEC := 30.0
const INSTANT_THRESHOLD := 200

func _ready() -> void:
	visible = false
	DialogueManager.dialogue_started.connect(_on_started)
	DialogueManager.line_advanced.connect(_on_advanced)
	DialogueManager.dialogue_finished.connect(_on_finished)

func _on_started() -> void:
	visible = true
	_show_line(DialogueManager.current_index)

func _on_advanced(idx: int) -> void:
	_show_line(idx)

func _on_finished() -> void:
	visible = false

func _show_line(idx: int) -> void:
	if idx >= DialogueManager.current_lines.size():
		return
	_full_text = str(DialogueManager.current_lines[idx])
	_visible_chars = 0
	_accum = 0.0
	label.text = ""
	arrow.visible = false
	if _full_text.length() >= INSTANT_THRESHOLD:
		_finish_typing()
	else:
		_typing = true

func _finish_typing() -> void:
	_typing = false
	_visible_chars = _full_text.length()
	label.text = _full_text
	label.scroll_to_line(label.get_line_count())
	arrow.visible = true

func _process(delta: float) -> void:
	if not _typing:
		return
	_accum += delta
	var chars := int(_accum * CHARS_PER_SEC)
	if chars > _visible_chars:
		_visible_chars = mini(chars, _full_text.length())
		label.text = _full_text.substr(0, _visible_chars)
		label.scroll_to_line(label.get_line_count())
	if _visible_chars >= _full_text.length():
		_finish_typing()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("skip_dialogue") or event.is_action_pressed("interact"):
		if _typing:
			_finish_typing()
		else:
			DialogueManager.advance()
		get_viewport().set_input_as_handled()
