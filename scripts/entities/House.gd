extends Node2D

@onready var roof: Sprite2D     = $Roof
@onready var interior: Node2D   = $Interior
@onready var trigger: Area2D    = $InteriorTrigger

func _ready() -> void:
	interior.visible = false
	trigger.body_entered.connect(_on_body_entered)
	trigger.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_enter_house()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_exit_house()

func _enter_house() -> void:
	interior.visible = true
	var tw := create_tween()
	tw.tween_property(roof, "modulate:a", 0.0, 0.35)

func _exit_house() -> void:
	var tw := create_tween()
	tw.tween_property(roof, "modulate:a", 1.0, 0.35)
	await tw.finished
	interior.visible = false
