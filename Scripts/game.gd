extends Node2D

const POG = preload("res://Scenes/pog.tscn")

@onready var pogs: Node2D = $Pogs
@onready var stack: Node2D = $Stack

var stack_position = Vector2(600, 300)

func _ready():
	var pog_count = randi_range(2, 10)
	stack.set_count(pog_count)
	#spawn_pogs(pog_count)

func spawn_pogs(pog_count):
	for i in range(pog_count):
		var pog = POG.instantiate()
		var force = Vector2(randf_range(-250, 250), randf_range(-250, 250))
		var offset = Vector2(randf_range(-3, 3), randf_range(-3, 3))
		
		pog.position = stack_position + offset
		pog.rotation_degrees = randf_range(0, 360)
		
		pogs.add_child(pog)
		
		pog.apply_central_impulse(force)
		pog.angular_velocity = randf_range(-8, 8)
		
		if randf() < .4:
			pog.flip()
