extends Resource
class_name SlimeData

@export var name: String = "Green Slime"
@export var health: int = 10
@export var damage: int = 1
@export var attack_speed: float = 1.5
@export var texture: CompressedTexture2D
@export var crystal_drop_min: int = 1
@export var crystal_drop_max: int = 5
@export var hasSpecialDrop: bool = false
@export var spec_crystal_drop_min: int = 0
@export var spec_crystal_drop_max: int = 0
