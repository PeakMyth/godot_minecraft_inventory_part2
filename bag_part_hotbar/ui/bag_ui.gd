extends Control

@onready var bag_slot_container: GridContainer = $PanelContainer/MarginContainer/VBoxContainer/BagSlotContainer
@onready var hot_bar_container: HBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/HotBarContainer

# 获取所有背包UI格子按钮（快捷栏的格子 + 背包的格子），
#get_children()是获取容器下所有子节点（也就是SlotButton）
@onready var bag_slots: Array = $PanelContainer/MarginContainer/VBoxContainer/HotBarContainer.get_children() +$PanelContainer/MarginContainer/VBoxContainer/BagSlotContainer.get_children() 

# 不再硬编码库存，而是从外部传入
var bag_inventory: Inventory
# 预加载slot_item场景
@onready var slotitem_ = preload("res://ui/slot_item.tscn")

# 存储当前跟随鼠标的物品节点（SlotItem类型，记录正在被抓取的物品）
var mouse_item: SlotItem = null

func _ready() -> void:
	connect_signal() # 调用信号连接函数，连接所有格子的点击信号
	close_bag()
	
	for i in range(bag_slots.size()):
		# 获取当前循环的UI格子（bag_slots[i]：第i个UI格子）
		var slot = bag_slots[i]
		# 给当前UI格子的slot_index变量（slot_button.gd里新增的变量）赋值为i
		# 意思是：第0个UI格子，对应库存第0格；第1个UI格子，对应库存第1格，以此类推
		slot.slot_index = i


func connect_signal():
	for slot_button in bag_slots:# 循环遍历所有UI格子（每个slot_button都是一个格子按钮）
		slot_button.mouse_button_left_press.connect(mouse_left_slot_button.bind(slot_button))
		slot_button.mouse_button_right_press.connect(mouse_right_slot_button.bind(slot_button))

# 背包更新核心函数：把库存数据同步到UI格子上，后续物品增减、切换都要调用这个函数
func bag_update():
	if bag_inventory.slots.size() != bag_slots.size():
		return
	# 36 = 36
	
	
	# 循环遍历所有UI格子（i是索引，从0开始，对应每个格子的位置）
	for i in range(bag_slots.size()):
		# inventory_slots 就可以代表玩家库存数据中的一个个格子
		# bag_slots[i] 就可以代表UI里面的一个个格子
		
		var inventory_slots: Slot = bag_inventory.slots[i]
		
		# 检查当前库存格子是否为空（防止null报错，比如库存格子没创建）
		if !inventory_slots:
			#if bag_slots[i].slot_button_slot_item:
				#bag_slots[i].slot_button_slot_item.queue_free()
				# 把UI格子的物品节点设为null，避免残留引用
				#bag_slots[i].slot_button_slot_item = null
				# 重置UI格子的背景颜色（恢复默认灰色，和空格子对应）
			bag_slots[i].reset_color()
			continue # 跳过当前循环，继续下一个格子（当前格子是空的，不用再执行后续操作）
		
		# 再检查当前库存格子里是否有物品（如果库存格子存在，但里面没物品）
		if !inventory_slots.item:
			#if bag_slots[i].slot_button_slot_item:
				#bag_slots[i].slot_button_slot_item.queue_free()
				#bag_slots[i].slot_button_slot_item = null
			#bag_slots[i].reset_color()  # 重置颜色
			bag_slots[i].clear_slot()
			continue # 跳过当前循环，继续下一个格子
		
		# 到这里，说明库存格子有物品，开始在UI格子上显示物品
		
		# 获取当前UI格子里的物品显示节点（slot_button_slot_item是slot_button脚本里的变量）
		var slot_item: SlotItem = bag_slots[i].slot_button_slot_item
		
		# 如果UI格子里没有物品显示节点，就实例化一个slot_item场景（创建一个物品显示节点）
		if !slot_item:
			slot_item = slotitem_.instantiate()
			bag_slots[i].insert(slot_item) # 把实例化的物品显示节点，插入到当前UI格子里
			
		# 把库存格子的数据（inventorySlot）赋值给物品显示节点的slot_变量，让它知道要显示哪个物品
		slot_item.slot_ = inventory_slots
		# 调用物品显示节点的更新函数，让它显示物品图标和数量
		slot_item.slot_item_update()

