extends Control

@export_file("*.tscn") var primer_nivel: String = "res://scenes/levels/nivel_tutorial.tscn"

@onready var _boton_jugar: Button = $Botones/BotonJugar
@onready var _boton_salir: Button = $Botones/BotonSalir

func _ready() -> void:
	_boton_jugar.pressed.connect(_on_jugar_pressed)
	_boton_salir.pressed.connect(_on_salir_pressed)
	_boton_jugar.grab_focus()
	if OS.has_feature("web"):
		_boton_salir.hide()

func _on_jugar_pressed() -> void:
	var err := get_tree().change_scene_to_file(primer_nivel)
	if err != OK:
		push_error("No se pudo cargar '%s' (error %d)" % [primer_nivel, err])

func _on_salir_pressed() -> void:
	get_tree().quit()
