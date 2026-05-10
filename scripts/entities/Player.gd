extends CharacterBody2D
class_name Player

@export var speed: float = Const.PLAYER_SPEED

@onready var sprite: AnimatedSprite2D   = $AnimatedSprite2D
@onready var ping_cooldown_timer: Timer  = $PingCooldown
@onready var interact_area: Area2D       = $InteractArea
@onready var point_light: PointLight2D  = $PointLight2D

enum Facing { DOWN, UP, LEFT, RIGHT }
var facing: Facing = Facing.DOWN
var dead: bool        = false
var input_locked: bool = false
var has_key: bool     = false

var _footstep_timer: float = 0.0
const FOOTSTEP_INTERVAL: float = 0.4

func _ready() -> void:
	add_to_group("player")
	interact_area.area_entered.connect(_on_interact_area_entered)
	interact_area.area_exited.connect(_on_interact_area_exited)
	RealityManager.reality_changed.connect(_on_reality_changed)
	_on_reality_changed(RealityManager.current)

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
		
		_footstep_timer -= _delta
		if _footstep_timer <= 0.0:
			AudioManager.play("footstep")
			_footstep_timer = FOOTSTEP_INTERVAL
	else:
		_play_idle()
		_footstep_timer = 0.0

	velocity = input * speed
	move_and_slide()

func _input(event: InputEvent) -> void:
	if dead:
		return

	if event.is_action_pressed("shift_reality") and RealityManager.can_toggle():
		if not GameState.chest_opened:
			_show_hud_hint("Нужен медальон чтобы переключать миры")
			return
		RealityManager.toggle()
		AudioManager.play("shift")

	if event.is_action_pressed("ping") and RealityManager.is_echo() and ping_cooldown_timer.is_stopped():
		_do_ping()

	if event.is_action_pressed("interact") and not DialogueManager.active:
		_try_interact()

	if event.is_action_pressed("pause"):
		var pause_scene = load("res://scenes/ui/PauseMenu.tscn")
		if pause_scene:
			get_tree().root.add_child(pause_scene.instantiate())

# ---------------------------------------------------------------------------
func _do_ping() -> void:
	AudioManager.play("ping")
	var ripple_scene = load("res://scenes/effects/PingRipple.tscn")
	if ripple_scene:
		var ripple = ripple_scene.instantiate()
		ripple.global_position = global_position
		get_parent().add_child(ripple)
	ping_cooldown_timer.start(Const.PING_COOLDOWN)

func _try_interact() -> void:
	var areas := interact_area.get_overlapping_areas()
	for area in areas:
		if area.has_method("interact"):
			area.interact(self)
			_refresh_hint_deferred()
			return

# ---------------------------------------------------------------------------
func _on_interact_area_entered(area: Area2D) -> void:
	if area.has_method("interact"):
		_refresh_hint()

func _on_interact_area_exited(_area: Area2D) -> void:
	_refresh_hint_deferred()

func _refresh_hint() -> void:
	var areas := interact_area.get_overlapping_areas()
	for area in areas:
		if area.has_method("interact") and is_instance_valid(area):
			var hint: String = "[E]  "
			if area.has_method("get_hint"):
				hint += area.get_hint()
			else:
				hint += "Взаимодействовать"
			_show_hud_hint(hint)
			return
	_hide_hud_hint()

func _refresh_hint_deferred() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_refresh_hint()

func _show_hud_hint(text: String) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_hint"):
		hud.show_hint(text)

func _hide_hud_hint() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("hide_hint"):
		hud.hide_hint()

# ---------------------------------------------------------------------------
func _update_facing(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		facing = Facing.RIGHT if dir.x > 0 else Facing.LEFT
	else:
		facing = Facing.DOWN if dir.y > 0 else Facing.UP

func _play_walk() -> void:
	if not sprite or not sprite.sprite_frames:
		return
	var anim_name: String = "walk_" + Facing.keys()[facing].to_lower()
	if sprite.sprite_frames.has_animation(anim_name) and sprite.animation != anim_name:
		sprite.play(anim_name)

func _play_idle() -> void:
	if not sprite or not sprite.sprite_frames:
		return
	var anim_name: String = "idle_" + Facing.keys()[facing].to_lower()
	if sprite.sprite_frames.has_animation(anim_name) and sprite.animation != anim_name:
		sprite.play(anim_name)

# ---------------------------------------------------------------------------
# PointLight2D reacts to reality — Echo = visible lantern
func _on_reality_changed(_r: Variant) -> void:
	if not is_instance_valid(point_light):
		return
	if RealityManager.is_echo():
		point_light.visible = true
		var tw := create_tween()
		tw.tween_property(point_light, "energy", 1.6, RealityManager.FADE_TIME)
	else:
		var tw := create_tween()
		tw.tween_property(point_light, "energy", 0.0, RealityManager.FADE_TIME)
		await tw.finished
		point_light.visible = false

# ---------------------------------------------------------------------------
func die() -> void:
	if dead:
		return
	dead = true
	_hide_hud_hint()
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
		GameState.puzzle_states    = data.puzzles.duplicate()
		has_key = false
	overlay.play_fade_in()
	await overlay.fade_in_done
	overlay.queue_free()
	dead = false
