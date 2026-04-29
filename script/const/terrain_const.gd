## 地形系统常量（PRD 3.1）。
##
## 地形分两层：
##   - TerrainLayer：底层静态地形（草地/废墟/障碍），custom_data "terrain" 标识类型
##   - OwnershipLayer：上层动态归属（HUMAN/AI），custom_data "user" 标识归属玩家
##
## 占领规则：
##   - EMPTY    : 1 HP，可被占领
##   - RUIN     : 2 HP，可被占领；被己方领地完全闭环包围时自动归属（PRD 3.2.3）
##   - OBSTACLE : 不可占、不可建、不可通行；不参与包围判定（PRD 3.1.5）
class_name terrain_const
extends Object

## 地形类型；与 TileSet 自定义层 "terrain" 的整型对应
enum TYPE {
	EMPTY    = 0,  ## 无主地（默认）
	RUIN     = 1,  ## 废墟
	OBSTACLE = 2,  ## 障碍：树林/河流/池塘
}

## 各地形初始耐久（建筑占格的耐久由 building.max_hp 决定，与此无关）
const HP_EMPTY: int = 1
const HP_RUIN:  int = 2
