extends StaticBody2D

@export var entity_id: String = ""
@export var reality_filter: String = "both"

func _process(_delta: float) -> void:
	if reality_filter == "both":
		return
	var in_echo := RealityManager.is_echo()
	var should_show := (reality_filter == "echo" and in_echo) or (reality_filter == "light" and not in_echo)
	visible = should_show
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = not should_show
