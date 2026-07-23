### Sabog na ko please lang gumana kana..... Sorry sa ibang comments medgo sabog.
## And btw error pag sobrang pogs yung pick mo kaysa enemy.
extends Node2D

const POG = preload("res://Scenes/pog.tscn")
const DECK_POG = preload("res://Scenes/deck_pog.tscn")
const SLAMMER = preload("res://Scenes/slammer.tscn")
const TIMING_BAR = preload("res://Scenes/timing_bar.tscn")

#Screen Size
const SCREEN_WIDTH = 1600
const SCREEN_HEIGHT = 900
const SCREEN_CENTER = Vector2(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)

#Deck Positions
const PLAYER_DECK_Y = 820
const ENEMY_DECK_Y = 80

#Center Position for Both Decks
const PLAYER_DECK_CENTER = Vector2(SCREEN_CENTER.x, PLAYER_DECK_Y)
const ENEMY_DECK_CENTER = Vector2(SCREEN_CENTER.x, ENEMY_DECK_Y)

@onready var pogs: Node2D = $Pogs
@onready var stack: Node2D = $Stack
@onready var player_deck: Node2D = $PlayerDeck
@onready var enemy_deck: Node2D = $EnemyDeck
@onready var slam_button: Button = $SlamButton

# Multiplier driven by the timing bar minigame
var slam_power := 1.0
var slam_rate := ""

var active_timing_bar: Node2D = null
var active_slammer: Node2D = null
var slammer_position := Vector2.ZERO
var timing_bar_position := SCREEN_CENTER

var active_pogs: Array = []

var player_turn = true
#Tracker only for last turn
var slam_owner := true

var stack_position := SCREEN_CENTER
var can_select = true
var slamming = false


func _ready():
	slam_button.hide()
	
	# Initialize initial layouts
	create_deck(player_deck, PLAYER_DECK_Y)
	create_deck(enemy_deck, ENEMY_DECK_Y)


func create_deck(deck, y_pos):
	# Centers the deck horizontally based on a fixed screen width of 1152
	var spacing = 50
	var pog_count = 10
	var start_x = SCREEN_WIDTH / 2.0 - ((pog_count - 1) * spacing) / 2.0
	
	for i in range(pog_count):
		var pog = DECK_POG.instantiate()
		pog.position = Vector2(start_x + i * spacing, y_pos)
		deck.add_child(pog)
		
		# Only the player's deck should drive UI interactions
		if deck == player_deck:
			pog.selection_change.connect(update_slam_button)
		else:
			pog.selectable = false


func arrange_deck(deck, y_pos):
	# Dynamically recalculates center and tweens pogs into place
	# Called after pogs are removed from the deck to fill in the gaps
	var spacing = 50
	var pog_count = deck.get_child_count()
	var start_x = SCREEN_WIDTH / 2.0 - ((pog_count - 1) * spacing) / 2.0
	
	for i in range(pog_count):
		var pog = deck.get_child(i)
		var new_pos = Vector2(start_x + i * spacing, y_pos)
		
		var tween = create_tween()
		tween.tween_property(pog, "position", new_pos, 0.2)
		
		pog.start_position = new_pos
		pog.selected = false


func spawn_slammer(player: bool):
	slam_owner = player
	var slammer = SLAMMER.instantiate()
	slammer.z_index = 100
	add_child(slammer)
	
	var start_position: Vector2
	var ready_position: Vector2
	
	if player:
		start_position = stack_position + Vector2(0, 500)
		ready_position = stack_position + Vector2(0, 160)
	else:
		start_position = stack_position + Vector2(0, -500)
		ready_position = stack_position + Vector2(0, -160)
	
	slammer.position = start_position
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		slammer,
		"position",
		ready_position,
		0.45
	)

	await tween.finished

	if !is_instance_valid(slammer):
		return

	active_slammer = slammer
	slammer_position = ready_position

	start_timing_bar(player)


func start_timing_bar(player: bool):
	active_timing_bar = TIMING_BAR.instantiate()
	add_child(active_timing_bar)
	
	active_timing_bar.position = timing_bar_position
	active_timing_bar.enemy_ai_turn = !player
	active_timing_bar.slam_finished.connect(_on_timing_bar_slam_finished)
	
	active_timing_bar.start()

