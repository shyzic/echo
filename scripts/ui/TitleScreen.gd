extends CanvasLayer

@onready var btn_start: Button = $VBox/BtnStart
@onready var btn_quit: Button = $VBox/BtnQuit

func _ready() -> void:
	AudioManager.play_bgm("menu")
	btn_start.pressed.connect(_on_start)
	btn_quit.pressed.connect(_on_quit)

func _on_start() -> void:
	GameState.reset()
	SaveManager.has_checkpoint = false
	get_tree().change_scene_to_file("res://scenes/ui/IntroCutscene.tscn")

func _on_quit() -> void:
	get_tree().quit()
