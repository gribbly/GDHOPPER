extends Control

@onready var time_info: Label = %TimeInfo
@onready var render_info: Label = %RenderInfo

# Internal
var dropped_frames := 0
var ms_average_frame := 0.0
var time_info_string: String
var render_info_string: String

func _ready() -> void:
	RH.print("📈 debug_info_panel.gd | _ready()", 1)
	dropped_frames = 0

func _process(_delta: float) -> void:
	if _delta > (1.0 / 60.0):
		dropped_frames += 1

	time_info_string = "%.2f FPS | %.2fms | %d drop" % [Performance.get_monitor(Performance.TIME_FPS), _delta, dropped_frames]
	time_info.text = time_info_string

	render_info_string = "%d drawcalls" % Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	render_info.text = render_info_string

