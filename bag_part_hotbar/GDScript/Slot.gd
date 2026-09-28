extends Resource

class_name Slot

# 定义一个ItemData类型的变量item，表示格子里当前放的物品
@export var item: ItemData = null
@export var count: int = 0 #表示格子里物品的数量

var current_use_times: int = 1 # 当前使用次数，默认1（即消耗品）。
var is_used: bool = false # 工具是否被使用过的标记
