extends Control

@onready var fps_counter_label: Label = %FpsCounter
@onready var frame_time_label: Label = %FrameTime
@onready var dropped_frames_label: Label = %DroppedFrames

var dropped_frames := 0
var ms_this_frame := 0.0

func _ready() -> void:
	RH.print("📈 debug_info_panel.gd | _ready()", 1)
	dropped_frames = 0

func _process(_delta: float) -> void:
	fps_counter_label.text = "%.2f FPS" % Performance.get_monitor(Performance.TIME_FPS)
	
	ms_this_frame = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	frame_time_label.text = "%.2f ms" % ms_this_frame

	if ms_this_frame > 16:
		dropped_frames += 1

	dropped_frames_label.text = "%d dropped" % dropped_frames
