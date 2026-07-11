extends Node2D

@onready var count: Label = $Count

var pog_count = 0

func _ready():
	update_count()

func update_count():
	count.text = "x" + str(pog_count)

func set_count(value):
	pog_count = value
	update_count()

func remove_stack():
	hide()
