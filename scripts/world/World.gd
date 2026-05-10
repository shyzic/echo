extends Node2D

@onready var ground: TileMapLayer    = $GroundTilemap
@onready var entities: Node2D        = $EntitiesContainer
@onready var player: CharacterBody2D = $EntitiesContainer/Player
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

const SCENE_PATHS := {
	"Tree":        "res://scenes/entities/Tree.tscn",
	"Stone":       "res://scenes/entities/Stone.tscn",
	"Letter":      "res://scenes/entities/Letter.tscn",
	"Anchor":      "res://scenes/entities/Anchor.tscn",
	"Chasm":       "res://scenes/entities/Chasm.tscn",
	"Bridge":      "res://scenes/entities/Bridge.tscn",
	"Door":        "res://scenes/entities/Door.tscn",
	"Key":         "res://scenes/entities/Key.tscn",
	"Switch":      "res://scenes/entities/Switch.tscn",
	"Monster":     "res://scenes/entities/Monster.tscn",
	"Npc":         "res://scenes/entities/Npc.tscn",
	"HeartShrine": "res://scenes/entities/HeartShrine.tscn",
	"Diary":       "res://scenes/entities/Diary.tscn",
	"House":       "res://scenes/entities/House.tscn",
	"Chest":       "res://scenes/entities/Chest.tscn",
	"Spirit":      "res://scenes/entities/Spirit.tscn",
}

var _scenes: Dictionary = {}

func _ready() -> void:
	RealityManager.reality_changed.connect(_on_reality_changed)
	_preload_scenes()
	var gen := ProcGen.generate(GameState.current_seed)
	GameState.current_seed = gen.seed
	_apply_tiles(gen.grid)
	_reachable_tiles_cache = _calc_reachable_from_home(gen)
	_spawn_all(gen)
	_spawn_puzzles(gen)
	_spawn_border()
	player.position = _wp(gen.pois.HOME) + Vector2(64, 16)

var _reachable_tiles_cache: Array = []

func _calc_reachable_from_home(gen: Dictionary) -> Array:
	var visited := {}
	var queue: Array = [gen.pois.HOME]
	visited[gen.pois.HOME] = true
	var reachable := []
	
	# Treat all puzzle doors as blocked for the initial reachable area
	var blocked := {}
	for p in gen.puzzle_spawns:
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				blocked[p.pos + Vector2i(dx, dy)] = true

	while queue.size() > 0:
		var curr: Vector2i = queue.pop_front()
		reachable.append(curr)
		var dirs: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		for d in dirs:
			var nxt = curr + d
			if nxt.x < 0 or nxt.y < 0 or nxt.x >= gen.grid[0].size() or nxt.y >= gen.grid.size(): continue
			if nxt in visited: continue
			if nxt in blocked: continue
			if gen.grid[nxt.y][nxt.x] != Const.TILE_PATH: continue
			visited[nxt] = true
			queue.append(nxt)
	return reachable

func _get_random_reachable_tile(center: Vector2i, min_dist: float, max_dist: float) -> Vector2i:
	var valid := []
	for pos in _reachable_tiles_cache:
		var d = center.distance_to(pos)
		if d >= min_dist and d <= max_dist:
			valid.append(pos)
	if valid.size() > 0:
		valid.shuffle()
		return valid[0]
	return center + Vector2i(0, 1) # fallback

func _preload_scenes() -> void:
	for key in SCENE_PATHS:
		if ResourceLoader.exists(SCENE_PATHS[key]):
			_scenes[key] = load(SCENE_PATHS[key])

func _apply_tiles(grid: Array) -> void:
	for y in grid.size():
		for x in grid[y].size():
			ground.set_cell(Vector2i(x, y), 0, Vector2i(grid[y][x], 0))

