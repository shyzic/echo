extends Area2D

@export var entity_id: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(_delta: float) -> void:
	# Chasm is dangerous in Light reality — bridge covers it in Echo
	var in_echo := RealityManager.is_echo()
	visible = not in_echo
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = in_echo

func _on_body_entered(body: Node) -> void:
	if body.has_method("die"):
		body.die()
