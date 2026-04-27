extends TileMapLayer

## uid(int) -> player
var players: Dictionary[int, player] = {}

## 格子当前血量表；未记录的格子视为满血（空地默认 1）
var tile_hp: Dictionary[Vector2i, int] = {}


func _enter_tree() -> void:
	add_to_group("map_layer")


func _ready() -> void:
	_collect_players()
	_collect_buildings()


func _process(_delta: float) -> void:
	pass


## 扫描 TileSet 自定义层 "user"，为每个不同 uid 实例化一个 Player 节点并记录初始地块。
func _collect_players() -> void:
	players.clear()

	if tile_set == null:
		push_warning("Map: tile_set 为空，无法收集 user 数据。")
		return

	for cell: Vector2i in get_used_cells():
		var td: TileData = get_cell_tile_data(cell)
		if td == null:
			continue
		var uid: int = td.get_custom_data("user") as int
		if uid == 0:
			continue

		if not players.has(uid):
			var p := player.new()
			p.uid = uid
			p.user_type = player_const.USER_TYPE.HUMAN if uid == 1 else player_const.USER_TYPE.AI
			add_child(p)
			players[uid] = p

		players[uid].cells.append(cell)


## 扫描场景树中所有 building 节点，初始化其占格的 tile_hp，并绑定 map 引用。
## 建筑每格的初始血量 = building.max_hp；占格由 get_occupied_cells() 提供。
func _collect_buildings() -> void:
	var all_buildings := get_tree().get_nodes_in_group("building")
	for node in all_buildings:
		var b := node as building
		if b == null:
			continue
		b.map = self
		for cell in b.get_occupied_cells():
			tile_hp[cell] = b.max_hp


## 返回格子当前血量；未受击过的格子返回默认值（空地 1）。
func get_tile_hp(cell: Vector2i) -> int:
	if tile_hp.has(cell):
		return tile_hp[cell]
	return 1


## 返回 attacker_uid 所有地块边界上可攻击的邻接格（去重）。
func get_border_targets(attacker_uid: int) -> Array[Vector2i]:
	if not players.has(attacker_uid):
		return []
	var owned: Array[Vector2i] = players[attacker_uid].cells
	var seen: Dictionary = {}
	var result: Array[Vector2i] = []
	var dirs := [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	for cell in owned:
		for d in dirs:
			var nb: Vector2i = cell + d
			if seen.has(nb):
				continue
			seen[nb] = true
			if is_attackable(nb, attacker_uid):
				result.append(nb)
	return result


## 该格是否可被 attacker_uid 攻击（存在于地图中、且不属于己方）。
func is_attackable(cell: Vector2i, attacker_uid: int) -> bool:
	var td: TileData = get_cell_tile_data(cell)
	if td == null:
		return false
	var cell_owner: int = td.get_custom_data("user") as int
	return cell_owner != attacker_uid


## 对目标格造成 1 点伤害；血量归零则将该格划归 attacker_uid。
func attack_cell(cell: Vector2i, attacker_uid: int) -> void:
	print("attack_cell: %s -> uid=%d" % [cell, attacker_uid])
	if not is_attackable(cell, attacker_uid):
		return

	var current_hp := get_tile_hp(cell)
	current_hp -= 1

	if current_hp <= 0:
		tile_hp.erase(cell)
		_claim_cell(cell, attacker_uid)
	else:
		tile_hp[cell] = current_hp


## 将格子归属改为 attacker_uid，并更新双方 player.cells。
func _claim_cell(cell: Vector2i, attacker_uid: int) -> void:
	var td: TileData = get_cell_tile_data(cell)
	if td == null:
		return

	var prev_owner: int = td.get_custom_data("user") as int

	# 从原归属者移除
	if prev_owner != 0 and players.has(prev_owner):
		players[prev_owner].cells.erase(cell)

	# 用对应玩家的瓦片覆盖（atlas 里 custom_data "user" 随瓦片自动更新）
	var atlas_coords := player_const.TILE_HUMAN if attacker_uid == player_const.USER_TYPE.HUMAN else player_const.TILE_AI
	set_cell(cell, 0, atlas_coords)

	# 写入新归属者
	if players.has(attacker_uid):
		players[attacker_uid].cells.append(cell)

	print("claim: %s -> uid=%d" % [cell, attacker_uid])