# ---------------------------------------------------------------------------
func _spawn_all(gen: Dictionary) -> void:
	for spawn in gen.entity_spawns:
		_spawn(spawn.type, spawn.pos)

	var letter_spawns: Array = gen.letter_spawns
	for i in letter_spawns.size():
		var valid_pos = _get_random_reachable_tile(letter_spawns[i], 0.0, 100.0)
		var node = _spawn("Letter", valid_pos)
		if node:
			node.entity_id = "letter_%d" % (i + 1)

	for pos in gen.anchor_spawns:
		_spawn("Anchor", pos)

	# HOME: house + chest inside + mother outside
	var house := _spawn("House", gen.pois.HOME)
	if house:
		house.entity_id = "player_house"

	var chest := _spawn("Chest", gen.pois.HOME + Vector2i(0, -2))
	if chest:
		chest.entity_id = "home_chest"

	var mother_home := _spawn("Npc", gen.pois.HOME + Vector2i(2, 2))
	if mother_home:
		mother_home.dialogue_key = "mother_farewell"
		mother_home.entity_id    = "mother_home"
		mother_home.sleep_after  = true

	# HUT (centre): diary only
	var diary := _spawn("Diary", gen.pois.HUT + Vector2i(1, 1))
	if diary:
		diary.entity_id = "father_diary"

	# HEART shrine
	var shrine := _spawn("HeartShrine", gen.pois.HEART)
	if shrine:
		shrine.entity_id = "heart_shrine"

	# Monsters
	for spawn in gen.monster_spawns:
		var m := _spawn("Monster", spawn.pos)
		if m:
			m.add_to_group("monster")

	# Spirits (Echo-only atmosphere)
	for pos in gen.spirit_spawns:
		_spawn("Spirit", pos)

	# POI markers
	var poi_tex = load("res://assets/ui/poi_marker.png")
	if poi_tex:
		_add_poi_marker(gen.pois.HOME,  Color(1.0, 0.3, 0.3), poi_tex)
		_add_poi_marker(gen.pois.HUT,   Color(0.3, 0.5, 1.0), poi_tex)
		_add_poi_marker(gen.pois.HEART, Color(1.0, 0.9, 0.1), poi_tex)

# ---------------------------------------------------------------------------
func _spawn_puzzles(gen: Dictionary) -> void:
	for puzzle in gen.puzzle_spawns:
		var pos: Vector2i = puzzle.pos
		var id: String    = puzzle.id
		
		# For puzzle items, we find a reachable tile on the player's side
		var item_pos1 = _get_random_reachable_tile(pos, 2.0, 6.0)
		var item_pos2 = _get_random_reachable_tile(pos, 2.0, 6.0)
		
		match puzzle.type:
			"RealityBridgeGate":
				var chasm  := _spawn("Chasm",  pos)
				var bridge := _spawn("Bridge", pos)
				if chasm:  chasm.entity_id  = id + "_chasm"
				if bridge: bridge.entity_id = id + "_bridge"
				_add_puzzle_barrier(pos, gen.grid)
				GameState.puzzle_states[id] = false

			"KeyLockGate":
				var door := _spawn("Door", pos)
				var key  := _spawn("Key",  item_pos1)
				if door: door.entity_id = id + "_door"
				if key:  key.entity_id  = id + "_key"
				_add_puzzle_barrier(pos, gen.grid)
				GameState.puzzle_states[id] = false

			"EchoSwitchesGate":
				var door := _spawn("Door",   pos)
				var sw1  := _spawn("Switch", item_pos1)
				var sw2  := _spawn("Switch", item_pos2)
				if door:
					door.entity_id   = id + "_door"
					door.switch_locked = true
					door.requires_key  = false
				if sw1: sw1.entity_id = id + "_sw1"
				if sw2: sw2.entity_id = id + "_sw2"
				if door and sw1 and sw2:
					var gate := EchoSwitchGate.new()
					gate.setup([sw1, sw2], door)
					entities.add_child(gate)
				_add_puzzle_barrier(pos, gen.grid)
				GameState.puzzle_states[id] = false
				
		# After placing the puzzle items, we "unlock" this door and expand the reachable area
		# so the next puzzles can use the space behind this door.
		var new_reachable = _expand_reachable_from(pos, gen)
		for r in new_reachable:
			if not r in _reachable_tiles_cache:
				_reachable_tiles_cache.append(r)

func _expand_reachable_from(start_pos: Vector2i, gen: Dictionary) -> Array:
	var visited := {}
	for r in _reachable_tiles_cache:
		visited[r] = true
	var queue: Array = [start_pos]
	visited[start_pos] = true
	var reachable := []
	var blocked := {}
	for p in gen.puzzle_spawns:
		if p.pos != start_pos and not p.pos in _reachable_tiles_cache:
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					blocked[p.pos + Vector2i(dx, dy)] = true

	while queue.size() > 0:
		var curr: Vector2i = queue.pop_front()
		reachable.append(curr)
		var dirs: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		for d in dirs:
			var nxt = curr + d
			if nxt.x < 0 or nxt.y < 0 or nxt.x >= gen.grid[0].size() or nxt.y >= gen.grid.size(): continue
			if nxt in visited: continue
			if nxt in blocked: continue
			if gen.grid[nxt.y][nxt.x] != Const.TILE_PATH: continue
			visited[nxt] = true
			queue.append(nxt)
	return reachable

