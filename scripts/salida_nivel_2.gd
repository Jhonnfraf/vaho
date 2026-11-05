extends Area2D

@export_file("*.tscn") var pantalla_fin: String = ""
@export var bloqueada := false

var _activada := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if bloqueada:
		visible = false
		monitoring = false

func abrir() -> void:
	visible = true
	set_deferred("monitoring", true)

func _on_body_entered(body: Node2D) -> void:
	if _activada or not body.is_in_group("jugador"):
		return
	_activada = true
	if pantalla_fin.is_empty():
		print("Fin del último nivel")
		return
	var err := get_tree().change_scene_to_file(pantalla_fin)
	
