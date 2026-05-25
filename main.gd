extends Node2D


@onready var slime_node = %Slime 
@onready var slime_sprite = %Slime/SlimeSprite
@onready var slime_label = %SlimeLabel
@onready var slime_hp_bar = %SlimeHealthBar
@onready var slime_hp_label = %SlimeHPLabel
@onready var slime_attack_bar = %SlimeAttackBar

@onready var crystal_label = %CrystalLabel
@onready var special_label = %SpecialCrystalLabel

@onready var pause_button = %PauseButton

@onready var player_health_bar = %PlayerHealthBar
@onready var player_health_label = %PlayerHPLabel
@onready var stats_label = %StatsLabel

@onready var zone_prev_button = %ZPrevButton
@onready var zone_name = %ZoneName
@onready var zone_next_button = %ZNextButton
@onready var background = %Background
@onready var info_popup = %InfoPopup

var current_slime_maxhp: float = 0
var current_slime_hp: float = 0
var current_slime_atkspeed: float = 1.8
var current_slime_data: SlimeData
var can_attack: bool = false
var slime_dead: bool = false

func _ready():
	# Start the game with a slime from the current zone
	spawn_new_slime()
	pause_button.pressed.connect(_on_pause_button_pressed)
	instantiate_player_ui()
	update_ui()
	update_zone_ui()

func update_ui():
	# 1. Update Crystals
	crystal_label.text = "Crystals: %d" % GameData.slime_crystals
	special_label.text = "Special: %d" % GameData.special_crystals
	
	# 2. Update Stats Sidebar
	stats_label.text = "Player Stats:\nATK: %.1f\nDEF: %.1f\nLUCK: %.1f\nREGEN: %.2f/s" % [
		GameData.get_attack(),
		GameData.get_defense(),
		GameData.luck,
		GameData.player_regen
	]
	
	slime_label.text = "Slime: %s" % current_slime_data.name
	background.texture = GameData.current_zone.background #background change if next area was chosen

func spawn_new_slime():
	var zone = GameData.current_zone
	
	# 1. Random slime
	var random_index = randi() % zone.possible_slimes.size()
	current_slime_data = zone.possible_slimes[random_index]
	if (current_slime_data.hasSpecialDrop):
		var roll = randf() #25 luck fölött ad luckonként +1% esélyt hogy láda LEHET
		if (roll) <= (0.25 + max(GameData.luck - 25, 0) / 100):
			GameData.current_slime = current_slime_data
		else:
			spawn_new_slime()
			return
	
	# 2. Reset variables with slime data
	current_slime_maxhp = current_slime_data.health
	current_slime_hp = current_slime_maxhp
	current_slime_atkspeed = current_slime_data.attack_speed
	
	# 3. Update slime texture
	slime_sprite.texture = current_slime_data.texture
	
	# Reset Slime health bar
	slime_hp_bar.max_value = current_slime_data.health
	slime_hp_bar.min_value = 0
	slime_hp_bar.value = current_slime_hp
	
	slime_hp_label.text = str(current_slime_hp, "/", current_slime_maxhp)
	
	# Make sure the slime is visible again
	slime_node.visible = true
	slime_dead = false
	make_new_popup(str("New slime appeared: ", current_slime_data.name))
	start_slime_timer()
	update_ui()

func start_slime_timer():
	# Reset the attack bar
	slime_attack_bar.max_value = current_slime_data.attack_speed
	slime_attack_bar.min_value = 0
	slime_attack_bar.value = current_slime_data.attack_speed
	can_attack = true

# Slime takes damage
func take_damage(amount: int):
	if slime_dead:
		return
	current_slime_hp -= amount
	
	slime_hp_label.text = str(current_slime_hp, "/", current_slime_maxhp)
	slime_hp_bar.value = current_slime_hp
	
	show_damage_popup(amount)
	
	if current_slime_hp <= 0:
		slime_dead = true
		on_slime_defeated()
	update_ui()

func calculate_player_damage():
	var base_dmg = GameData.weapon.power

		# Divine (Tier 5) Effect: 1% Insta-kill
	if GameData.weapon.tier == 5:
		if randf() < 0.01:
			return 999999
				
	# Rare (Tier 2) Effect: +10% Crit
	if GameData.weapon.tier >= 2:
		if randf() < 0.10: # 10% chance
			make_new_popup(str("CRITICAL HIT!"))
			return base_dmg * 2
			
	return base_dmg

func show_damage_popup(amount: int):
	var base_popup = %Popup
	var popup = base_popup.duplicate()
	base_popup.get_parent().add_child(popup)
	
	popup.text = "-%d" % amount
	popup.modulate = Color.RED
	popup.position = get_global_mouse_position() - Vector2(popup.size)
	popup.scale = Vector2(2, 2)
	
	#Tweening
	var tween = create_tween()
	tween.tween_property(popup, "position", popup.position + Vector2(0, -50), 0.5)
	tween.parallel().tween_property(popup, "modulate:a", 0, 0.5)
	tween.finished.connect(popup.queue_free)

func on_slime_defeated():
	can_attack = false
	
	var tween = create_tween()
	tween.tween_property(%Slime, "scale", Vector2(0, 0), 0.5)
	
	await tween.finished
	
	slime_node.visible = false
	%Slime.scale = Vector2(1, 1)
	var crystals = randi_range(current_slime_data.crystal_drop_min, current_slime_data.crystal_drop_max)
	GameData.slime_crystals += crystals * GameData.current_zone.crystal_multiplier
	if current_slime_data.hasSpecialDrop:
		var spec_crystals = randi_range(current_slime_data.spec_crystal_drop_min, current_slime_data.spec_crystal_drop_max)
		GameData.special_crystals += spec_crystals
	
	await get_tree().create_timer(0.5).timeout
	spawn_new_slime()
	update_ui()
	
