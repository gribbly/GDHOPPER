extends Control

@onready var fps_counter: Label = %FpsCounter
@onready var frame_time: Label = %FrameTime

func _ready() -> void:
	RH.print("📈 debug_info_panel.gd | _ready()", 1)

func _process(_delta: float) -> void:
	fps_counter.text = "%.2f FPS" % Performance.get_monitor(Performance.TIME_FPS)
	frame_time.text = "%.2f ms" % Performance.get_monitor(Performance.TIME_PROCESS)
