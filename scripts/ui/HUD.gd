extends CanvasLayer

@onready var reality_label: Label = $RealityIndicator
@onready var letter_label: Label = $LetterCounter
@onready var hint_label: Label = $InteractHint

func _ready() -> void:
	add_to_group("hud")
	RealityManager.reality_changed.connect(_on_reality_changed)
	GameState.letters_changed.connect(_on_letters_changed)
	hint_label.visible = false
	_update_reality()
	_update_letters(GameState.letters_collected.size(), GameState.TOTAL_LETTERS)

func _on_reality_changed(_new: Variant) -> void:
	_update_reality()

func _update_reality() -> void:
	if RealityManager.is_echo():
		reality_label.text = "◉ ЭХО"
		reality_label.modulate = Color(0.5, 0.7, 1.0)
	else:
		reality_label.text = "○ МИР"
		reality_label.modulate = Color(1, 1, 1)

func _on_letters_changed(count: int, total: int) -> void:
	_update_letters(count, total)

func _update_letters(count: int, total: int) -> void:
	letter_label.text = "✉ %d/%d" % [count, total]

func show_hint(text: String) -> void:
	hint_label.text = text
	hint_label.visible = true

func hide_hint() -> void:
	hint_label.visible = false
