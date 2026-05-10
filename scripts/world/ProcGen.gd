class_name ProcGen
extends RefCounted

const MAP_W := Const.MAP_W_TILES
const MAP_H := Const.MAP_H_TILES

static func generate(seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if seed == 0:
		rng.randomize()
		seed = rng.seed
	else:
		rng.seed = seed

	var grid := []
	for y in MAP_H:
		var row := []
		for x in MAP_W:
			row.append(Const.TILE_GRASS_A if rng.randf() > 0.3 else Const.TILE_GRASS_B)
		grid.append(row)

	var pois := _place_pois(rng)

	# Stamp POI clearings so paths connect and flood-fill works
	for poi in [pois.HOME, pois.HUT, pois.HEART]:
		_stamp_clearing(grid, poi, 3)

	_carve_path(grid, pois.HOME, pois.HUT, rng)
	_carve_path(grid, pois.HUT, pois.HEART, rng)
	_add_branches(grid, rng)

	var entity_spawns := _place_trees(grid, rng, pois)
	var puzzle_spawns := _place_puzzles(grid, rng, pois)
	var letter_spawns := _place_letters(grid, rng)
	var anchor_spawns := _place_anchors(pois)
	var monster_spawns := _place_monsters(grid, rng, pois)

	if not _validate(grid, pois):
		return generate(seed + 1)

	return {
		"seed": seed,
		"grid": grid,
		"pois": pois,
		"entity_spawns": entity_spawns,
		"puzzle_spawns": puzzle_spawns,
		"letter_spawns": letter_spawns,
		"anchor_spawns": anchor_spawns,
		"monster_spawns": monster_spawns,
	}

static func _place_pois(rng: RandomNumberGenerator) -> Dictionary:
	var home := Vector2i(8 + rng.randi_range(0, 3), 8 + rng.randi_range(0, 3))
	var heart := Vector2i(MAP_W - 10 + rng.randi_range(0, 3), MAP_H - 10 + rng.randi_range(0, 3))
	var hut: Vector2i
	var attempts := 0
	while attempts < 50:
		hut = Vector2i(MAP_W / 2 + rng.randi_range(-5, 5), MAP_H / 2 + rng.randi_range(-5, 5))
		if home.distance_to(hut) >= Const.MIN_POI_DIST and heart.distance_to(hut) >= Const.MIN_POI_DIST:
			break
		attempts += 1
	return {"HOME": home, "HUT": hut, "HEART": heart}

static func _stamp_clearing(grid: Array, center: Vector2i, radius: int) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var px := center.x + dx
			var py := center.y + dy
			if px > 0 and px < MAP_W - 1 and py > 0 and py < MAP_H - 1:
				grid[py][px] = Const.TILE_PATH

static func _carve_path(grid: Array, from: Vector2i, to: Vector2i, rng: RandomNumberGenerator) -> void:
	var pos := from
	var max_steps := 600
	var step := 0
	while pos.distance_to(to) > 2.0 and step < max_steps:
		var dir: Vector2i
		if rng.randf() < 0.7:
			var d := Vector2(to - pos).normalized()
			var dx := int(round(d.x))
			var dy := int(round(d.y))
			dir = Vector2i(dx, dy)
			if dir == Vector2i.ZERO:
				dir = Vector2i.RIGHT
		else:
			dir = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT][rng.randi() % 4]
		pos += dir
		pos.x = clampi(pos.x, 1, MAP_W - 2)
		pos.y = clampi(pos.y, 1, MAP_H - 2)
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var px := pos.x + dx
				var py := pos.y + dy
				if px > 0 and px < MAP_W - 1 and py > 0 and py < MAP_H - 1:
					grid[py][px] = Const.TILE_PATH
		step += 1

static func _add_branches(grid: Array, rng: RandomNumberGenerator) -> void:
	for _i in 8:
		var sx := rng.randi_range(5, MAP_W - 5)
		var sy := rng.randi_range(5, MAP_H - 5)
		if grid[sy][sx] != Const.TILE_PATH:
			continue
		var pos := Vector2i(sx, sy)
		for _j in rng.randi_range(10, 25):
			var dir: Vector2i = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT][rng.randi() % 4]
			pos += dir
			pos.x = clampi(pos.x, 1, MAP_W - 2)
			pos.y = clampi(pos.y, 1, MAP_H - 2)
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var px := pos.x + dx
					var py := pos.y + dy
					if px > 0 and px < MAP_W - 1 and py > 0 and py < MAP_H - 1:
						grid[py][px] = Const.TILE_PATH

