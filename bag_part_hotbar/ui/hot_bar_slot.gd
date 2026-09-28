extends Button

@onready var slot_item: SlotItem = $SlotBackground/CenterContainer/slot_item
@onready var slot_background: ColorRect = $SlotBackground

# 将快捷栏格子更新为对应库存格子的状态（显示物品/清空）
# hot_slot: 参数，背包快捷栏的库存格子数据（Slot类型，从快捷栏UI脚本传递过来）
func update_to_slot(hot_slot: Slot) -> void:
	# 情况1：当前库存格子没有物品（快捷栏格子清空显示）
	if !hot_slot or !hot_slot.item:
		# 隐藏物品显示节点（不显示图标和数量）
		slot_item.visible = false
		# 背景设为深色（表示空格子）
		slot_background.color = Color(0.5, 0.5, 0.5, 0.8)
		
		return # 清空显示后，直接返回，不执行后续代码
	
	# 情况2：当前库存格子有物品（快捷栏格子显示对应物品）
	# 给物品显示节点设置库存数据（关联物品类型和数量）
	slot_item.slot_ = hot_slot
	# 更新物品显示（显示图标和对应数量，和背包格子一致）
	slot_item.slot_item_update()
	# 显示物品节点（让玩家看到物品）
	slot_item.visible = true
	
	# 背景设为浅色（表示有物品）
	slot_background.color = Color(0.7, 0.7, 0.7, 0.8)
