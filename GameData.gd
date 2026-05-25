extends CanvasLayer

const SAVE_PATH = "user://player_save.json"

var weapon: ItemData = load("res://Equipment_Res/Weapon.tres")
var helmet: ItemData = load("res://Equipment_Res/Helmet.tres")
var chestpiece: ItemData = load("res://Equipment_Res/Chestplate.tres")
var leggings: ItemData = load("res://Equipment_Res/Leggings.tres")

var current_zone: ZoneData = load("res://Zone_Res/Plains.tres")
var current_zone_index: int = 0

var zones = [
	"res://Zone_Res/Plains.tres",
	"res://Zone_Res/Forest.tres",
	"res://Zone_Res/Caves.tres",
	"res://Zone_Res/CrystalCaves.tres"
]
var current_slime: SlimeData = load("res://Slime_Res/Plains/GreenSlime.tres")

var player_max_hp: float = 100.0
var player_hp: float = 100.0
var player_regen: float = 0.2

var slime_crystals: int = 0
var special_crystals: int = 0

var luck: float = 1.0

func _ready() -> void:
	load_game()

func get_attack() -> float:
	var attack = 0.0
	attack += weapon.power
	
	attack = attack * (1 + weapon.tier * 0.05)
	
	return attack

func get_defense() -> float:
	var defense: float = 0.0
	defense += helmet.power + chestpiece.power + leggings.power
	
	# 1% defense increment per each tier of equipment
	defense = defense * (1 + helmet.tier * 0.01)
	defense = defense * (1 + chestpiece.tier * 0.01)
	defense = defense * (1 + leggings.tier * 0.01)
	return defense

func get_zone_resource(_index) -> ZoneData:
	return load(zones[_index])

func update_luck():
	var base_luck = 1
	var gear_luck = GameData.helmet.power + (GameData.helmet.level * 0.5)
	
	# Tier Multiplier
	var multiplier = 1.0 + (GameData.helmet.tier * 0.25) 
	
	luck = base_luck + (gear_luck * multiplier)
	
func get_chest_drop_chance() -> float:
	# Base 2.5% + 1% for every point of luck(asszem??)
	return 0.025 + (luck * 0.01)

func save_game():
	# Összegyűjtjük az összes fontos adatot
	var save_data = {
	"player_hp": player_hp,
	"player_max_hp": player_max_hp,
	"player_regen": player_regen,
	"current_zone_index": current_zone_index,
	"slime_crystals": slime_crystals,
	"special_crystals": special_crystals,

		#Felszerelések fejlesztéseinek mentése (ha léteznek a változók az ItemData-ban)
		"equipment_upgrades": {
			"weapon": {
				"tier": weapon.tier if "tier" in weapon else 0,
				"level": weapon.level if "level" in weapon else 1,
				"power": weapon.power if "power" in weapon else 1,
				"tierup_cost": weapon.tierup_cost if "tierup_cost" in weapon else 8,
				"levelup_cost": weapon.levelup_cost if "levelup_cost" in weapon else 20
			},
			"helmet": {
				"tier": helmet.tier if "tier" in helmet else 0,
				"level": helmet.level if "level" in helmet else 1,
				"power": helmet.power if "power" in helmet else 0.5,
				"tierup_cost": helmet.tierup_cost if "tierup_cost" in helmet else 5,
				"levelup_cost": helmet.levelup_cost if "levelup_cost" in helmet else 10
			},
			"chestpiece": {
				"tier": chestpiece.tier if "tier" in chestpiece else 0,
				"level": chestpiece.level if "level" in chestpiece else 1,
				"power": chestpiece.power if "power" in chestpiece else 1,
				"tierup_cost": chestpiece.tierup_cost if "tierup_cost" in chestpiece else 10,
				"levelup_cost": chestpiece.levelup_cost if "levelup_cost" in chestpiece else 15
			},
			"leggings": {
				"tier": leggings.tier if "tier" in leggings else 0,
				"level": leggings.level if "level" in leggings else 1,
				"power": leggings.power if "power" in leggings else 0.5,
				"tierup_cost": leggings.tierup_cost if "tierup_cost" in leggings else 8,
				"levelup_cost": leggings.levelup_cost if "levelup_cost" in leggings else 10
			}
		}
	}

	# Fájl megnyitása írásra
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data)
		file.store_line(json_string)
		file.close()
		print("[Save System] Játék sikeresen mentve ide: ", SAVE_PATH)
	else:
		print("[Save System] Hiba történt a mentési fájl létrehozásakor!")