func slime_attack_player():
	var damage = current_slime_data.damage
	var defense = GameData.get_defense()
	
	var final_damage = max(1, damage - defense)
	GameData.player_hp -= final_damage
	
	if GameData.player_hp <= 0:
		player_died()
	
	player_health_label.text = str(snapped(GameData.player_hp, 0.01), "/", GameData.player_max_hp)
	player_health_bar.value = GameData.player_hp
	
	slime_attack_bar.value = slime_attack_bar.max_value
	
	print("Player took ", damage, " Points of damage")
	
func _on_pause_button_pressed():
	get_tree().paused = !get_tree().paused
	update_ui()
	
func instantiate_player_ui():
	player_health_bar.max_value = GameData.player_max_hp
	player_health_bar.min_value = 0
	player_health_bar.value = GameData.player_hp
	
	player_health_label.text = str(snapped(GameData.player_hp, 0.01), "/", GameData.player_max_hp)
	update_ui()

func _on_slime_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		take_damage(calculate_player_damage())

func change_zone(direction: int):
	# Update the index (0 for Plains, 1 for Forest, etc.)
	var new_index = GameData.current_zone_index + direction
	
	# Boundary check
	if new_index >= 0 and new_index < GameData.zones.size():
		GameData.current_zone_index = new_index
		GameData.current_zone = GameData.get_zone_resource(GameData.current_zone_index)
		
		# Background, ui update, new slime spawning
		update_ui()
		update_zone_ui()
		spawn_new_slime()
		
		make_new_popup(str("Entered: ", GameData.current_zone.zone_name))
		GameData.save_game()

func _on_z_prev_button_pressed() -> void:
	change_zone(-1)


func _on_z_next_button_pressed() -> void:
	var next_zone_index = GameData.current_zone_index + 1
	var nextZone = GameData.get_zone_resource(GameData.current_zone_index + 1)
	if next_zone_index >= 0 and next_zone_index < GameData.zones.size():
		if GameData.get_attack() >= nextZone.required_attack and GameData.get_defense() >= nextZone.required_defense:
			change_zone(1)
		else:
			make_new_popup(str("You need more power to enter ", nextZone.zone_name, "! \n(hover over button to see requirements)"))

func update_zone_ui():
	var previous_zone = GameData.get_zone_resource(GameData.current_zone_index - 1)
	var current_zone = GameData.get_zone_resource(GameData.current_zone_index)
	var next_zone = GameData.get_zone_resource(GameData.current_zone_index + 1)
	zone_name.text = "Zone: \n%s" % GameData.current_zone.zone_name
	
	if (previous_zone):
		zone_prev_button.text = "Previous Zone: (%s)" % previous_zone.zone_name
	else:
		zone_prev_button.text = "Previous Zone: (%s) \n(Lowest zone currently)" % current_zone.zone_name
	
	if (next_zone):
		zone_next_button.text = "Next Zone: (%s)" % next_zone.zone_name
		zone_next_button.tooltip_text = "Required attack: %d; defense: %d \nfor next area" % [next_zone.required_attack, next_zone.required_defense]
	else:
		zone_next_button.text = "Next Zone: (%s) \n(Max zone reached)" % current_zone.zone_name

func player_died():
	can_attack = false
	get_tree().paused = true

	#AcceptDialog létrehozás
	var death_popup = AcceptDialog.new()
	death_popup.title = "YOU DIED!"
	death_popup.dialog_text = "You'll go back to the first zone, however you lost all your crystals.. :C"
	death_popup.ok_button_text = "I accept my fate with pride!"

	death_popup.process_mode = Node.PROCESS_MODE_ALWAYS

	add_child(death_popup)
	death_popup.popup_centered()

	# Reseteljük a playert, acceptdialog törlés
	death_popup.confirmed.connect(func():
		_reset_after_death()
		death_popup.queue_free()
	)
	death_popup.canceled.connect(func():
		_reset_after_death()
		death_popup.queue_free()
	)

func _reset_after_death():
	# Értékek nullázása..
	GameData.slime_crystals = 0
	GameData.special_crystals = 0
	GameData.player_hp = GameData.player_max_hp

	# Kezdő zónába vissza
	GameData.current_zone_index = 0
	GameData.current_zone = GameData.get_zone_resource(GameData.current_zone_index)
	
	#UI updatelése a megfelelő dolgok kiírására
	update_ui()
	update_zone_ui()

	# Játék folytatása, slime spawnolás
	get_tree().paused = false
	spawn_new_slime()
	GameData.save_game()
	make_new_popup("You have been respawned!")
	
func make_new_popup(newText):
	var new_info_popup = info_popup.duplicate()
	
	info_popup.get_parent().add_child(new_info_popup)
	new_info_popup.text = str(newText)
	new_info_popup.modulate = Color.CHOCOLATE
	
	var tween = create_tween()
	tween.tween_property(new_info_popup, "position", new_info_popup.position + Vector2(0, -75), 3.5)
	tween.parallel()
	tween.finished.connect(new_info_popup.queue_free)

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	
	GameData.player_hp += GameData.player_regen * delta
	
	if GameData.player_hp > GameData.player_max_hp:
		GameData.player_hp = GameData.player_max_hp
	
	player_health_label.text = str(snapped(GameData.player_hp, 0.01), "/", GameData.player_max_hp)
	player_health_bar.value = GameData.player_hp
	
	#Slime attack logic
	# paused or there's no slime?
	if not can_attack:
		return
	
	slime_attack_bar.value -= delta
	if slime_attack_bar.value <= 0:
		slime_attack_player()
