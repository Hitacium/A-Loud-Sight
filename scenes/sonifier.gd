extends AudioStreamPlayer

#  === CONFIGURATION ===
const SAMPLE_RATE := 44100 # in HZ
const BUFFER_LENGTH = 1 # in seconds
const DOWNSAMPLE_W := 16
const DOWNSAMPLE_H := 16
const FREQ_MIN := 400.0 # in HZ
const FREQ_MAX := 2000.0 # in HZ

@export var capture_interval := 1  # in seconds
@export var OSC_LENGTH := 0.3 # in seconds
@export var EDGES_FADE := 0.01 # in seconds
@export var debug_preview := true
@export var logarithmic_distribution := true

@onready var player_camera: Camera3D = $"../Camera3D"
@onready var capture_viewport: SubViewport = $ScreenchotViewport
@onready var capture_camera: Camera3D = $ScreenchotViewport/CaptureCamera
@onready var preview: TextureRect = $DebugPreview	

var time_since_last_capture := 0.0
var playback: AudioStreamGeneratorPlayback
var pixels: Array = []
var thread: Thread

func _ready() -> void:
	pixels = _init_pixel_matrix()
	preview.visible = debug_preview
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_init_audio_streaming()

func _process(delta: float) -> void:
	time_since_last_capture += delta
	if time_since_last_capture >= capture_interval:
		time_since_last_capture = 0.0
		_capture_frame()

func _init_audio_streaming() -> void:
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = SAMPLE_RATE
	generator.buffer_length = BUFFER_LENGTH
	stream = generator
	play()
	playback = get_stream_playback()

func _init_pixel_matrix() -> Array:
	var m = []
	# grayscale brightness grid
	m.resize(DOWNSAMPLE_H)
	for y in range(DOWNSAMPLE_H):
		m[y] = []
		m[y].resize(DOWNSAMPLE_W)
		m[y].fill(0.0)
	return m

func _capture_frame() -> void:
	# Camera sync
	capture_camera.global_transform = player_camera.global_transform
	capture_camera.fov = player_camera.fov
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	await RenderingServer.frame_post_draw
	var text := capture_viewport.get_texture()
	if !text: return
		
	var img := text.get_image()
	img.resize(DOWNSAMPLE_W, DOWNSAMPLE_H)
	img.convert(Image.FORMAT_L8)  # grayscale
	
	if debug_preview:
		img.generate_mipmaps()
		preview.texture = ImageTexture.create_from_image(img)
	
	for y in range(DOWNSAMPLE_H):
		for x in range(DOWNSAMPLE_W):
			pixels[y][x] = img.get_pixel(x, y).r
			
	_start_async_gen()

func _start_async_gen() -> void:
	if thread and thread.is_alive():
		return # Still processing previous frame
	if thread:
		thread.wait_to_finish()
		
	thread = Thread.new()
	thread.start(_generate_wave_thread.bind(pixels.duplicate(true)))

func _generate_wave_thread(pixel_matrix: Array) -> void:
	var w := DOWNSAMPLE_W
	var h := DOWNSAMPLE_H
	
	var step_time := capture_interval / float(w)
	
	var total_frames := int((capture_interval + OSC_LENGTH) * SAMPLE_RATE)
	var buffer := PackedFloat32Array()
	buffer.resize(total_frames * 2)
	buffer.fill(0.0)
	
	for x in range(w):
		var pan := float(x) / float(w - 1) if w > 1 else 0.5
		var start_idx := int(x * step_time * SAMPLE_RATE)
		
		for y in range(h):
			var amp = pixel_matrix[y][x]
			if amp <= 0.5: continue
			
			var freq = _get_freq(y, h)
			_add_sine_to_buffer(freq, amp, pan, start_idx, buffer)
	
	_normalize(buffer)
	call_deferred("_push_to_playback", buffer)

func _get_freq(y: int, h: int) -> float:
	var t = float(h - y - 1) / float(h - 1) if h > 1 else 0.5
	if logarithmic_distribution:
		return FREQ_MIN * pow(FREQ_MAX / FREQ_MIN, t)
	return FREQ_MIN + (FREQ_MAX - FREQ_MIN) * t

func _add_sine_to_buffer(freq: float, amp: float, pan: float, start_idx: int, buffer: PackedFloat32Array):
	var length_frames := int(OSC_LENGTH * SAMPLE_RATE)
	var fade_frames := int(EDGES_FADE * SAMPLE_RATE)
	var step := TAU * freq / SAMPLE_RATE
	var local_phase := 0.0

	for i in range(length_frames):
		var idx = (start_idx + i) * 2
		if idx + 1 >= buffer.size(): break

		# Edge fade
		var env := 1.0
		if i < fade_frames: 
			env = float(i) / fade_frames
		elif i > length_frames - fade_frames: 
			env = float(length_frames - i) / fade_frames

		var s := sin(local_phase) * amp * env
		local_phase += step
		
		buffer[idx] += s * sqrt(1.0 - pan)
		buffer[idx + 1] += s * sqrt(pan)

func _normalize(buffer: PackedFloat32Array) -> void:
	var max_val := 0.0
	for s in buffer:
		max_val = max(max_val, abs(s))
	if max_val > 1.0: # Only normalize if clipping
		for i in range(buffer.size()):
			buffer[i] /= max_val

func _push_to_playback(buffer: PackedFloat32Array):
	for i in range(0, buffer.size(), 2):
		playback.push_frame(Vector2(buffer[i], buffer[i+1]))
		
func _exit_tree():
	if thread:
		thread.wait_to_finish()
