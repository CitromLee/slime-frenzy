extends Resource
class_name ItemData

@export var item_name: String
@export_enum("Weapon", "Head", "Chest", "Legs") var slot: String
@export var level: int = 1
@export var tier: int = 0 # 0=Common, 5=Divine
@export var power: float = 10.0
@export var tierup_cost: int = 5
@export var levelup_cost: int = 10
