extends RefCounted
class_name InventorySystem

static func craft_basic_upgrade() -> bool:
	if GameState.consume_item("scrap", 20):
		GameState.add_item("spark_cutter", 1)
		GameState.notify("合成完成：火花切割器")
		return true
	GameState.notify("廢鐵不足，需要 20")
	return false

static func forge_ammo_pack() -> bool:
	if GameState.consume_item("scrap", 8):
		GameState.add_item("ammo", 12)
		GameState.notify("鍛造完成：彈藥 x12")
		return true
	GameState.notify("廢鐵不足，需要 8")
	return false
