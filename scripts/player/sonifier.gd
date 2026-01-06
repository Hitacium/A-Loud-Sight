extends AudioStreamPlayer

const SAMPLE_RATE := 44100 # in Hz
const DOWNSAMPLE_W := 32
const DOWNSAMPLE_H := 32
const FREQ_MIN := 400.0 # in Hz
const FREQ_MAX := 6000.0 # in Hz

@export var osc_length := 0.05 # in seconds
@export var debug_preview := true
@export var logarithmic_distribution := true

var audio_stream_playback: AudioStreamGeneratorPlayback
var thread: Thread

@onready var main_camera: Camera3D = $"../Camera3D"
@onready var capture_viewport: SubViewport = $ScreenchotViewport
@onready var capture_camera: Camera3D = $ScreenchotViewport/CaptureCamera
@onready var preview: TextureRect = $DebugPreview


func _ready() -> void:
	init_audio_streaming()
	preview.visible = debug_preview
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


var time_since_last_capture: float = 0
func _process(delta: float) -> void:
	time_since_last_capture += delta
	var scan_time := osc_length * DOWNSAMPLE_W
	if time_since_last_capture >= scan_time:
		time_since_last_capture = 0.0
		capture_frame()


func init_audio_streaming() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = SAMPLE_RATE
	generator.buffer_length = osc_length * DOWNSAMPLE_W + 0.1
	stream = generator
	play()
	audio_stream_playback = get_stream_playback()


func capture_frame() -> void:
	if thread and thread.is_started():
		thread.wait_to_finish()

	capture_camera.global_transform = main_camera.global_transform
	capture_camera.fov = main_camera.fov
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

	await RenderingServer.frame_post_draw

	var img: Image = capture_viewport.get_texture().get_image()
	img.resize(DOWNSAMPLE_W, DOWNSAMPLE_H, Image.INTERPOLATE_LANCZOS)
	img.convert(Image.FORMAT_L8)

	if debug_preview:
		preview.texture = ImageTexture.create_from_image(img)

	thread = Thread.new()
	thread.start(create_audio_from_image.bind(img.get_data()))


func create_audio_from_image(pixels: PackedByteArray) -> void:
	var column_samples := int(osc_length * SAMPLE_RATE)
	var total_samples := column_samples * DOWNSAMPLE_W
	var buffer := PackedVector2Array()
	buffer.resize(total_samples)
	buffer.fill(Vector2.ZERO)

	for x in range(DOWNSAMPLE_W):
		var start_idx := x * column_samples
		var pan := float(x) / float(max(1, DOWNSAMPLE_W - 1))
		var l_gain := sqrt(1.0 - pan)
		var r_gain := sqrt(pan)

		for y in range(DOWNSAMPLE_H):
			var brightness := pixels[y * DOWNSAMPLE_W + x]
			if brightness < 10:
				continue

			var amp := (float(brightness) / 255.0) * 0.4
			var freq := get_frequency(y)
			var step := TAU * freq / SAMPLE_RATE
			var phase := 0.0

			# Hann window per whole column
			for i in range(column_samples):
				var idx := start_idx + i
				if idx >= total_samples:
					break

				var window := 0.5 * (1.0 - cos(TAU * i / float(column_samples - 1)))
				var sample := sin(phase) * amp * window

				buffer[idx].x += sample * l_gain
				buffer[idx].y += sample * r_gain

				phase += step
				
	normalize_buffer(buffer)
	call_deferred("_push_audio", buffer)


func normalize_buffer(buffer: PackedVector2Array) -> void:
	var sum_l := 0.0
	var sum_r := 0.0
	var n := buffer.size()

	if n == 0:
		return

	for v in buffer:
		sum_l += v.x
		sum_r += v.y

	var mean_l := sum_l / n
	var mean_r := sum_r / n

	var peak := 0.0
	for i in range(n):
		buffer[i].x -= mean_l
		buffer[i].y -= mean_r
		peak = max(peak, abs(buffer[i].x), abs(buffer[i].y))

	if peak > 0.00001:
		var inv := 1.0 / peak
		for i in range(n):
			buffer[i] *= inv


func _push_audio(buffer: PackedVector2Array) -> void:
	if not audio_stream_playback:
		return
	if audio_stream_playback.can_push_buffer(buffer.size()):
		audio_stream_playback.push_buffer(buffer)


func get_frequency(y: int) -> float:
	var t := float(DOWNSAMPLE_H - y - 1) / float(DOWNSAMPLE_H - 1)
	if logarithmic_distribution:
		return FREQ_MIN * pow(FREQ_MAX / FREQ_MIN, t)
	return lerp(FREQ_MIN, FREQ_MAX, t)


func _exit_tree():
	if thread and thread.is_started():
		thread.wait_to_finish()