# 新增：设置背包库存的函数（外部传入库存时调用）
func set_player_inventory(player_inventory: Inventory): 
	# 把外部传入的玩家专属库存，赋值给当前bag_ui的库存变量
	bag_inventory = player_inventory
	# 如果库存不为空，就调用更新函数，同步UI显示（避免打开背包时UI空白）
	if bag_inventory:
		bag_update()


func open_bag(player_inventory: Inventory):
	set_player_inventory(player_inventory)
	
	# 如果已经有库存对象，先断开之前的连接
	if bag_inventory.inventory_update.is_connected(bag_update):
		bag_inventory.inventory_update.disconnect(bag_update)
	
	bag_inventory.inventory_update.connect(bag_update)
	
	for slot_button in bag_slots:
		slot_button.slot_inventory = bag_inventory
	show()

# 背包关闭函数
func close_bag():
	hide()# 隐藏当前节点（bag_ui），也就是关闭背包

# 鼠标左键点击格子的处理函数（判断是“抓取物品”还是“放入物品”）
func mouse_left_slot_button(slot_button):
	# 情况1：点击的格子是空的，且有正在跟随鼠标的物品（准备把物品放入格子）
	if slot_button.is_empty() and mouse_item:
		
		insert_item_in_slot(slot_button)
	
	# 情况2：点击的格子有物品，且没有正在跟随鼠标的物品（准备抓取物品）
	elif !slot_button.is_empty() and !mouse_item:
		take_item_from_slot(slot_button)
	
	# 情况3：点击的格子有物品，且鼠标上正跟随有物品（准备交换或堆叠两个物品）
	elif !slot_button.is_empty() and mouse_item:
		# 情况3-1 判断：两个物品的ID不一样（不同物品才交换，相同物品后续做堆叠，本期不实现）
		if slot_button.slot_button_slot_item.slot_.item.id != mouse_item.slot_.item.id:
			# 调用交换函数，实现两个物品互换
			swap_items(slot_button)
		
		# 情况3-2：两个物品的ID一样（相同物品，判断是堆叠还是交换）
		elif slot_button.slot_button_slot_item.slot_.item.id == mouse_item.slot_.item.id:
			# 情况3-2-1：如果物品的最大堆叠数是1（无法堆叠，比如工具、武器），执行交换
			if slot_button.slot_button_slot_item.slot_.item.max_stack == 1:
			#if slot_button.slot_button_slot_item.slot_.count == slot_button.slot_button_slot_item.slot_.item.max_stack:
				swap_items(slot_button)
			
			# 情况3-2-2：如果物品的最大堆叠数>1（可以堆叠，比如苹果、木头），执行堆叠
			else:
				stack_items(slot_button)
		
		else:
			return
	
	else:
		return

# 从格子抓取物品的函数（调用slot_button的take_item，控制物品跟随鼠标）
func take_item_from_slot(slot_button):
	# 调用当前格子的take_item函数，取出物品，赋值给mouse_item（跟随鼠标的物品）
	mouse_item = slot_button.take_item()
	# 把抓取到的物品节点，添加为当前bag_ui的子节点（让物品显示在背包上层，不被遮挡）
	add_child(mouse_item)
	item_follow_mouse()

# 物品跟随核心函数（让mouse_item跟着鼠标移动）
func item_follow_mouse():
	# 容错判断：如果没有跟随鼠标的物品（mouse_item是null），直接返回，避免报错
	if !mouse_item:
		return
	
	# 设置物品的全局位置 = 鼠标的全局位置
	mouse_item.global_position = get_global_mouse_position()

# 新增：输入事件检测函数
func _input(event: InputEvent) -> void:
	item_follow_mouse()

# 放入物品函数
func insert_item_in_slot(slot_button):
	# 临时记录鼠标上的物品，避免后续操作丢失物品引用
	var item_ = mouse_item
	
	# 让物品不再跟随鼠标（相当于“松开”物品，准备放进格子）
	remove_child(mouse_item)
	
	# 表示鼠标上没有物品了，重置鼠标物品状态
	mouse_item = null
	
	# 调用当前空格子（slot_button）的insert函数，把物品放进格子
	slot_button.insert(item_)

