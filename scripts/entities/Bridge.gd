extends Node2D

@export var entity_id: String = ""

func _process(_delta: float) -> void:
	# Bridge appears in Echo reality, covering the chasm
	visible = RealityManager.is_echo()
