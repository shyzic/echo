extends CharacterBody2D
class_name Player

@export var speed: float = Const.PLAYER_SPEED

#@onready var sprite: Sprite2D = $Sprite2D
#@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ping_cooldown_timer: Timer = $PingCooldown
@onready var interact_area: Area2D = $InteractArea

enum Facing { DOWN, UP, LEFT, RIGHT }
var facing: Facing = Facing.DOWN
var dead: bool = false
var input_locked: bool = false
var has_key: bool = false

func _ready() -> void:
	add_to_group("player")

func _physics_process(_delta: float) -> void:
	if dead or input_locked or DialogueManager.active:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input := Vector2.ZERO
	if Input.is_action_pressed("move_right"): input.x += 1
	if Input.is_action_pressed("move_left"):  input.x -= 1
	if Input.is_action_pressed("move_down"):  input.y += 1
	if Input.is_action_pressed("move_up"):    input.y -= 1

	if input.length() > 0:
		input = input.normalized()
		_update_facing(input)
		_play_walk()
	else:
		_play_idle()

	velocity = input * speed
	move_and_slide()

func _input(event: InputEvent) -> void:
	if dead:
		return
	if event.is_action_pressed("shift_reality") and RealityManager.can_toggle():
		RealityManager.toggle()
		AudioManager.play("shift")
	if event.is_action_pressed("ping") and RealityManager.is_echo() and ping_cooldown_timer.is_stopped():
		_do_ping()
	if event.is_action_pressed("interact") and not DialogueManager.active:
		_try_interact()
	if event.is_action_pressed("pause"):
		get_tree().paused = true

func _do_ping() -> void:
	AudioManager.play("ping")
	var ripple_scene = load("res://scenes/effects/PingRipple.tscn")
	if ripple_scene:
		var ripple = ripple_scene.instantiate()
		ripple.global_position = global_position
		get_parent().add_child(ripple)
	ping_cooldown_timer.start(Const.PING_COOLDOWN)

func _try_interact() -> void:
	var areas = interact_area.get_overlapping_areas()
	for area in areas:
		if area.has_method("interact"):
			area.interact(self)
			return

func _update_facing(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		facing = Facing.RIGHT if dir.x > 0 else Facing.LEFT
	else:
		facing = Facing.DOWN if dir.y > 0 else Facing.UP

#func _play_walk() -> void:
	#var anim_name = "walk_" + Facing.keys()[facing].to_lower()
	#if anim and anim.has_animation(anim_name) and anim.current_animation != anim_name:
		#anim.play(anim_name)
func _play_walk() -> void:
	var anim_name = "walk_" + Facing.keys()[facing].to_lower()

	if sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)

#func _play_idle() -> void:
	#var anim_name = "idle_" + Facing.keys()[facing].to_lower()
	#if anim and anim.has_animation(anim_name) and anim.current_animation != anim_name:
		#anim.play(anim_name)
func _play_idle() -> void:
	var anim_name = "idle_" + Facing.keys()[facing].to_lower()

	if sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)


func die() -> void:
	if dead:
		return
	dead = true
	AudioManager.play("death")
	GameState.player_died.emit()
	var overlay_scene = load("res://scenes/effects/DeathOverlay.tscn")
	if not overlay_scene:
		dead = false
		return
	var overlay = overlay_scene.instantiate()
	get_tree().root.add_child(overlay)
	await overlay.fade_out_done
	if SaveManager.has_checkpoint:
		var data = SaveManager.restore()
		global_position = data.pos
		RealityManager.current = data.reality
		GameState.letters_collected = data.letters.duplicate()
		GameState.puzzle_states = data.puzzles.duplicate()
	overlay.play_fade_in()
	await overlay.fade_in_done
	overlay.queue_free()
	dead = false
