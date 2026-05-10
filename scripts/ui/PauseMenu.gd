extends CanvasLayer

@onready var btn_resume: Button = $VBox/BtnResume
@onready var btn_title: Button  = $VBox/BtnTitle
@onready var btn_quit: Button   = $VBox/BtnQuit

func _ready() -> void:
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	btn_resume.pressed.connect(_on_resume)
	btn_title.pressed.connect(_on_title)
	btn_quit.pressed.connect(_on_quit)
	btn_resume.grab_focus()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_resume()
		get_viewport().set_input_as_handled()

func _on_resume() -> void:
	get_tree().paused = false
	queue_free()

func _on_title() -> void:
	get_tree().paused = false
	SceneRouter.goto_title()
	queue_free()

func _on_quit() -> void:
	get_tree().quit()