func _on_timing_bar_slam_finished(result: Dictionary):
	# Cache the outcome to drive the physics impulse later
	slam_power = result.power
	slam_rate = result.rating
	print("Slam rating: %s (power %.2f)" % [result.rating, result.power])
	
	active_timing_bar.queue_free()
	active_timing_bar = null
	
	await animate_slammer_hit()
	
	if active_slammer:
		active_slammer.queue_free()
		active_slammer = null
	
	# Trigger the physics explosion based on the slammer's final resting place
	spawn_pogs(slammer_position)


func animate_slammer_hit():
	if active_slammer == null:
		return
	
	var impact_pos = stack_position
	var anticipation_pos = active_slammer.position + Vector2(0, -8)

	var original_scale = active_slammer.scale
	var stack_original_scale = stack.scale
	var stack_original_position = stack.position

	# Scale the visual impact squash to match the minigame performance
	var squash_amount = lerp(0.08, 0.28, slam_power)

	# -------------------------------------------------
	# 1. Anticipation (small lift)
	# -------------------------------------------------
	var anticipation = create_tween()
	anticipation.set_trans(Tween.TRANS_QUAD)
	anticipation.set_ease(Tween.EASE_OUT)

	anticipation.tween_property(
		active_slammer,
		"position",
		anticipation_pos,
		0.05
	)

	await anticipation.finished

	# -------------------------------------------------
	# 2. Fast Slam
	# -------------------------------------------------
	var slam = create_tween()
	slam.set_trans(Tween.TRANS_QUAD)
	slam.set_ease(Tween.EASE_IN)

	slam.tween_property(
		active_slammer,
		"position",
		impact_pos,
		0.05
	)

	await slam.finished

	# -------------------------------------------------
	# Stack impact reaction
	# -------------------------------------------------
	await animate_stack_impact()

	# -------------------------------------------------
	# 3. Impact Squash
	# -------------------------------------------------
	var squash_tween = create_tween()
	squash_tween.set_trans(Tween.TRANS_QUAD)
	squash_tween.set_ease(Tween.EASE_OUT)

	# Slammer squash
	squash_tween.parallel().tween_property(
		active_slammer,
		"scale",
		original_scale * Vector2(1.0 + squash_amount, 1.0 - squash_amount),
		0.05
	)

	# Stack squash
	squash_tween.parallel().tween_property(
		stack,
		"scale",
		stack_original_scale * Vector2(1.08, 0.92),
		0.05
	)

	# Stack pushed downward slightly
	squash_tween.parallel().tween_property(
		stack,
		"position",
		stack_original_position + Vector2(0, 4),
		0.05
	)

	await squash_tween.finished

	# Small hold to emphasize impact
	await get_tree().create_timer(0.04).timeout

	# -------------------------------------------------
	# 4. Recoil
	# -------------------------------------------------
	var recoil = create_tween()
	recoil.set_trans(Tween.TRANS_BACK)
	recoil.set_ease(Tween.EASE_OUT)

	# Slammer returns to normal size
	recoil.parallel().tween_property(
		active_slammer,
		"scale",
		original_scale,
		0.10
	)

	# Small upward bounce
	recoil.parallel().tween_property(
		active_slammer,
		"position",
		impact_pos + Vector2(0, -10),
		0.12
	)

	# Stack returns to normal
	recoil.parallel().tween_property(
		stack,
		"scale",
		stack_original_scale,
		0.12
	)

	recoil.parallel().tween_property(
		stack,
		"position",
		stack_original_position,
		0.12
	)

	# Fade the slammer
	recoil.parallel().tween_property(
		active_slammer,
		"modulate:a",
		0.0,
		0.18
	)

	await recoil.finished


func move_selected_to_stack(selected):
	# Transitions 2D UI pogs into RigidBody/physics pogs for the main arena
	for deck_pog in selected:
		var pog = POG.instantiate()
		pog.position = stack_position
		pog.rotation_degrees = randf_range(0, 360) # Add variance to the stack appearance
		pogs.add_child(pog)
		active_pogs.append(pog)
		
		# Animate the UI element moving into the arena before deleting it
		var tween = create_tween()
		tween.parallel().tween_property(deck_pog, "global_position", stack_position, 0.25)
		tween.parallel().tween_property(deck_pog, "scale", Vector2(0.3, 0.3), 0.25)
		
		await tween.finished
		deck_pog.queue_free()
		
		restack_pogs(active_pogs)
		
	# Brief buffer to let the visual stack settle
	await get_tree().create_timer(0.1).timeout

