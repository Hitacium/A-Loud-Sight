extends Node3D

#  === CONFIGURATION ===
const SAMPLE_RATE := 44100
const BLOCK_SIZE := 1024
const DOWNSAMPLE_W := 16
const DOWNSAMPLE_H := 12
const FREQ_MIN := 200.0
const FREQ_MAX := 2000.0
const CAPTURE_INTERVAL := 0.2  # seconds between image captures

# Scene references
@onready var player_camera: Camera3D = $"../head/Camera3D"
@onready var capture_viewport: SubViewport = $SubViewport
@onready var capture_camera: Camera3D = $SubViewport/Camera3D
@onready var audio_player: AudioStreamPlayer = $"../head/Sonifier"
@onready var debug_texture: TextureRect = $CanvasLayer/TextureRect

# Internal variables
var generator: AudioStreamGenerator
var playback: AudioStreamGeneratorPlayback
var pixel_matrix: Array = []
var time_since_last_capture := 0.0

# === INITIALIZATION ===
func _ready() -> void:
	# Initialize the audio generator stream
	generator = AudioStreamGenerator.new()
	generator.mix_rate = SAMPLE_RATE
	audio_player.stream = generator
	audio_player.play()
	playback = audio_player.get_stream_playback()

	# Prepare the pixel matrix (grayscale brightness grid)
	pixel_matrix.resize(DOWNSAMPLE_H)
	for y in range(DOWNSAMPLE_H):
		pixel_matrix[y] = []
		for x in range(DOWNSAMPLE_W):
			pixel_matrix[y].append(0.0)

	print("Sonifier initialized: Audio + Camera + SubViewport ready.")

# === MAIN LOOP ===
func _process(delta: float) -> void:
	time_since_last_capture += delta

	# Keep capture camera aligned with player's view
	if player_camera and capture_camera:
		capture_camera.global_transform = player_camera.global_transform

	# Every CAPTURE_INTERVAL seconds, capture a new image
	if time_since_last_capture >= CAPTURE_INTERVAL:
		time_since_last_capture = 0.0
		_capture_frame()

	# Continuously push small chunks of audio
	if playback and playback.get_frames_available() < BLOCK_SIZE:
		_generate_audio_block(BLOCK_SIZE)

# === CAPTURE AND PROCESS IMAGE ===
func _capture_frame() -> void:
	var tex := capture_viewport.get_texture()
	if tex == null:
		return
	var img := tex.get_image()
	if img == null:
		return

	img.resize(DOWNSAMPLE_W, DOWNSAMPLE_H)
	img.convert(Image.FORMAT_L8)  # grayscale

	for y in range(DOWNSAMPLE_H):
		for x in range(DOWNSAMPLE_W):
			var brightness := img.get_pixelv(Vector2i(x, y)).r
			pixel_matrix[y][x] = brightness

	debug_texture.texture = ImageTexture.create_from_image(img)
	print("Captured frame. Avg brightness: %.3f" % _avg_brightness())

func _avg_brightness() -> float:
	var total := 0.0
	for row in pixel_matrix:
		for b in row:
			total += b
	return total / float(DOWNSAMPLE_W * DOWNSAMPLE_H)

# === AUDIO GENERATION ===
func _generate_audio_block(l: int) -> void:
	if not playback:
		return

	var block := PackedVector2Array()
	block.resize(l)

	# Each frame = combined sine waves for each pixel
	for i in range(l):
		var s := 0.0
		for y in range(DOWNSAMPLE_H):
			for x in range(DOWNSAMPLE_W):
				var amp = pixel_matrix[y][x]
				if amp > 0.01:
					var freq = lerp(FREQ_MIN, FREQ_MAX, float(y) / DOWNSAMPLE_H)
					s += sin(2.0 * PI * freq * (float(i) / SAMPLE_RATE)) * amp
		block[i] = Vector2(s, s)  # stereo identical

	playback.push_buffer(block)
