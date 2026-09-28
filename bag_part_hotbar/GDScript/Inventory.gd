extends Resource

# 给背包模板起类名Inventory，后续控制背包都靠这个类
class_name Inventory

# 库存更新信号，库存数据发生变化时，发送这个信号，通知UI同步更新
signal inventory_update

# 定义一个Slot类型的数组slots，默认空数组
#（数组就是“容器”，把所有格子都装在这里，比如背包有20格，这里就存20个Slot）
@export var slots: Array[Slot]

# 移除库存格子物品的函数
func remove_slot(slot__: Slot):
	# 找到当前库存格子（slot__）在slots数组里的索引（位置）
	# find找不到就会返回 -1
	var index_ = slots.find(slot__)
	
	# 如果找不到这个格子（index<0），直接返回，避免报错
	if index_ < 0: return
	
	# 核心操作：把数组中这个索引位置的格子，替换成一个新的空Slot（清空库存格子）
	slots[index_] = Slot.new()
	
	# 发送库存更新信号（通知UI：库存变了，同步更新！）
	inventory_update.emit()

# 插入物品到指定库存格子的函数（背包UI放入物品时，调用这个函数更新库存）
func insert_slot(slot_index: int, slot__: Slot):
	# 核心操作：把传入的物品格子数据（slot__），赋值给slots数组中指定索引（slot_index）的位置
	slots[slot_index] = slot__
	# 发送库存更新信号（通知UI：库存变了，同步更新！）
	inventory_update.emit()

# 使用快捷栏对应索引的物品
# use_index: 参数，快捷栏格子的索引
# （比如索引0对应快捷栏第1格、索引1对应第2格，和背包快捷栏一一对应）
func use_item(use_index: int):
	# 容错判断 避免报错
	if use_index < 0 or use_index >= slots.size() or !slots[use_index].item or !slots[use_index].item.use_mouse_right:
		return
	
	# 获取要使用的库存格子（快捷栏索引对应的背包库存格子）
	var use_slot = slots[use_index]
	
	# 如果有耐久度
	if use_slot.item.max_use_times > 1:
		# 如果是第一次使用，初始化耐久度
		if not use_slot.is_used:
			# 将当前使用次数设置成物品的最大使用次数
			use_slot.current_use_times = use_slot.item.max_use_times
			# 标记成已使用过
			use_slot.is_used = true
		
		# 减少耐久度
		use_slot.current_use_times -= 1
		
		# 判断物品是否损坏
		if use_slot.current_use_times <= 0:
			clear_item(use_index) # 如果损坏就删除物品
			return # 直接返回不执行后续操作
		else:
			# 工具还未损坏，只更新显示
			inventory_update.emit()
			return # 直接返回不执行后续操作
	
	# 情况1：物品数量大于1（使用1个，数量减少1，不删除物品）
	if use_slot.count > 1:
		use_slot.count -= 1 # 物品数量减1（比如3个苹果，使用后变成2个）
		inventory_update.emit() # 发送库存更新信号，触发快捷栏、背包UI同步
		return # 执行完数量减少，直接返回
	
	# 情况2：物品数量等于1（使用后，直接删除该物品）
	clear_item(use_index)

func clear_item(clear_index: int):
	# 核心操作：把数组中这个索引位置的格子，替换成一个新的空Slot（清空库存格子）
	slots[clear_index] = Slot.new()
	
	# 发送库存更新信号（通知UI：库存变了，同步更新！）
	inventory_update.emit()

# 鼠标左键点击实用工具
func use_tool(use_index: int):
	# 容错判断 避免报错
	if use_index < 0 or use_index >= slots.size() or !slots[use_index].item  or !slots[use_index].item.use_mouse_left:
		return
	
	# 获取要使用的库存格子（快捷栏索引对应的背包库存格子）
	var use_slot = slots[use_index]
	
	# 如果有耐久度
	if use_slot.item.max_use_times > 1:
		# 如果是第一次使用，初始化耐久度
		if not use_slot.is_used:
			# 将当前使用次数设置成物品的最大使用次数
			use_slot.current_use_times = use_slot.item.max_use_times
			# 标记成已使用过
			use_slot.is_used = true
		
		# 减少耐久度
		use_slot.current_use_times -= 1
		
		# 判断物品是否损坏
		if use_slot.current_use_times <= 0:
			clear_item(use_index) # 如果损坏就删除物品
			return # 直接返回不执行后续操作
		else:
			# 工具还未损坏，只更新显示
			inventory_update.emit()
			return # 直接返回不执行后续操作
	
	# 情况1：物品数量大于1（使用1个，数量减少1，不删除物品）
	if use_slot.count > 1:
		use_slot.count -= 1 # 物品数量减1（比如3个苹果，使用后变成2个）
		inventory_update.emit() # 发送库存更新信号，触发快捷栏、背包UI同步
		return # 执行完数量减少，直接返回
	
	# 情况2：物品数量等于1（使用后，直接删除该物品）
	clear_item(use_index)
