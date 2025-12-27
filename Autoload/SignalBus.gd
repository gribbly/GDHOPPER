extends Node

# This is the global signal hub!
# It should be added as an autoload
# Note: Use @warning_ignore("unused_signal") before declaring a signal to avoid a runtime warning

# Example usage

@warning_ignore("unused_signal")
signal level_setup_complete() #level_csg.gd was first customer

@warning_ignore("unused_signal")
signal ship_spawn_point(spawn_point: Vector3) #level.gd was first customer

@warning_ignore("unused_signal")
signal explosion() #level_camera.gd was first customer

# Example usage:
# ---SignalBus.gd---
# @warning_ignore("unused_signal")
#   signal example_signal(example_param: Vector3)
#
# ---other_file1.gd---
# func _ready() -> void:
#	SignalBus.connect("example", Callable(self, "_example_callable"))
#
# func _exit_tree() -> void:
#	SignalBus.disconnect("explosion", Callable(self, "_example_callable"))
#
# func _example_callable(vec: Vector3) -> void:
#   print("I heard the 'example_signal' and with parameter %s" % vec)
#
# ---other_file2.gd---
# func _process() -> void:
#   Signbus.emit_signal("example", Vector3.ZERO)