func load_game() -> bool:
	var json_string
	# Ha nincs még mentésünk, nem csinálunk semmit
	if not FileAccess.file_exists(SAVE_PATH):
		print("[Save System] Nincs korábbi mentés. Új játék indul.")
		update_luck() # Biztonsági luck frissítés az alapértékekhez
		return false

	# Fájl megnyitása olvasásra
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		json_string = file.get_as_text()
		file.close()
	
	# JSON szöveg visszaalakítása adatokká
	var save_data = JSON.parse_string(json_string)
	if save_data == null:
		print("[Save System] Hiba! A mentési fájl sérült vagy hibás formátumú.")
		return false
		
	# Alapvető adatok betöltése
	slime_crystals = save_data.get("slime_crystals", 0)
	special_crystals = save_data.get("special_crystals", 0)
	current_zone_index = save_data.get("current_zone_index", 0)
	player_hp = save_data.get("player_hp", player_max_hp)
	player_max_hp = save_data.get("player_max_hp", player_max_hp)
	player_regen = save_data.get("player_regen", player_regen)
	
	# Zóna visszaállítása
	if current_zone_index >= 0 and current_zone_index < zones.size():
		current_zone = get_zone_resource(current_zone_index)
		
	# Felszerelések szintjeinek visszaállítása
	if "equipment_upgrades" in save_data:
		var upgrades = save_data["equipment_upgrades"]
		
		if "weapon" in upgrades:
			if "tier" in weapon: weapon.tier = upgrades["weapon"].get("tier", 0)
			if "level" in weapon: weapon.level = upgrades["weapon"].get("level", 1)
			if "power" in weapon: weapon.power = upgrades["weapon"].get("power", 1)
			if "tierup_cost" in weapon: weapon.tierup_cost = upgrades["weapon"].get("tierup_cost", 8)
			if "levelup_cost" in weapon: weapon.levelup_cost = upgrades["weapon"].get("levelup_cost", 20)
			
		if "helmet" in upgrades:
			if "tier" in helmet: helmet.tier = upgrades["helmet"].get("tier", 0)
			if "level" in helmet: helmet.level = upgrades["helmet"].get("level", 1)
			if "power" in helmet: helmet.power = upgrades["helmet"].get("power", 0.5)
			if "tierup_cost" in helmet: helmet.tierup_cost = upgrades["helmet"].get("tierup_cost", 5)
			if "levelup_cost" in helmet: helmet.levelup_cost = upgrades["helmet"].get("levelup_cost", 10)
			
		if "chestpiece" in upgrades:
			if "tier" in chestpiece: chestpiece.tier = upgrades["chestpiece"].get("tier", 0)
			if "level" in chestpiece: chestpiece.level = upgrades["chestpiece"].get("level", 1)
			if "power" in chestpiece: chestpiece.power = upgrades["chestpiece"].get("power", 1)
			if "tierup_cost" in chestpiece: chestpiece.tierup_cost = upgrades["chestpiece"].get("tierup_cost", 10)
			if "levelup_cost" in chestpiece: chestpiece.levelup_cost = upgrades["chestpiece"].get("levelup_cost", 15)
			
		if "leggings" in upgrades:
			if "tier" in leggings: leggings.tier = upgrades["leggings"].get("tier", 0)
			if "level" in leggings: leggings.level = upgrades["leggings"].get("level", 1)
			if "power" in leggings: leggings.power = upgrades["leggings"].get("power", 0.5)
			if "tierup_cost" in leggings: leggings.tierup_cost = upgrades["leggings"].get("tierup_cost", 8)
			if "levelup_cost" in leggings: leggings.levelup_cost = upgrades["leggings"].get("levelup_cost", 10)
	
	# Luck újraszámolása
	update_luck()
	
	print("[Save System] Játék sikeresen betöltve!")
	return true
	

func _on_save_button_pressed() -> void:
	save_game()
