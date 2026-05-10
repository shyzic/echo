extends CanvasLayer

@onready var video: VideoStreamPlayer = $VideoStreamPlayer

func _ready() -> void:
	AudioManager.ambient_player.stop()
	AudioManager.stop_bgm()
	if video.stream:
		video.finished.connect(_on_video_finished)
		video.play()
	else:
		# If no video is assigned, skip straight to the game
		_on_video_finished()

func _input(event: InputEvent) -> void:
	# Skip video on space/E/esc
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("pause"):
		_on_video_finished()

func _on_video_finished() -> void:
	get_tree().change_scene_to_file("res://scenes/world/World.tscn")