func move_enemy_to_stack(selected):
	# Transitions 2D UI pogs into RigidBody/physics pogs for the main arena
	for deck_pog in selected:
		var pog = POG.instantiate()
		pog.position = stack_position
		pog.rotation_degrees = randf_range(0, 360) # Add variance to the stack appearance
		pogs.add_child(pog)
		active_pogs.append(pog)
		
		# Animate the UI element moving into the arena before deleting it
		var tween = create_tween()
		tween.parallel().tween_property(deck_pog, "global_position", stack_position, 0.25)
		tween.parallel().tween_property(deck_pog, "scale", Vector2(0.3, 0.3), 0.25)
		
		await tween.finished
		deck_pog.queue_free()
		
		restack_pogs(active_pogs)
		
	# Brief buffer to let the visual stack settle
	await get_tree().create_timer(0.1).timeout

func enemy_match_stack(amount):
	# This is For Testing Only, This Only Matches The Player's Pogs InPlay
	var selected = []
	
	for i in range(amount):
		if enemy_deck.get_child_count() == 0:
			break
		selected.append(enemy_deck.get_child(i))
	await move_enemy_to_stack(selected)
	await get_tree().process_frame
	arrange_deck(enemy_deck, ENEMY_DECK_Y)

func update_slam_button():
	# UI State validation
	var selected = 0
	for pog in player_deck.get_children():
		if pog.selected:
			selected += 1
			
	if selected > 0:
		slam_button.show()
		slam_button.disabled = false
	else:
		slam_button.hide()


func check_results():
	# In standard rules, face-down means the player claims the pog
	var won_pogs = []
	var remaining_pogs = []
	
	for pog in active_pogs:
		if pog.face_up:
			remaining_pogs.append(pog)
		else:
			won_pogs.append(pog)
			
	await move_won_pogs(won_pogs, slam_owner)
	
	if remaining_pogs.is_empty():
		end_round()
	else:
		# Put the remaining pogs back into a neat stack
		restack_pogs(remaining_pogs)
		slamming = false
		player_turn = !player_turn
		
		if player_turn:
			await spawn_slammer(true)
		else:
			await enemy_turn()


func end_round():
	# Reset arena and UI state for the next turn
	active_pogs.clear()
	can_select = true
	slamming = false
	
	player_turn = true
	
	for pog in player_deck.get_children():
		pog.selectable = true
		
	slam_button.hide()
	stack.hide()


func move_won_pogs(won_pogs, player: bool):
	# Transition winning physics bodies back into UI deck elements
	# Return Won Pogs to the Winner's Deck
	var target_position: Vector2
	if player:
		target_position = PLAYER_DECK_CENTER
	else:
		target_position = ENEMY_DECK_CENTER
	
	for pog in won_pogs:
		var tween = create_tween()
		tween.tween_property(pog, "global_position", target_position, 0.4)
		tween.parallel().tween_property(pog, "scale", Vector2(0.3, 0.3), 0.4)
		
		await tween.finished
		
		var new_pog = DECK_POG.instantiate()
		if player:
			player_deck.add_child(new_pog)
			new_pog.position = PLAYER_DECK_CENTER
			new_pog.start_position = new_pog.position
			new_pog.selection_change.connect(update_slam_button)
			new_pog.selectable = false
			arrange_deck(player_deck, PLAYER_DECK_Y)
		else:
			enemy_deck.add_child(new_pog)
			new_pog.position = ENEMY_DECK_CENTER
			new_pog.start_position = new_pog.position
			new_pog.selectable = false
			arrange_deck(enemy_deck, ENEMY_DECK_Y)
		pog.queue_free()


