extends TileMapLayer


func _ready() -> void:
	_collect_players()


func _process(_delta: float) -> void:
	pass


## 扫描 TileSet 自定义层 "user"，为每个不同 uid 实例化一个 Player 节点并记录初始地块。
func _collect_players() -> Dictionary[int, player]:
	## uid(int) -> Player
	var players: Dictionary[int, player] = {}

	if tile_set == null:
		push_warning("Map: tile_set 为空，无法收集 user 数据。")
		return players

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

	for uid: int in players:
		var p: player = players[uid]
		print("uid=%d user_type=%d cells=%s" % [p.uid, p.user_type, p.cells])

	return players

	
