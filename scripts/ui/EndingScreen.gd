extends CanvasLayer

@export var ending_id: String = "free"

# UI refs
@onready var bg:            ColorRect = $Bg
@onready var narration:     Label     = $UI/NarrationLabel
@onready var btn_title:     Button    = $UI/BtnTitle

# Cutscene sprite refs
@onready var spr_father: Sprite2D = $CutsceneLayer/SpriteFather
@onready var spr_player: Sprite2D = $CutsceneLayer/SpritePlayer
@onready var spr_mother: Sprite2D = $CutsceneLayer/SpriteMother

const TYPEWRITER_SPEED := 0.038   # seconds per character

func _ready() -> void:
	# Read ending id from GameState (set by SceneRouter.goto_ending)
	ending_id = GameState.pending_ending
	btn_title.visible = false
	btn_title.pressed.connect(func(): SceneRouter.goto_title())
	narration.text = ""
	spr_father.visible = false
	spr_player.visible = false
	spr_mother.visible = false
	_play_cutscene.call_deferred()

func _play_cutscene() -> void:
	var key := ending_id
	if GameState.hidden_endings_qualifying and ending_id == "free":
		key = "free_all_letters"

	match key:
		"stay":
			await _cutscene_stay()
		"free_all_letters":
			await _cutscene_free_all()
		_:
			await _cutscene_free()

	btn_title.visible = true

# ---------------------------------------------------------------------------
# ENDING A — освободить отца: он возвращается к маме
# ---------------------------------------------------------------------------
func _cutscene_free() -> void:
	bg.color = Color(0.04, 0.04, 0.08)

	# Father starts off-screen right, player is at centre-right
	spr_father.position = Vector2(1500, 400)
	spr_father.modulate = Color(0.85, 0.78, 0.65, 1.0)
	spr_father.visible  = true

	spr_player.position = Vector2(900, 440)
	spr_player.modulate = Color(1.0, 1.0, 1.0, 1.0)
	spr_player.visible  = true

	spr_mother.position = Vector2(160, 420)
	spr_mother.modulate = Color(0.9, 0.8, 0.6, 0.0)   # starts invisible
	spr_mother.visible  = true

	await _say("Сердце леса дрогнуло.")
	await _say("Ты прикоснулся к эху — и оно отпустило отца.")

	# Father walks from right toward player
	var tw := create_tween()
	tw.tween_property(spr_father, "position:x", 700.0, 2.8)
	await tw.finished

	await _say("Отец стоит перед тобой. Молчит. Постаревший. Живой.")
	await _say("Вы смотрите друг на друга. Слов не нужно.")

	# Mother fades in on the left
	var tw2 := create_tween()
	tw2.tween_property(spr_mother, "modulate:a", 1.0, 1.2)
	await tw2.finished

	await _say("Мама появляется на опушке.")

	# Father walks toward mother
	var tw3 := create_tween()
	tw3.tween_property(spr_father, "position:x", 220.0, 2.5)
	await tw3.finished

	await _say("Она плачет. Он обнимает её молча.")

	# Bright fade: happy ending
	var tw4 := create_tween()
	tw4.tween_property(bg, "color", Color(0.98, 0.94, 0.82), 2.5)
	await tw4.finished

	await _say("Лес замолк. Эхо ушло. Они вернулись домой.")
	await _say("Иногда ночью ты слышишь далёкий шёпот —\nлес всё ещё тебя помнит.")

# ---------------------------------------------------------------------------
# ENDING B — остаться: игрок уходит в Эхо, отец ведёт его
# ---------------------------------------------------------------------------
func _cutscene_stay() -> void:
	bg.color = Color(0.02, 0.02, 0.06)

	spr_player.position = Vector2(700, 440)
	spr_player.modulate = Color(1.0, 1.0, 1.0, 1.0)
	spr_player.visible  = true

	spr_father.position = Vector2(1000, 440)
	spr_father.modulate = Color(0.55, 0.65, 1.0, 0.9)  # echo-tinted
	spr_father.visible  = true

	await _say("Ты смотришь на отца.")
	await _say("Он кивает. Медальон теплеет у тебя на груди.")

	# Background deepens to Echo blue
	var tw := create_tween()
	tw.tween_property(bg, "color", Color(0.04, 0.06, 0.22), 2.5)
	await tw.finished

	await _say("«Идём. Я покажу тебе Эхо таким, каким знаю его я.»")

	# Father moves to player's side
	var tw2 := create_tween()
	tw2.tween_property(spr_father, "position:x", 550.0, 1.8)
	await tw2.finished

	await _say("Он берёт тебя за руку. Лес расступается.")

	# Both walk off-screen to the left, fading into darkness
	var tw3 := create_tween()
	tw3.parallel().tween_property(spr_player, "position:x", -200.0, 3.5)
	tw3.parallel().tween_property(spr_father, "position:x", -400.0, 3.5)
	tw3.parallel().tween_property(spr_player, "modulate:a",  0.0, 3.5)
	tw3.parallel().tween_property(spr_father, "modulate:a",  0.0, 3.5)
	await tw3.finished

	await _say("Ты стал хранителем. Голосом Эха.")
	await _say("Между двумя мирами — теперь твой дом.")

# ---------------------------------------------------------------------------
# ENDING C (скрытый) — все письма + свобода
# ---------------------------------------------------------------------------
func _cutscene_free_all() -> void:
	bg.color = Color(0.04, 0.04, 0.08)

	spr_father.position = Vector2(1400, 400)
	spr_father.modulate = Color(0.85, 0.78, 0.65, 1.0)
	spr_father.visible  = true

	spr_player.position = Vector2(800, 440)
	spr_player.modulate = Color(1.0, 1.0, 1.0, 1.0)
	spr_player.visible  = true

	spr_mother.position = Vector2(150, 420)
	spr_mother.modulate = Color(0.9, 0.8, 0.6, 0.0)
	spr_mother.visible  = true

	await _say("Ты прочитал все письма. Ты знал его путь наизусть.")
	await _say("Каждый шаг. Каждое сомнение. Каждую любовь.")

	var tw := create_tween()
	tw.tween_property(spr_father, "position:x", 650.0, 2.5)
	await tw.finished

	await _say("Когда вы встретились — слов не понадобилось.")
	await _say("Отец увидел в твоих глазах: ты понял всё.")

	var tw2 := create_tween()
	tw2.tween_property(spr_mother, "modulate:a", 1.0, 1.0)
	await tw2.finished

	var tw3 := create_tween()
	tw3.parallel().tween_property(spr_father, "position:x", 230.0, 2.2)
	tw3.parallel().tween_property(bg, "color", Color(0.95, 0.92, 0.80), 3.0)
	await tw3.finished

	await _say("Лес отпустил вас обоих.")
	await _say("Эхо затихло — не умерло, а превратилось в воспоминание.")
	await _say("Вы вернулись домой вместе.")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func _say(text: String) -> void:
	narration.text = ""
	for ch in text:
		narration.text += ch
		await get_tree().create_timer(TYPEWRITER_SPEED).timeout
	await get_tree().create_timer(1.8).timeout
