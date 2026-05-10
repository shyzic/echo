extends Area2D

@export var entity_id: String = ""
@export var reality_filter: String = "echo"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(_delta: float) -> void:
	var in_echo := RealityManager.is_echo()
	visible = in_echo
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = not in_echo

func _on_body_entered(body: Node) -> void:
	if body.has_method("die"):
		body.die()
