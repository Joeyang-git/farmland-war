class_name building_const
extends Object

## 单格像素尺寸（与 TileSet 保持一致）
const TILE_SIZE: int = 16

## 建筑占地尺寸（格数）
enum SIZE {
	SMALL  = 1,  ## 低级 1×1
	MEDIUM = 2,  ## 中级 2×2
	LARGE  = 3,  ## 高级 3×3
}

## 技能类型
enum SKILL_TYPE {
	ACTIVE,   ## 主动：CD 就绪后需要用户点击释放
	PASSIVE,  ## 被动：按周期/触发条件自动生效
}
