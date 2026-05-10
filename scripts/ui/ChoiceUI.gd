extends CanvasLayer

@onready var btn_free: Button = $Panel/VBox/BtnFree
@onready var btn_stay: Button = $Panel/VBox/BtnStay

func _ready() -> void:
	btn_free.pressed.connect(_on_free)
	btn_stay.pressed.connect(_on_stay)
	# Freeze game while choosing
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_free() -> void:
	get_tree().paused = false
	GameState.hidden_endings_qualifying = GameState.letters_collected.size() >= 6
	SceneRouter.goto_ending("free")
	queue_free()

func _on_stay() -> void:
	get_tree().paused = false
	GameState.hidden_endings_qualifying = GameState.letters_collected.size() >= 6
	SceneRouter.goto_ending("stay")
	queue_free()