static func _place_trees(grid: Array, rng: RandomNumberGenerator, pois: Dictionary) -> Array[Dictionary]:
	var spawns: Array[Dictionary] = []
	for y in MAP_H:
		for x in MAP_W:
			if grid[y][x] == Const.TILE_PATH:
				continue
			var pos := Vector2i(x, y)
			if pos.distance_to(pois.HOME) < 5 or pos.distance_to(pois.HUT) < 5 or pos.distance_to(pois.HEART) < 5:
				continue
			if rng.randf() < Const.TREE_DENSITY:
				var kind := "Tree" if rng.randf() > 0.2 else "Stone"
				spawns.append({"type": kind, "pos": pos})
	return spawns

static func _place_puzzles(grid: Array, rng: RandomNumberGenerator, pois: Dictionary) -> Array[Dictionary]:
	var spawns: Array[Dictionary] = []
	var types := ["RealityBridgeGate", "KeyLockGate", "EchoSwitchesGate", "KeyLockGate"]
	var used: Array[Vector2i] = []
	var attempts := 0
	while spawns.size() < Const.NUM_PUZZLES and attempts < 400:
		attempts += 1
		var x := rng.randi_range(5, MAP_W - 5)
		var y := rng.randi_range(5, MAP_H - 5)
		if grid[y][x] != Const.TILE_PATH:
			continue
		var pos := Vector2i(x, y)
		if pos.distance_to(pois.HOME) < 8 or pos.distance_to(pois.HUT) < 8 or pos.distance_to(pois.HEART) < 8:
			continue
		var too_close := false
		for u in used:
			if pos.distance_to(u) < 14:
				too_close = true
				break
		if too_close:
			continue
		used.append(pos)
		var idx := spawns.size()
		spawns.append({"type": types[idx], "pos": pos, "id": "puzzle_%d" % idx})
	return spawns

static func _place_letters(grid: Array, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var spawns: Array[Vector2i] = []
	var attempts := 0
	while spawns.size() < Const.NUM_LETTERS and attempts < 600:
		attempts += 1
		var x := rng.randi_range(3, MAP_W - 3)
		var y := rng.randi_range(3, MAP_H - 3)
		var pos := Vector2i(x, y)
		var too_close := false
		for s in spawns:
			if pos.distance_to(s) < 10:
				too_close = true
				break
		if too_close:
			continue
		spawns.append(pos)
	return spawns

static func _place_anchors(pois: Dictionary) -> Array[Vector2i]:
	return [
		pois.HOME + Vector2i(2, 0),
		pois.HUT + Vector2i(0, 2),
		pois.HEART + Vector2i(-2, 0),
	]

static func _place_monsters(grid: Array, rng: RandomNumberGenerator, pois: Dictionary) -> Array[Dictionary]:
	var spawns: Array[Dictionary] = []
	var attempts := 0
	while spawns.size() < Const.NUM_MONSTERS and attempts < 300:
		attempts += 1
		var x := rng.randi_range(5, MAP_W - 5)
		var y := rng.randi_range(5, MAP_H - 5)
		if grid[y][x] != Const.TILE_PATH:
			continue
		var pos := Vector2i(x, y)
		if pos.distance_to(pois.HOME) < 15:
			continue
		spawns.append({"type": "Monster", "pos": pos})
	return spawns

static func _validate(grid: Array, pois: Dictionary) -> bool:
	var visited := {}
	var queue: Array = [pois.HOME]
	visited[pois.HOME] = true
	while queue.size() > 0:
		var pos: Vector2i = queue.pop_front()
		for dir: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var nxt: Vector2i = pos + dir
			if nxt.x < 0 or nxt.x >= MAP_W or nxt.y < 0 or nxt.y >= MAP_H:
				continue
			if nxt in visited:
				continue
			if grid[nxt.y][nxt.x] != Const.TILE_PATH:
				continue
			visited[nxt] = true
			queue.append(nxt)
	return (pois.HUT in visited) and (pois.HEART in visited)
