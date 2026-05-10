extends Node2D

@export var entity_id: String = ""

@onready var roof: Sprite2D    = $Roof
@onready var interior: Node2D  = $Interior
@onready var trigger: Area2D   = $InteriorTrigger

func _ready() -> void:
	interior.visible = false
	trigger.body_entered.connect(_on_body_entered)
	trigger.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_enter_house(body)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_exit_house(body)

func _enter_house(player: Node2D) -> void:
	interior.visible = true
	# Raise player above the floor (Interior z=0, player raised to z=2).
	# The roof (z=3) still covers everything; it fades below.
	player.z_index = 2
	var tw := create_tween()
	tw.tween_property(roof, "modulate:a", 0.0, 0.35)

func _exit_house(player: Node2D) -> void:
	# Restore normal z so Y-sort works correctly in the open world
	player.z_index = 0
	var tw := create_tween()
	tw.tween_property(roof, "modulate:a", 1.0, 0.35)
	await tw.finished
	interior.visible = false