# 物品交换核心函数（实现“鼠标上的物品”和“点击格子里的物品”互换）
func swap_items(slot_button):
	# 第一步：调用当前点击格子的take_item函数，取出格子里的物品，赋值给临时变量one_item
	# 作用：先把点击格子里的物品“抓出来”，临时保存，方便后续交换
	var one_item = slot_button.take_item()
	
	# 第二步：调用放入物品函数，把鼠标上的物品，放进当前点击的格子里
	# 相当于：把鼠标上的物品，放到刚才空出来的格子里（完成第一步交换）
	insert_item_in_slot(slot_button)
	
	# 第三步：把刚才临时保存的物品（one_item），赋值给mouse_item
	# 作用：让这个“被抓出来”的物品，开始跟随鼠标
	mouse_item = one_item
	
	# 第四步：把跟随鼠标的物品（one_item），添加为bag_ui的子节点
	# 作用：让物品显示在背包上层，不被背包其他节点遮挡，和第六期抓取物品的逻辑一致
	add_child(mouse_item)
	
	# 第五步：调用鼠标跟随函数，让交换后跟随鼠标的物品，立刻跟着鼠标移动
	# 避免物品交换后，停留在原地，不跟随鼠标，影响操作体验
	item_follow_mouse()

# 物品堆叠核心函数（重点！实现“相同物品”数量叠加，处理超出上限的情况）
func stack_items(slot_button):
	# 第一步：获取当前点击格子里的物品显示节点（SlotItem），赋值给one_item
	# 作用：后续操作当前格子里的物品（修改数量、更新显示）
	var one_item: SlotItem = slot_button.slot_button_slot_item
	# 第二步：获取当前物品的最大堆叠数（从物品属性中获取，比如苹果最大堆叠数量64）
	var max_stack_count = one_item.slot_.item.max_stack
	# 第三步：计算“当前格子物品数量 + 鼠标上物品数量”的总数量
	var total_count = one_item.slot_.count + mouse_item.slot_.count
	
	# 第四步：容错判断：如果当前格子物品数量已经达到最大堆叠数，直接返回，不执行堆叠
	# 避免出现“数量超出上限”的bug，比如格子里已经有64个苹果，再放就不执行
	if one_item.slot_.count == max_stack_count:
		return
	
	# 第五步：分两种情况处理堆叠（总数量≤上限 vs 总数量>上限）
	# 情况1：总数量 ≤ 最大堆叠数（比如格子有5个苹果，鼠标有3个，总8个≤64）
	if total_count <= max_stack_count:
		# 把当前格子的物品数量，更新为总数量（5+3=8）
		one_item.slot_.count = total_count
		# 销毁鼠标上的物品节点（鼠标上的物品全部堆叠到格子里，没有剩余）
		remove_child(mouse_item)
		mouse_item.queue_free()
		# 重置mouse_item为null，告诉程序“鼠标上没有物品了”
		mouse_item = null
	
	# 情况2：总数量 > 最大堆叠数（比如格子有50个苹果，鼠标有50个，总100>64）
	else:
		# 把当前格子的物品数量，设为最大堆叠数
		one_item.slot_.count = max_stack_count
		# 鼠标上物品的数量，设为“总数量 - 最大堆叠数”（100-64=36，剩余36个跟随鼠标）
		mouse_item.slot_.count = total_count - max_stack_count
	
	# 第六步：更新物品显示（关键！让格子里、鼠标上的物品数量，实时显示正确）
	# 如果当前格子物品存在，调用slot_item_update()更新数量显示
	if one_item: one_item.slot_item_update()
	# 如果鼠标上还有剩余物品，调用slot_item_update()更新剩余数量显示
	if mouse_item: mouse_item.slot_item_update()
	
	# 发送库存更新信号，通知UI同步显示（确保格子、鼠标物品数量和库存一致）
	bag_inventory.inventory_update.emit()

