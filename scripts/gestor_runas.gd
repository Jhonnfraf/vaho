class_name GestorRunas
extends Node

@export var runa_scene : PackedScene = preload("res://scenes/entities/rune.tscn")
@export var throw_speed : float = 750.0
@export var throw_direction : Vector2 = Vector2(1.0, -1)
@export var max_runas : int = 3
@export var base_damage_rune : float = 5.0

var runas_vailable: int = 0
var _active_runes : Array[Rune] = []
var _controllable_runa : Rune = null

func _ready() -> void:
	runas_vailable = max_runas

func try_throw(thrower: Node2D, facing_right: bool) -> void:
	if runas_vailable <= 0 or _controllable_runa != null:
		return
	
	runas_vailable -= 1
	var facing_sign := 1.0 if facing_right else -1.0
	
	var runa: Rune = runa_scene.instantiate()
	thrower.get_tree().current_scene.add_child(runa)
	runa.global_position = thrower.global_position + Vector2(facing_sign * 20.0, -12.0)
	
	var direction := Vector2(throw_direction.x * facing_sign, throw_direction.y).normalized()
	runa.launch(thrower, direction * throw_speed , base_damage_rune)
	print("Lanzada con velocidad: ", direction * throw_speed)
	
	runa.commited.connect(_on_runa_commited.bind(runa))
	runa.returned.connect(_on_rune_returned.bind(runa))
	
	_active_runes.append(runa)
	_controllable_runa = runa

func try_exhale(thrower : Node2D) -> void:
	if _controllable_runa == null:
		return
	var direction := _controllable_runa.global_position - thrower.global_position
	_controllable_runa.push(direction)
	
func do_inhale(thrower : Node2D) -> void:
	for runa in _active_runes.duplicate():
		if is_instance_valid(runa):
			runa.recall(thrower)

func has_controllable_runa() -> bool:
	return _controllable_runa != null

func _on_runa_commited(runa : Rune) -> void:
	if runa == _controllable_runa:
		_controllable_runa = null

func _on_rune_returned(runa : Rune) -> void:
	_active_runes.erase(runa)
	if runa == _controllable_runa:
		_controllable_runa = null
	runas_vailable += 1
	runa.queue_free()
		
	
	
