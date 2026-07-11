extends Node2D

@onready var count: Label = $Count

var pog_count = 0
var hit = false

func _ready():
	update_count()

func update_count():
	count.text = "x" + str(pog_count)

func set_count(value):
	pog_count = value
	update_count()

func remove_stack():
	hide()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if hit:
		return
	
	if area.name == "Hitbox":
		hit = true
		hide()
		get_parent().call_deferred("spawn_pogs", pog_count)