# Add a localized barrier and dense forest ring around the puzzle
func _add_puzzle_barrier(tile_pos: Vector2i, grid: Array) -> void:
	var ts   := float(Const.TILE_SIZE)
	var c    := _wp(tile_pos)

	# 1. Spawn 4 diagonal blocks to form an X barrier.
	# This leaves the Top, Bottom, Left, and Right approach paths completely open!
	var b_size = Vector2(ts * 0.5, ts * 0.5)
	_add_border_wall(c + Vector2(-ts, -ts), b_size)
	_add_border_wall(c + Vector2( ts, -ts), b_size)
	_add_border_wall(c + Vector2(-ts,  ts), b_size)
	_add_border_wall(c + Vector2( ts,  ts), b_size)
			
	# 2. Spawn a dense forest ring (radius 2 to 6) on non-path tiles to prevent bypass
	for dy in range(-6, 7):
		for dx in range(-6, 7):
			var dist = Vector2(dx, dy).length()
			if dist >= 2.0 and dist <= 6.5:
				var px = tile_pos.x + dx
				var py = tile_pos.y + dy
				if px > 0 and py > 0 and px < grid[0].size() and py < grid.size():
					if grid[py][px] != Const.TILE_PATH:
						_spawn_border_tree(Vector2i(px, py))

# ---------------------------------------------------------------------------
func _spawn_border() -> void:
	var mw := Const.MAP_W_TILES * Const.TILE_SIZE
	var mh := Const.MAP_H_TILES * Const.TILE_SIZE
	# Four invisible walls outside map edges
	_add_border_wall(Vector2(mw / 2.0, -16),     Vector2(mw + 64, 32))
	_add_border_wall(Vector2(mw / 2.0, mh + 16), Vector2(mw + 64, 32))
	_add_border_wall(Vector2(-16, mh / 2.0),     Vector2(32, mh + 64))
	_add_border_wall(Vector2(mw + 16, mh / 2.0), Vector2(32, mh + 64))

	# Light visual border: spawn a tree every 3 tiles along the outer ring
	# (every tile would be ~1200 instances; every 3 = ~400)
	var w := Const.MAP_W_TILES
	var h := Const.MAP_H_TILES
	for x in range(0, w, 3):
		_spawn_border_tree(Vector2i(x, 0))
		_spawn_border_tree(Vector2i(x, h - 1))
	for y in range(0, h, 3):
		_spawn_border_tree(Vector2i(0, y))
		_spawn_border_tree(Vector2i(w - 1, y))

func _spawn_border_tree(tile_pos: Vector2i) -> void:
	if not _scenes.has("Tree"):
		return
	var node: Node = _scenes["Tree"].instantiate()
	node.position = _wp(tile_pos)
	if node.has_node("Sprite2D"):
		node.get_node("Sprite2D").modulate = Color(0.20, 0.26, 0.20, 1.0)
	entities.add_child(node)

func _add_border_wall(pos: Vector2, size: Vector2) -> void:
	var body  := StaticBody2D.new()
	body.position = pos
	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	entities.add_child(body)

# ---------------------------------------------------------------------------
func _spawn(type: String, tile_pos: Vector2i) -> Node:
	if not _scenes.has(type):
		return null
	var node: Node = _scenes[type].instantiate()
	node.position  = _wp(tile_pos)
	entities.add_child(node)
	return node

func _add_poi_marker(tile_pos: Vector2i, tint: Color, tex: Texture2D) -> void:
	var spr := Sprite2D.new()
	spr.texture  = tex
	spr.modulate = tint
	spr.position = _wp(tile_pos)
	entities.add_child(spr)

func _wp(tile_pos: Vector2i) -> Vector2:
	return Vector2(
		tile_pos.x * Const.TILE_SIZE + Const.TILE_SIZE * 0.5,
		tile_pos.y * Const.TILE_SIZE + Const.TILE_SIZE
	)

# ---------------------------------------------------------------------------
func _on_reality_changed(_new: Variant) -> void:
	var target := Const.TINT_ECHO if RealityManager.is_echo() else Const.TINT_LIGHT
	var tw := create_tween()
	tw.tween_property(canvas_modulate, "color", target, RealityManager.FADE_TIME)
	AudioManager.play_ambient(RealityManager.current)
