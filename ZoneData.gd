# ZoneData.gd
extends Resource
class_name ZoneData

@export var zone_name: String = "New Zone"

# Requirements to enter
@export var required_attack: int = 0
@export var required_defense: int = 0

# Visuals
@export var background: Texture2D

# Loot & Spawns
@export var possible_slimes: Array[SlimeData] = []

# Difficulty Multiplier (Bonus crystals for harder zones)
@export var crystal_multiplier: float = 1.0

func can_enter_zone(zone: ZoneData) -> bool:
	var player_atk = GameData.get_attack()
	var player_def = GameData.get_defense()
	
	if player_atk >= zone.required_attack and player_def >= zone.required_defense:
		return true
	else:
		print("You are too weak for ", zone.zone_name)
		return false
