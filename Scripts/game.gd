extends Node2D

const POG = preload("res://Scenes/pog.tscn")
const DECK_POG = preload("res://Scenes/deck_pog.tscn")
const SLAMMER = preload("res://Scenes/slammer.tscn")

@onready var pogs: Node2D = $Pogs
@onready var stack: Node2D = $Stack
@onready var deck: Node2D = $Deck
@onready var slam_button: Button = $SlamButton

var stack_position = Vector2(600, 300)

func _ready():
	slam_button.hide()
	create_deck()
	
	#var pog_count = randi_range(1, 10)
	#stack.set_count(pog_count)
	#spawn_pogs(pog_count)

func create_deck():
	for i in range(10):
		var pog = DECK_POG.instantiate()
		pog.position = Vector2(261 + i * 70, 605)
		deck.add_child(pog)
		pog.selection_change.connect(update_slam_button)

func arrange_deck():
	var spacing = 50
	var pog_count = deck.get_child_count()
	var deck_width = (pog_count - 1) * spacing
	var start_x = (1152 - deck_width) / 2
	
	for i in range(pog_count):
		var pog = deck.get_child(i)
		var tween = create_tween()
		tween.tween_property(pog, "position", Vector2(start_x + i * spacing, 580), .2)

func spawn_slammer():
	var slammer = SLAMMER.instantiate()
	
	add_child(slammer)
	slammer.position = Vector2(576, -120)
	
	var tween = create_tween()
	
	tween.tween_property(slammer, "position", Vector2(576, 140), .4)

func move_selected_to_stack(selected):
	var center = stack_position
	
	for pog in selected:
		var tween = create_tween()
		
		tween.parallel().tween_property(pog, "global_position", center, .25)
		tween.parallel().tween_property(pog, "scale", Vector2(.3, .3), .25)
	await get_tree().create_timer(.25).timeout

func update_slam_button():
	var selected = 0
	
	for pog in deck.get_children():
		if pog.selected:
			selected += 1
	if selected > 0:
		slam_button.show()
	else:
		slam_button.hide()

func spawn_pogs(pog_count, slam_position):
	for i in range(pog_count):
		var pog = POG.instantiate()
		
		var offset = Vector2(randf_range(-3, 3), randf_range(-3, 3))
		pog.position = stack_position + offset
		
		var direction = (pog.position - slam_position).normalized()
		direction = direction.rotated(randf_range(-0.5, 0.5))
		
		var force = direction * randf_range(80, 350)
		pog.rotation_degrees = randf_range(0, 360)
		
		pogs.add_child(pog)
		pog.apply_central_impulse(force)
		
		var chance = 1.0 - (float(i) / pog_count)
		if randf() < chance:
			pog.angular_velocity = randf_range(-12, 12)
			pog.start()
		else:
			pog.angular_velocity = randf_range(-4, 4)

func _on_slam_button_pressed():
	var selected = []
	
	for pog in deck.get_children():
		if pog.selected:
			selected.append(pog)
	await move_selected_to_stack(selected)
	
	var selected_count = selected.size()
	
	for pog in selected:
		pog.queue_free()
	await get_tree().process_frame
	arrange_deck()
	stack.set_count(selected_count)
	stack.show()
	spawn_slammer()
	slam_button.hide()