func mouse_right_slot_button(slot_button):
	# 情况1：点击的格子有物品，且鼠标上正跟随有物品（和左键逻辑类似，执行交换）
	if !slot_button.is_empty() and mouse_item:
		# 情况1-1：两个物品ID不一样，执行交换（和左键交换逻辑完全一致）
		if slot_button.slot_button_slot_item.slot_.item.id != mouse_item.slot_.item.id:
			swap_items(slot_button)
		# 情况1-2：两个物品ID一样，放入一个物品判断
		else:
			put_one_item_to_slot(slot_button)
	
	# 情况2：点击的格子有物品，且鼠标上没有物品，执行取出一半物品
	elif !slot_button.is_empty() and !mouse_item:
		# 调用新增的取一半物品函数，实现拆分堆叠
		take_half_items(slot_button)
	
	# 情况3：点击的格子是空的，且鼠标上有物品
	elif slot_button.is_empty() and mouse_item:
		# 调用投放函数，放入1个物品
		put_one_item_to_slot(slot_button)
	
	else:
		return

func take_half_items(slot_button):
	# 如果格子里只有1个物品，右键点击直接抓取（和左键抓取逻辑一致）
	if slot_button.slot_button_slot_item.slot_.count == 1:
		take_item_from_slot(slot_button)
		return # 执行完抓取，直接返回，不执行后续取一半逻辑
	
	# 格子里有多个物品（堆叠物品），执行取一半逻辑
	# 第一个变量：获取当前格子里的原物品显示节点（SlotItem），赋值给original_item
	var original_item: SlotItem = slot_button.slot_button_slot_item
	# 第二个变量：获取原物品的总数量（比如9个苹果，original_count=9）
	var original_count = original_item.slot_.count
	# 第三个变量：计算要取出的数量（ceil函数：向上取整，避免出现小数，比如9/2=4.5，取5）
	var take_count = ceil(original_count / 2.0)
	
	#（深拷贝，重点！避免和原物品数据冲突）
	# 为什么要深拷贝？如果直接把原物品赋值给新物品，新物品和原物品会共用一套数据，修改一个会影响另一个
	# 创建新的物品节点（用于跟随鼠标）
	var new_item = slotitem_.instantiate()
	# 创建新的Slot对象（深拷贝）
	var new_slot = Slot.new()
	
	# 新物品的类型，和原物品一致（比如都是苹果）
	new_slot.item = original_item.slot_.item
	# 新物品的数量，就是刚才计算的“取出数量”
	new_slot.count = take_count
	# 给新创建的物品节点，设置对应的Slot数据（关联物品类型和数量）
	new_item.slot_ = new_slot
	# 更新原物品的数量（原数量 - 取出数量，比如9-5=4，原格子里剩下4个）
	original_item.slot_.count = original_count - take_count
	
	# 设置鼠标物品，让新创建的物品（取出的一半）跟随鼠标
	mouse_item = new_item # 告诉程序，当前跟随鼠标的是这个新物品
	add_child(mouse_item) # 把新物品添加为bag_ui的子节点，避免被遮挡
	item_follow_mouse()   # 调用鼠标跟随函数，让新物品立刻跟随鼠标移动
	
	# 更新物品显示
	if mouse_item: mouse_item.slot_item_update() # 更新鼠标上物品的数量显示
	if original_item: original_item.slot_item_update() # 更新原格子里物品的数量显示
	
	# 发送库存更新信号，通知UI同步显示（确保格子、鼠标物品数量和库存一致）
	bag_inventory.inventory_update.emit()

func put_one_item_to_slot(slot_button):
	# 核心步骤：调用当前格子的put_one_item函数，传入鼠标物品的Slot数据，判断是否放入成功
	var success = slot_button.put_one_item(mouse_item.slot_)
	
	# 如果放入成功（success为true），处理鼠标上的物品
	if success:
		# 子判断：如果鼠标上物品数量≤0（最后一个全部放入了，没有剩余）
		if mouse_item.slot_.count <= 0:
			# 把鼠标物品从bag_ui的子节点中移除（不再跟随鼠标）
			remove_child(mouse_item)
			# 销毁鼠标物品节点（释放内存，避免内存泄漏）
			mouse_item.queue_free()
			# 重置mouse_item为null，告诉程序“鼠标上没有物品了”
			mouse_item = null
		
		# 其他情况：也就是鼠标上还有剩余物品，更新物品数量显示
		else:
			# 更新鼠标物品的显示
			mouse_item.slot_item_update()
	
	# 发送库存更新信号，通知UI同步显示（确保格子、鼠标物品数量和库存一致）
	bag_inventory.inventory_update.emit()
