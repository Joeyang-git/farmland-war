## 对局里「人 / 机」、人数上限等约定。TileSet 自定义层 "user" 的整型尽量与 USER_TYPE 枚举对齐，避免魔法数分散。
class_name player_const
extends Object

## 多个真人、多个电脑时：仍然只有「人 / 机」两档；第几路由 [Player] 的 uid 区分。
enum USER_TYPE {
	HUMAN = 1,
	AI = 2,
}

const LOCAL_PEER_ID: int = 1 ## 单机模式下固定值，本机玩家的 peer_id

## TileSet Atlas 中标识初始领地归属的 tile 坐标（与 custom_data "user" 整型对应）
const TILE_HUMAN: Vector2i = Vector2i(1, 4)   ## user = HUMAN(1)
const TILE_AI: Vector2i = Vector2i(1, 10)  ## user = AI(2)
