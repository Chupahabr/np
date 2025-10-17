extends CharacterBody3D

signal health_changed(new_health)
signal died()
signal respawned()

@export var max_health := 20
var current_health: int

@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5
@export var CAMERA_SENSITIVITY = 0.002

@onready var HEAD = $Head
@onready var CAMERA = $Head/Camera3D

var CAN_JUMP = true

func _ready():
	# Capture the cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_health = max_health
	print("Здоровье инициализировано: ", current_health, "/", max_health)

func _input(event):
	# Сamera rotation processing
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Vertical head rotation
		HEAD.rotate_x(-event.relative.y * CAMERA_SENSITIVITY)
		# Limit the angle of head tilt
		HEAD.rotation.x = clamp(HEAD.rotation.x, -PI/2, PI/2)
		
		# Rotation of the body horizontally
		rotate_y(-event.relative.x * CAMERA_SENSITIVITY)

func _process(_delta):
	if Input.is_action_just_pressed("press_e"):
		take_damage(1)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and CAN_JUMP:
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if global_position.y < 0:
		global_position = Vector3.ZERO
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func enable_jump():
	CAN_JUMP = true

func disable_jump():
	CAN_JUMP = false
	
func take_damage(amount: int):
	if current_health <= 0:
		return # Уже мертв

	current_health -= amount
	health_changed.emit(current_health)
	print("Получен урон: ", amount, ". Здоровье: ", current_health, "/", max_health)

	if current_health <= 0:
		die()

func die():
	print("Персонаж умер!")
	died.emit()
	respawn()

func respawn():
	# Восстанавливаем здоровье
	current_health = max_health
	
	# Телепортируем на нулевые координаты
	global_position = Vector3.ZERO  # или Vector3.ZERO для 3D
	
	print("Возрождение завершено! Здоровье: ", current_health, "/", max_health)
	respawned.emit()
	health_changed.emit(current_health)

# Дополнительные методы для управления здоровьем
func heal(amount: int):
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health)
	print("Восстановлено здоровья: ", amount, ". Здоровье: ", current_health, "/", max_health)

func get_health_percentage() -> float:
	return float(current_health) / float(max_health)
