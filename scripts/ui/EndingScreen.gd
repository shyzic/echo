extends CanvasLayer

@export var ending_id: String = "free"

@onready var title_label: Label = $VBox/TitleLabel
@onready var body_label: RichTextLabel = $VBox/BodyLabel
@onready var btn_title: Button = $VBox/BtnTitle

const ENDINGS := {
	"free": {
		"title": "Конец: Освобождение",
		"body": "Ты нашёл отца в сердце леса.\nТвоё прикосновение разрушило оковы эха.\nОтец вернулся домой — молчаливый, постаревший, но живой.\n\nЛес замолк. Эхо ушло.\n\nНо иногда по ночам ты слышишь далёкий шёпот —\nкак будто лес всё ещё тебя помнит."
	},
	"stay": {
		"title": "Конец: Хранитель",
		"body": "Ты выслушал отца и понял его выбор.\nЛес нуждается в хранителе — и теперь им стал ты.\n\nОтец ушёл домой. Мать плакала от радости.\n\nА ты остался между двумя мирами —\nголос эха, память леса,\nхранитель границы, которую никто больше не пересечёт."
	},
	"free_all_letters": {
		"title": "Истинный конец: Память",
		"body": "Ты собрал все письма отца.\nТы знал его путь наизусть — каждый шаг, каждое сомнение.\n\nКогда вы встретились, слов не понадобилось.\nОтец увидел в твоих глазах, что ты понял всё.\n\nЛес отпустил вас обоих.\nЭхо затихло — не умерло, а превратилось в воспоминание.\n\nВы вернулись домой вместе."
	}
}

func _ready() -> void:
	var key := ending_id
	if GameState.hidden_endings_qualifying and ending_id == "free":
		key = "free_all_letters"
	var data: Dictionary = ENDINGS.get(key, ENDINGS["free"])
	title_label.text = data["title"]
	body_label.text = data["body"]
	btn_title.pressed.connect(_on_title)

func _on_title() -> void:
	SceneRouter.goto_title()
