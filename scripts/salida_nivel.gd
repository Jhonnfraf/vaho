extends Area2D
@export_file("*.tscn") var siguiente_nivel: String = ""

var _activada := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _activada or not body.is_in_group("jugador"):
		return
	_activada = true
	if siguiente_nivel.is_empty():
		print("Fin del último nivel")
		return
	get_tree().change_scene_to_file.call_deferred(siguiente_nivel)
