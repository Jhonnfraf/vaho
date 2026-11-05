extends Control

@export_file("*.tscn") var menu: String = "res://scenes/levels/menu_inicio.tscn"

@onready var _boton_menu: Button = $Botones/BotonMenu
@onready var _boton_salir: Button = $Botones/BotonSalir

func _ready() -> void:
	_boton_menu.pressed.connect(_on_menu_pressed)
	_boton_salir.pressed.connect(_on_salir_pressed)
	_boton_menu.grab_focus()
	if OS.has_feature("web"):
		_boton_salir.hide()

func _on_menu_pressed() -> void:
	var err := get_tree().change_scene_to_file(menu)
	if err != OK:
		push_error("No se pudo cargar '%s' (error %d)" % [menu, err])

func _on_salir_pressed() -> void:
	get_tree().quit()
