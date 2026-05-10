extends StaticBody2D

@export var entity_id: String = ""
@export var reality_filter: String = "both"
@export var requires_key: bool = true
@export var switch_locked: bool = false   # true for EchoSwitchesGate doors

var _open := false
var _switch_activated := 0
var _switch_total := 2

func update_switch_progress(activated: int, total: int) -> void:
	_switch_activated = activated
	_switch_total = total

func _process(_delta: float) -> void:
	if reality_filter == "both":
		return
	var in_echo := RealityManager.is_echo()
	var should_show := (reality_filter == "echo" and in_echo) or (reality_filter == "light" and not in_echo)
	visible = should_show
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

func get_hint() -> String:
	if switch_locked:
		return "Дверь заперта (%d/%d рычагов в Эхо)" % [_switch_activated, _switch_total]
	if requires_key:
		return "Открыть дверь (нужен ключ)"
	return "Открыть дверь"

func interact(player: Node) -> void:
	if _open:
		return
	if switch_locked:
		DialogueManager.play_dialogue("door_locked")
		return
	if requires_key and not player.get("has_key"):
		DialogueManager.play_dialogue("door_locked")
		return
	open()
