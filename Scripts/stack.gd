extends Node2D

@onready var top_pog: Sprite2D = $"Top Pog"
@onready var count: Label = $Count

var pog_count = 0
var hit = false

func _ready():
	set_count(0)
	hide()

func update_count():
	count.text = "x" + str(pog_count)

func set_count(value):
	pog_count = value
	hit = false
	
	if pog_count <= 0:
		count.hide()
		hide()
	else:
		top_pog.show()
		count.show()
		show()
	update_count()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if hit:
		return
	if area.name != "Hitbox":
		return
	
	hit = true
	var slam_position = area.global_position
	area.get_parent().queue_free()
	hide()
	var game = get_parent()
	game.call_deferred("spawn_pogs", pog_count, slam_position)
	game.call_deferred("start_next_turn")
