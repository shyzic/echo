extends Node

enum Reality { LIGHT, ECHO }

signal reality_changed(new_reality: Reality)
signal reality_transition_started
signal reality_transition_finished

var current: Reality = Reality.LIGHT
var transitioning: bool = false
var cooldown_remaining: float = 0.0

const COOLDOWN: float = 0.6
const FADE_TIME: float = 0.4

func _process(delta: float) -> void:
	if cooldown_remaining > 0.0:
		cooldown_remaining -= delta

func is_echo() -> bool:
	return current == Reality.ECHO

func can_toggle() -> bool:
	return cooldown_remaining <= 0.0 and not transitioning

func toggle() -> void:
	if not can_toggle():
		return
	transitioning = true
	cooldown_remaining = COOLDOWN
	reality_transition_started.emit()
	var t := get_tree().create_timer(FADE_TIME / 2.0)
	t.timeout.connect(_swap)
	var t2 := get_tree().create_timer(FADE_TIME)
	t2.timeout.connect(func(): transitioning = false; reality_transition_finished.emit())

func _swap() -> void:
	current = Reality.ECHO if current == Reality.LIGHT else Reality.LIGHT
	reality_changed.emit(current)
