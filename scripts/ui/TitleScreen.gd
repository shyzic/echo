extends CanvasLayer

@onready var btn_start: Button = $VBox/BtnStart
@onready var btn_quit: Button = $VBox/BtnQuit

func _ready() -> void:
	btn_start.pressed.connect(_on_start)
	btn_quit.pressed.connect(_on_quit)

func _on_start() -> void:
	SceneRouter.goto_world()

func _on_quit() -> void:
	get_tree().quit()
