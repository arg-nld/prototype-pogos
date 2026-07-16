extends Node2D

const POG = preload("res://Scenes/pog.tscn")
const DECK_POG = preload("res://Scenes/deck_pog.tscn")
const SLAMMER = preload("res://Scenes/slammer.tscn")

@onready var pogs: Node2D = $Pogs
@onready var stack: Node2D = $Stack
@onready var player_deck: Node2D = $PlayerDeck
@onready var enemy_deck: Node2D = $EnemyDeck
@onready var slam_button: Button = $SlamButton

var active_pogs: Array = []

var stack_position = Vector2(600, 300)
var can_select = true
var slamming = false

func _ready():
	slam_button.hide()
	create_deck(player_deck, 580)
	create_deck(enemy_deck, 70)
	
	#var pog_count = randi_range(1, 10)
	#stack.set_count(pog_count)
	#spawn_pogs(pog_count)

func create_deck(deck, y_pos):
	var spacing = 50
	var pog_count = 10
	var deck_width = (pog_count - 1) * spacing
	var start_x = (1152 - deck_width) / 2
	
	for i in range(pog_count):
		var pog = DECK_POG.instantiate()
		pog.position = Vector2(start_x + i * spacing, y_pos)
		deck.add_child(pog)
		
		if deck == player_deck:
			pog.selection_change.connect(update_slam_button)
		else:
			pog.selectable = false

func arrange_deck(deck, y_pos):
	var spacing = 50
	var pog_count = deck.get_child_count()
	var deck_width = (pog_count - 1) * spacing
	var start_x = (1152 - deck_width) / 2
	
	for i in range(pog_count):
		var pog = deck.get_child(i)
		var new_pos = Vector2(start_x + i * spacing, y_pos)
		
		var tween = create_tween()
		tween.tween_property(pog, "position", new_pos, .2)
		
		pog.start_position = new_pos
		pog.selected = false

func spawn_slammer():
	var slammer = SLAMMER.instantiate()
	add_child(slammer)
	
	slammer.position = Vector2(350, 500)
	
	var tween = create_tween()
	tween.tween_property(slammer, "position", Vector2(420, 430), 0.4)

func move_selected_to_stack(selected):
	for deck_pog in selected:
		var pog = POG.instantiate()
		pog.position = stack_position
		pog.rotation_degrees = randf_range(0, 360)
		pogs.add_child(pog)
		active_pogs.append(pog)
		
		var tween = create_tween()
		tween.parallel().tween_property(deck_pog, "global_position", stack_position, .25)
		tween.parallel().tween_property(deck_pog, "scale", Vector2(.3, .3), .25)
		await tween.finished
		deck_pog.queue_free()
		restack_pogs(active_pogs)
		
	await get_tree().create_timer(.1).timeout

func update_slam_button():
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
		restack_pogs(remaining_pogs)
		slamming = false
		spawn_slammer()

func end_round():
	active_pogs.clear()
	can_select = true
	slamming = false
	
	for pog in player_deck.get_children():
		pog.selectable = true
	slam_button.hide()
	stack.hide()

func move_won_pogs(won_pogs):
	for pog in won_pogs:
		var tween = create_tween()
		tween.tween_property(pog, "global_position", Vector2(576, 580), .4)
		tween.parallel().tween_property(pog, "scale", Vector2(.3, .3), .4)
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
	for i in range(remaining_pogs.size()):
		var pog = remaining_pogs[i]
		var tween = create_tween()
		
		pog.freeze = true
		var offset = Vector2(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3))
		tween.tween_property(pog, "global_position", stack_position + offset, 0.4)
		pog.rotation_degrees = randf_range(0, 360)
		pog.linear_velocity = Vector2.ZERO
		pog.angular_velocity = 0
		pog.z_index = i
	active_pogs = remaining_pogs
	stack.global_position = stack_position
	stack.set_count(remaining_pogs.size())

func spawn_pogs(pog_count, slam_position):
	for i in range(active_pogs.size()):
		var pog = active_pogs[i]
		var direction = (pog.position - slam_position).normalized()
		direction = direction.rotated(randf_range(-0.5, 0.5))
		
		var force = direction * randf_range(80, 350)
		pog.freeze = false
		pog.apply_central_impulse(force)
		
		var chance = 1.0 - float(i) / active_pogs.size()
		if randf() < chance:
			pog.angular_velocity = randf_range(-12, 12)
			pog.start()
		else:
			pog.angular_velocity = randf_range(-4, 4)

	await get_tree().create_timer(2.0).timeout
	await check_results()

func _on_slam_button_pressed():
	if slamming:
		return
	slamming = true
	slam_button.disabled = true
	
	var selected = []
	can_select = false
	
	for pog in player_deck.get_children():
		pog.selectable = false
	
	for pog in player_deck.get_children():
		if pog.selected:
			selected.append(pog)
	await move_selected_to_stack(selected)
	
	await get_tree().process_frame
	arrange_deck(player_deck, 580)
	stack.set_count(active_pogs.size())
	stack.show()
	spawn_slammer()
	slam_button.hide()
	slam_button.disabled = true

func start_next_turn():
	slamming = false
