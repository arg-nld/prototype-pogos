extends Node2D

const POG = preload("res://Scenes/pog.tscn")

@onready var pogs: Node2D = $Pogs
@onready var stack: Node2D = $Stack

var stack_position = Vector2(600, 300)

func _ready():
	var pog_count = randi_range(1, 10)
	stack.set_count(pog_count)
	#spawn_pogs(pog_count)

func spawn_pogs(pog_count):
	for i in range(pog_count):
		var pog = POG.instantiate()
		var x = randf_range(-5, 5)
		var y = randf_range(-5, 5)
		
		pog.position = stack_position + Vector2(x, y)
		pog.rotation_degrees = randf_range(0, 360)
		pog.z_index = i
		
		pogs.add_child(pog)
