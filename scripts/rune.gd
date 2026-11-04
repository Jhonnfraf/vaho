class_name Rune
extends CharacterBody2D

enum _state {
	FLYING,
	PUSHED,
	EMBEDDED,
	RETURNING
}

signal commited
signal landed(collider : Node2D)
signal returned

@export var push_speed : float = 1900.0
@export var return_speed : float = 1700.0
@export var guide_solid_lengt : float = 500.0
@export var guide_faded_lengt : float = 900.0
@export var spin_speed_degrees : float = 360.0
@export var arrival_distance: float = 20.0

@export var base_damage : float

@onready var sprite : Sprite2D = $Sprite2D

var state: int = _state.FLYING
var thrower: Node2D = null #nosotros somos el personaje que tira el objeto
var _return_target : Node2D = null #Se refiere al personaje
var _marked_enemy : Node2D = null #Nos referimos al enemigo marcado
var _nivel_marca : int = 0  #Marca del enemigo, entre mas nivel mas fuerte pega lv(1, 3)
var _gravity : float = ProjectSettings.get_setting("physics/2d/default_gravity")


@onready var guide_solid : Line2D = $GuideLineSolid
@onready var guide_faded : Line2D = $GuideLineFaded

func _ready() -> void:
	pass
	
func launch(who_threw_it : Node2D, initial_velocity : Vector2, damage : float) -> void:
	thrower = who_threw_it
	velocity = initial_velocity
	base_damage = damage
	state = _state.FLYING
	add_collision_exception_with(thrower)
	
func push(direction : Vector2) -> void:
	if state != _state.FLYING:
		return
	velocity = direction.normalized()* push_speed
	state = _state.PUSHED
	_clear_guide_line()
	commited.emit()
	
func recall(target : Node2D) -> void:
	if state == _state.PUSHED or state == _state.RETURNING:
		return
	if is_instance_valid(_marked_enemy):
		_marked_enemy.quitar_marca(self)
		_marked_enemy = null
		
	var was_flying := state == _state.FLYING
	_return_target = target
	state = _state.RETURNING
	if was_flying:
		commited.emit()

func detonar(target : Node2D) -> void:
	if state == _state.PUSHED or state == _state.RETURNING:
		return
	_marked_enemy = null
	var was_flying := state == _state.FLYING
	_return_target = target
	state = _state.RETURNING
	if was_flying:
		commited.emit()
	

func _physics_process(delta: float) -> void:
	if state == _state.FLYING or state == _state.PUSHED:
		sprite.rotation += deg_to_rad(spin_speed_degrees) * delta
	match state:
		_state.FLYING, _state.PUSHED:
			
			velocity.y += _gravity * delta
			var collition := move_and_collide(velocity*delta)
			if collition:
				_on_impact(collition)
			elif state == _state.FLYING:
				_update_guide_line()
		_state.RETURNING:
			_move_toward_target(delta)
			sprite.rotation += deg_to_rad(spin_speed_degrees) * delta
		_state.EMBEDDED:
			return
			
				

func _on_impact(collision : KinematicCollision2D) -> void:
	var was_flying := state == _state.FLYING
	var impact_speed := velocity.length()
	
	state = _state.EMBEDDED
	velocity  = Vector2.ZERO
	_clear_guide_line()
	
	var colider := collision.get_collider()
	if colider.has_method("marcar"):
		colider.marcar(self, impact_speed)
		_marked_enemy = colider
	
	
	landed.emit(collision.get_collider())
	if was_flying:
		commited.emit()

func _move_toward_target(delta: float) -> void:
	if not is_instance_valid(_return_target):
		queue_free()
		return
	var to_target := _return_target.global_position - global_position
	if to_target.length() <= arrival_distance:
		returned.emit()
		return
	global_position += to_target.normalized() * return_speed * delta
	

func _update_guide_line() -> void:
	if not is_instance_valid(thrower):
		return
	var direction := global_position - thrower.global_position
	if direction.length_squared() < 0.01:
		return
	direction = direction.normalized()
	guide_solid.points = [Vector2.ZERO, direction * guide_solid_lengt]
	guide_faded.points = [
		direction * guide_solid_lengt,
		direction * (guide_solid_lengt + guide_faded_lengt),
	]
		
func _clear_guide_line() -> void:
	guide_solid.points = []
	guide_faded.points = []
