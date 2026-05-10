extends Area2D

@export var entity_id: String = ""
@export var reality_filter: String = "echo"
@export var order: int = 1

signal activated(switch_node: Node)

var _triggered := false

func _process(_delta: float) -> void:
	var in_echo := RealityManager.is_echo()
	visible = in_echo
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = not in_echo

func get_hint() -> String:
	if _triggered: return "Рычаг активирован"
	return "Активировать переключатель"

func interact(_player: Node) -> void:
	if _triggered:
		return
	_triggered = true
	AudioManager.play("switch")
	activated.emit(self)

func reset() -> void:
	_triggered = false
