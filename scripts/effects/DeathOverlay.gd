extends CanvasLayer

signal fade_out_done
signal fade_in_done

@onready var bg: ColorRect = $Background
@onready var msg: Label = $Message

func _ready() -> void:
	bg.color = Color(0, 0, 0, 0)
	msg.modulate.a = 0.0
	play_fade_to_black()

func play_fade_to_black() -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(bg, "color:a", 1.0, 0.7)
	t.tween_property(msg, "modulate:a", 1.0, 0.7)
	await t.finished
	fade_out_done.emit()

func play_fade_in() -> void:
	await get_tree().create_timer(0.5).timeout
	var t := create_tween().set_parallel(true)
	t.tween_property(bg, "color:a", 0.0, 0.7)
	t.tween_property(msg, "modulate:a", 0.0, 0.7)
	await t.finished
	fade_in_done.emit()
