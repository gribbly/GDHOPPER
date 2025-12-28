extends Control

@onready var pos_info: Label = %ShipPosition
@onready var mass_info: Label = %ShipMass

# Internal
var _the_ship: Node3D = null
var _the_ship_rb: RigidBody3D = null
var _ship_position: String
var _ship_mass: String


func _ready() -> void:
	RH.print("🌡️ ship_info_panel.gd | _ready()", 2)


func set_ship(ship: Node3D) -> void:
	_the_ship = ship
	_the_ship_rb = (_the_ship as RigidBody3D)


func _process(_delta: float) -> void:
	if _the_ship == null:
		return
	
	_ship_position = "Pos: (%.1f, %.1f)" % [_the_ship.global_position.x, _the_ship.global_position.y]
	_ship_mass = "Mass: %.2f" % _the_ship_rb.mass 

	pos_info.text = _ship_position
	mass_info.text = _ship_mass
