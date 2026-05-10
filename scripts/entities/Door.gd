extends StaticBody2D

@export var entity_id: String = ""
@export var reality_filter: String = "both"
@export var requires_key: bool = true

var _open := false

func _process(_delta: float) -> void:
	if reality_filter == "both":
		return
	var in_echo := RealityManager.is_echo()
	var should_show := (reality_filter == "echo" and in_echo) or (reality_filter == "light" and not in_echo)
	visible = should_show
	# Disable collision when hidden or open
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = not should_show or _open

func open() -> void:
	_open = true
	AudioManager.play("door")
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("open")
	else:
		visible = false
		for child in get_children():
			if child is CollisionShape2D:
				child.disabled = true

func interact(player: Node) -> void:
	if _open:
		return
	if requires_key and not player.get("has_key"):
		DialogueManager.play_dialogue("door_locked")
		return
	open()