func restack_pogs(remaining_pogs):
	# Freeze physics and neatly pile remaining pogs at the center
	for i in range(remaining_pogs.size()):
		var pog = remaining_pogs[i]
		pog.stack_depth = i
		pog.freeze = true
		
		# Micro-offset gives the stack a natural, slightly messy look
		var offset = Vector2(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3))
		var tween = create_tween()
		
		tween.tween_property(pog, "global_position", stack_position + offset, 0.4)
		pog.rotation_degrees = randf_range(0, 360)
		pog.linear_velocity = Vector2.ZERO
		pog.angular_velocity = 0
		pog.z_index = i # Ensure proper rendering hierarchy based on stack order
		
	active_pogs = remaining_pogs
	stack.global_position = stack_position
	stack.set_count(remaining_pogs.size())


func spawn_pogs(slam_position):
	# Simulate the slammer's impact as energy travelling through the stack
	var energy = get_energy()
	
	for pog in active_pogs:
		# Calculate trajectory away from the impact point with slight randomization
		var direction = (pog.position - slam_position).normalized()
		direction = direction.rotated(randf_range(-0.5, 0.5))
		
		# Apply minigame power multiplier to the force
		var base_force = lerp(80.0, 350.0, slam_power)
		var random_force = randf_range(-20.0, 20.0)

		pog.freeze = false
		pog.apply_central_impulse(direction * (base_force + random_force))
		
		# Higher pogs in the stack have a better chance to flip and gain angular velocity
		var resistance = 12.0
		resistance += randf_range(-2.0, 2.0)
		resistance += pog.stack_depth * 2.5

		if energy >= resistance:
			pog.angular_velocity = randf_range(-12, 12)
			pog.start()
			# Flipped pog passes some energy to the next
			energy -= resistance * .7
		else:
			pog.angular_velocity = randf_range(-4, 4)
			# Non-flipped pog absorbs most of the remaining energy
			energy -= resistance * .9
		energy = max(0.0, energy)

	# Wait for physics bodies to settle before evaluating the board state
	await get_tree().create_timer(2.0).timeout
	await check_results()


func get_energy() -> float:
	# Better timing = more energy transferred to stack =  more pogs will flip
	return lerp(30.0, 140.0, slam_power)


func _on_slam_button_pressed():
	# Lock down game state to prevent input spam during animations
	if slamming:
		return
		
	slamming = true
	slam_button.disabled = true
	can_select = false
	
	var selected = []
	
	for pog in player_deck.get_children():
		pog.selectable = false
		if pog.selected:
			selected.append(pog)
	var amount = selected.size()
	await move_selected_to_stack(selected)
	await enemy_match_stack(amount)
	#one frame to ensure deck tree handles reparenting/deletion cleanly
	await get_tree().process_frame
	
	arrange_deck(player_deck, PLAYER_DECK_Y)
	stack.set_count(active_pogs.size())
	stack.show()
	player_turn = true
	await spawn_slammer(true)
	
	slam_button.hide()
	slam_button.disabled = true

func animate_stack_impact():
	var pog_data = []

	# Save original transforms
	for pog in active_pogs:
		pog_data.append({
			"pog": pog,
			"scale": pog.scale,
			"position": pog.position
		})


	# Compress stack
	var squash = create_tween()
	squash.set_trans(Tween.TRANS_QUAD)
	squash.set_ease(Tween.EASE_OUT)


	for data in pog_data:
		var pog = data["pog"]

		squash.parallel().tween_property(
			pog,
			"scale",
			Vector2(1.12, 0.88),
			0.05
		)

		squash.parallel().tween_property(
			pog,
			"position",
			data["position"] + Vector2(0, 4),
			0.05
		)


	await squash.finished


	# Tiny hold
	await get_tree().create_timer(0.04).timeout


	# Spring back
	var rebound = create_tween()
	rebound.set_trans(Tween.TRANS_BACK)
	rebound.set_ease(Tween.EASE_OUT)


	for data in pog_data:
		var pog = data["pog"]

		rebound.parallel().tween_property(
			pog,
			"scale",
			data["scale"],
			0.12
		)

		rebound.parallel().tween_property(
			pog,
			"position",
			data["position"],
			0.12
		)

	await rebound.finished

func enemy_turn():
	# Enemy waits for 1 Second Before Slamming
	await get_tree().create_timer(1).timeout
	await spawn_slammer(false)
