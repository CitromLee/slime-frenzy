extends Control

@onready var main_node = owner
#Weapon
@onready var w_label = %WeaponLabel
@onready var w_upg_label = %WeaponUpgLabel
@onready var w_tier_button = %WeaponTierUp
@onready var w_level_button = %WeaponLevelUp
var w = GameData.weapon

#Helmet
@onready var h_label = %HelmetLabel
@onready var h_upg_label = %HelmetUpgLabel
@onready var h_tier_button = %HelmetTierUp
@onready var h_level_button = %HelmetLevelUp
var h = GameData.helmet

#Chestpiece
@onready var c_label = %ChestpieceLabel
@onready var c_upg_label = %ChestpieceUpgLabel
@onready var c_tier_button = %ChestpieceTierUp
@onready var c_level_button = %ChestpieceLevelUp
var c = GameData.chestpiece

#Leggings
@onready var l_label = %LeggingsLabel
@onready var l_upg_label = %LeggingsUpgLabel
@onready var l_tier_button = %LeggingsTierUp
@onready var l_level_button = %LeggingsLevelUp
var l = GameData.leggings

func _ready():
	#Weapon
	w_tier_button.pressed.connect(_on_wpn_tierup_pressed)
	w_level_button.pressed.connect(_on_wpn_levelup_pressed)
	
	#Helmet
	h_tier_button.pressed.connect(_on_head_tierup_pressed)
	h_level_button.pressed.connect(_on_head_levelup_pressed)
	
	#Chestpiece
	c_tier_button.pressed.connect(_on_chest_tierup_pressed)
	c_level_button.pressed.connect(_on_chest_levelup_pressed)
	
	#Leggings
	l_tier_button.pressed.connect(_on_leg_tierup_pressed)
	l_level_button.pressed.connect(_on_leg_levelup_pressed)

var tier_names = ["Common", "Uncommon", "Rare", "Legendary", "Mythic", "Divine"]
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	w_label.text = "Weapon: Lv. %d (%s)" % [w.level, tier_names[w.tier]]
	w_upg_label.text = "Weapon Upgrade Requirements: Tier Up(special crystal): %d, Levelup(normal crystals): %s" % [w.tierup_cost, w.levelup_cost]
	h_label.text = "Helmet: Lv. %d (%s)" % [h.level, tier_names[h.tier]]
	h_upg_label.text = "Helmet Upgrade Requirements: Tier Up(special crystal): %d, Levelup(normal crystals): %s" % [h.tierup_cost, h.levelup_cost]
	c_label.text = "Chestpiece: Lv. %d (%s)" % [c.level, tier_names[c.tier]]
	c_upg_label.text = "Chestpiece Upgrade Requirements: Tier Up(special crystal): %d, Levelup(normal crystals): %s" % [c.tierup_cost, c.levelup_cost]
	l_label.text = "Leggings: Lv. %d (%s)" % [l.level, tier_names[l.tier]]
	l_upg_label.text = "Leggings Upgrade Requirements: Tier Up(special crystal): %d, Levelup(normal crystals): %s" % [l.tierup_cost, l.levelup_cost]
	
func _on_wpn_tierup_pressed():
	if w.tier + 1 <= 5:
		if GameData.special_crystals >= w.tierup_cost:
			GameData.special_crystals -= w.tierup_cost
			w.tierup_cost = round(w.tierup_cost * 2.1)
			w.tier += 1
			w.power += 10
			main_node.update_ui()
			GameData.save_game()
			owner.make_new_popup(str("Succesfully evolved weapon to Tier ", tier_names[w.tier]))

func _on_wpn_levelup_pressed():
	if w.level + 1 <= 100:
		if GameData.slime_crystals >= w.levelup_cost:
			GameData.slime_crystals -= w.levelup_cost
			w.levelup_cost = round(w.levelup_cost * 1.18)
			w.level += 1
			w.power += 1
			main_node.update_ui()
			GameData.save_game()
			owner.make_new_popup(str("Succesfully levelled up weapon to level ", GameData.weapon.level, " level"))

func _on_head_tierup_pressed():
	if h.tier + 1 <= 5:
		if GameData.special_crystals >= h.tierup_cost:
			GameData.special_crystals -= h.tierup_cost
			h.tierup_cost = round(h.tierup_cost * 2.1)
			h.tier += 1
			h.power += 5
			GameData.update_luck()
			main_node.update_ui()
			GameData.save_game()
			owner.make_new_popup(str("Succesfully evolved helmet to Tier ", tier_names[h.tier]))

func _on_head_levelup_pressed():
	if h.level + 1 <= 100:
		if GameData.slime_crystals >= h.levelup_cost:
			GameData.slime_crystals -= h.levelup_cost
			h.levelup_cost = round(h.levelup_cost * 1.18)
			h.level += 1
			h.power += 0.5
			GameData.update_luck()
			main_node.update_ui()
			GameData.save_game()
			owner.make_new_popup(str("Succesfully levelled up helmet to ", GameData.helmet.level, " level."))

func _on_chest_tierup_pressed():
	if c.tier + 1 <= 5:
		if GameData.special_crystals >= c.tierup_cost:
			GameData.special_crystals -= c.tierup_cost
			c.tierup_cost = round(c.tierup_cost * 2.1)
			c.tier += 1
			c.power += 5
			GameData.player_max_hp += 35
			GameData.player_hp += 35
			main_node.update_ui()
			GameData.save_game()
			owner.make_new_popup(str("Succesfully evolved chestpiece to Tier ", tier_names[c.tier]))

func _on_chest_levelup_pressed():
	if c.level + 1 <= 100:
		if GameData.slime_crystals >= c.levelup_cost:
			GameData.slime_crystals -= c.levelup_cost
			c.levelup_cost = round(c.levelup_cost * 1.18)
			c.level += 1
			c.power += 0.5
			GameData.player_max_hp += 10
			GameData.player_hp += 10
			main_node.update_ui()
			GameData.save_game()
			owner.make_new_popup(str("Succesfully levelled up chestpiece to ", GameData.chestpiece.level, " level"))

func _on_leg_tierup_pressed():
	if l.tier + 1 <= 5:
		if GameData.special_crystals >= l.tierup_cost:
			GameData.special_crystals -= l.tierup_cost
			l.tierup_cost = round(l.tierup_cost * 2.1)
			l.tier += 1
			l.power += 5
			GameData.player_regen += 0.5
			main_node.update_ui()
			GameData.save_game()
			owner.make_new_popup(str("Succesfully evolved leggings to Tier ", tier_names[l.tier]))

func _on_leg_levelup_pressed():
	if l.level + 1 <= 100:
		if GameData.slime_crystals >= l.levelup_cost:
			GameData.slime_crystals -= l.levelup_cost
			l.levelup_cost = round(l.levelup_cost * 1.18)
			l.level += 1
			l.power += 0.5
			GameData.player_regen += 0.01
			main_node.update_ui()
			GameData.save_game()
			owner.make_new_popup(str("Succesfully levelled up leggings to ", GameData.leggings.level, " level"))
