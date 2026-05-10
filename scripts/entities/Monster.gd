extends CharacterBody2D

@export var speed: float = 40.0
@export var chase_radius: float = 120.0
@export var entity_id: String = ""

@onready var detection: Area2D = $DetectionArea
@onready var hurt_area: Area2D = $HurtArea

var _player: Node = null
var _active := false

func _ready() -> void:
	hurt_area.body_entered.connect(_on_hurt)
	_find_player()

func _find_player() -> void:
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]

func _physics_process(_delta: float) -> void:
	var in_echo := RealityManager.is_echo()
	visible = in_echo
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = not in_echo

	if not in_echo or not is_instance_valid(_player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dist := global_position.distance_to(_player.global_position)
	if dist < chase_radius:
		var dir: Vector2 = (_player.global_position - global_position).normalized()
		velocity = dir * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

func _on_hurt(body: Node) -> void:
	if body.has_method("die"):
		body.die()
