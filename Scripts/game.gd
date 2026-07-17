#dont forget to make bar Area2D Zones / the current one is placeholder only retard - Past andrei to future andrei

extends Node2D

const POG = preload("res://Scenes/pog.tscn")
const DECK_POG = preload("res://Scenes/deck_pog.tscn")
const SLAMMER = preload("res://Scenes/slammer.tscn")
const TIMING_BAR = preload("res://Scenes/timing_bar.tscn")

@onready var pogs: Node2D = $Pogs
@onready var stack: Node2D = $Stack
@onready var player_deck: Node2D = $PlayerDeck
@onready var enemy_deck: Node2D = $EnemyDeck
@onready var slam_button: Button = $SlamButton

# Multiplier driven by the timing bar minigame
var slam_power := 1.0

var active_timing_bar: Node2D = null
var active_slammer: Node2D = null
var slammer_position := Vector2.ZERO
var timing_bar_position := Vector2(576, 300)

var active_pogs: Array = []

var stack_position = Vector2(600, 300)
var can_select = true
var slamming = false


func _ready():
	slam_button.hide()
	
	# Initialize initial layouts
	create_deck(player_deck, 580)
	create_deck(enemy_deck, 70)


func create_deck(deck, y_pos):
	# Centers the deck horizontally based on a fixed screen width of 1152
	var spacing = 50
	var pog_count = 10
	var deck_width = (pog_count - 1) * spacing
	var start_x = (1152 - deck_width) / 2.0
	
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
	var deck_width = (pog_count - 1) * spacing
	var start_x = (1152 - deck_width) / 2.0
	
	for i in range(pog_count):
		var pog = deck.get_child(i)
		var new_pos = Vector2(start_x + i * spacing, y_pos)
		
		var tween = create_tween()
		tween.tween_property(pog, "position", new_pos, 0.2)
		
		pog.start_position = new_pos
		pog.selected = false


func spawn_slammer():
	var slammer = SLAMMER.instantiate()
	add_child(slammer)
	
	slammer.position = Vector2(350, 500)
	
	# Dramatic entrance before the minigame starts
	var tween = create_tween()
	tween.tween_property(slammer, "position", Vector2(420, 430), 0.4)
	await tween.finished
	
	slammer_position = slammer.position
	active_slammer = slammer
	
	start_timing_bar()


func start_timing_bar():
	active_timing_bar = TIMING_BAR.instantiate()
	add_child(active_timing_bar)
	
	active_timing_bar.position = timing_bar_position
	active_timing_bar.slam_finished.connect(_on_timing_bar_slam_finished)


func _on_timing_bar_slam_finished(result: Dictionary):
	# Cache the outcome to drive the physics impulse later
	slam_power = result.power
	print("Slam rating: %s (power %.2f)" % [result.rating, result.power])
	
	active_timing_bar.queue_free()
	active_timing_bar = null
	
	await animate_slammer_hit()
	
	if active_slammer:
		active_slammer.queue_free()
		active_slammer = null
	
	# Trigger the physics explosion based on the slammer's final resting place
	spawn_pogs(active_pogs.size(), slammer_position)


func animate_slammer_hit():
	if active_slammer == null:
		return
	
	var impact_pos = stack_position
	var original_scale = active_slammer.scale
	
	# Scale the visual impact squash to match the minigame performance
	var squash_amount = lerp(0.08, 0.28, slam_power)
	
	# 1. Swing down
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(active_slammer, "position", impact_pos, 0.1)
	
	await tween.finished
	
	# 2. Impact squash (Conservation of Volume: wide and flat)
	var squash_tween = create_tween()
	squash_tween.set_trans(Tween.TRANS_QUAD)
	squash_tween.set_ease(Tween.EASE_OUT)
	squash_tween.tween_property(
		active_slammer, 
		"scale", 
		original_scale * Vector2(1.0 + squash_amount, 1.0 - squash_amount), 
		0.05
	)
	
	await squash_tween.finished
	
	# 3. Recoil / Fade out to clear the view for the physics simulation
	var recoil = create_tween()
	recoil.set_trans(Tween.TRANS_BACK)
	recoil.set_ease(Tween.EASE_OUT)
	recoil.tween_property(active_slammer, "scale", original_scale, 0.1)
	recoil.parallel().tween_property(active_slammer, "position", impact_pos + Vector2(0, -30), 0.18)
	recoil.parallel().tween_property(active_slammer, "modulate:a", 0.0, 0.18)
	
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
			
	await move_won_pogs(won_pogs)
	
	if remaining_pogs.is_empty():
		end_round()
	else:
		# Set up for the next strike if pogs remain
		restack_pogs(remaining_pogs)
		slamming = false
		spawn_slammer()


func end_round():
	# Reset arena and UI state for the next turn
	active_pogs.clear()
	can_select = true
	slamming = false
	
	for pog in player_deck.get_children():
		pog.selectable = true
		
	slam_button.hide()
	stack.hide()


func move_won_pogs(won_pogs):
	# Transition winning physics bodies back into UI deck elements
	for pog in won_pogs:
		var tween = create_tween()
		tween.tween_property(pog, "global_position", Vector2(576, 580), 0.4)
		tween.parallel().tween_property(pog, "scale", Vector2(0.3, 0.3), 0.4)
		
		await tween.finished
		
		var new_pog = DECK_POG.instantiate()
		player_deck.add_child(new_pog)
		new_pog.position = Vector2(576, 580)
		new_pog.start_position = new_pog.position
		new_pog.selection_change.connect(update_slam_button)
		
		pog.queue_free()
		new_pog.selectable = false
		
		arrange_deck(player_deck, 580)


func restack_pogs(remaining_pogs):
	# Freeze physics and neatly pile remaining pogs at the center
	for i in range(remaining_pogs.size()):
		var pog = remaining_pogs[i]
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


func spawn_pogs(pog_count, slam_position):
	# Translates the slammer's impact into radial physics impulses
	for i in range(active_pogs.size()):
		var pog = active_pogs[i]
		
		# Calculate trajectory away from the impact point with slight randomization
		var direction = (pog.position - slam_position).normalized()
		direction = direction.rotated(randf_range(-0.5, 0.5))
		
		# Apply minigame power multiplier to the force
		var base_force = lerp(80.0, 350.0, slam_power)
		var random_force = randf_range(-20.0, 20.0)

		var force = direction * (base_force + random_force)
		pog.freeze = false
		pog.apply_central_impulse(force)
		
		# Higher pogs in the stack have a better chance to flip and gain angular velocity
		var chance = 1.0 - float(i) / active_pogs.size()
		if randf() < chance:
			pog.angular_velocity = randf_range(-12.0, 12.0)
			pog.start() # Assuming this triggers an internal flip animation/logic
		else:
			pog.angular_velocity = randf_range(-4.0, 4.0)

	# Wait for physics bodies to settle before evaluating the board state
	await get_tree().create_timer(2.0).timeout
	await check_results()


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
			
	await move_selected_to_stack(selected)
	
	#one frame to ensure deck tree handles reparenting/deletion cleanly
	await get_tree().process_frame
	
	arrange_deck(player_deck, 580)
	stack.set_count(active_pogs.size())
	stack.show()
	spawn_slammer()
	
	slam_button.hide()
	slam_button.disabled = true


func start_next_turn():
	slamming = false
