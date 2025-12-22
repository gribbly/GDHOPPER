extends Node

# This is the global signal hub!
# It should be added as an autoload
# Note: Use @warning_ignore("unused_signal") before declaring a signal to avoid a runtime warning

@warning_ignore("unused_signal")
signal level_setup_complete() #level_csg.gd was first customer

@warning_ignore("unused_signal")
signal ship_spawn_point(spawn_point: Vector3) #level.gd was first customer