extends Node2D

@export var entity_id: String = ""
@export var reality_filter: String = "echo"

func _process(_delta: float) -> void:
	visible = RealityManager.is_echo()
