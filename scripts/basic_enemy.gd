extends "res://scripts/enemy.gd"

@export var velocidad_persecucion: float = 90.0

var _objetivo: Node2D = null
var _gravity : float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	sprite.play("Idle")
	super._ready()
	_objetivo = get_tree().get_first_node_in_group("jugador")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity*delta
	
	var direccion := 0.0
	if not _muerto and not _en_hit and is_instance_valid(_objetivo):
		direccion = signf(_objetivo.global_position.x - global_position.x)
	
	velocity.x = direccion * velocidad_persecucion
	move_and_slide()
	
	if _muerto or _en_hit:
		return
	
	#_actualizar_animacion()
func _actualizar_animacion(direccion : float) -> void:
	if direccion != 0.0:
		sprite.flip_h = direccion < 0.0
		sprite.play("Walk")
	else:
		sprite.play("Idle")
