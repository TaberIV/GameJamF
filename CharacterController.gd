extends KinematicBody2D

class_name CharacterController

# Editor Parameters
export var move_speed: float = 250
export var accel_time: float = 0.1
export var deccel_time: float = 0.1

export var jump_height: float = 150
export(float, 0.1, 1) var jump_variance: float = 0.5
export var jump_distance: float = 200
export(float, 0, 1) var air_mobility: float = 0.8
#export var jump_forgiveness: float = 0.1

export var max_slope_angle: float = 45

# Movement constants
var move_force: float
var friction: float

var gravity: float
var jump_speed: float

var max_slope_normal: Vector2

# Input state
var h_input: int = 0
var d_input: bool = false

var jump: bool = false
var jump_pressed: bool = false
var jump_timer: float = 0

# Movement state
var velocity: Vector2 = Vector2()
var fast_fall: bool = false

var dir: int = 1
var hit: bool = false
var dead: bool = false

# Collision info
var colY: KinematicCollision2D
var colX: KinematicCollision2D

var on_ground: bool = false setget _set_on_ground
var on_wall: bool = false
var floor_velocity: Vector2 = Vector2()

# References
var sprite: AnimatedSprite
var jump_sound: AudioStreamPlayer

# Setters/Getters
func _set_on_ground(val: bool) -> void:
    if not val:
        velocity.x += floor_velocity.x
        floor_velocity = Vector2()
    else:
        hit = false

    on_ground = val


#
func _ready() -> void:
    # Set constants
    if accel_time == 0:
        move_force = INF
    else:
        move_force = move_speed / accel_time

    if deccel_time == 0:
        friction = INF
    else:
        friction = move_speed / deccel_time

    gravity = 2 * jump_height * pow(move_speed, 2) / pow(jump_distance / 2, 2)
    jump_speed = -2 * jump_height * move_speed / (jump_distance / 2)

    max_slope_normal = Vector2(sin(deg2rad(max_slope_angle + 1)),
                               cos(deg2rad(max_slope_angle + 1)))
    
    # Find references
    sprite = $AnimatedSprite
    jump_sound = $JumpSound


func _physics_process(delta: float) -> void:
    if not hit and not dead:
        _get_input()
    else:
        _zero_input()
    
    _movement(delta)
    
    _set_anim()


func _get_input() -> void:
    # Duck input
    d_input = Input.is_action_pressed("duck")
    if not d_input:
        d_input = Input.get_joy_axis(0, JOY_ANALOG_LY) > 0.5
    
    # Movement Input
    h_input = 0
    
    if Input.is_action_pressed("left"):
        h_input -= 1
    if Input.is_action_pressed("right"):
        h_input += 1
 
    if h_input == 0:
        var stick = Input.get_joy_axis(0, JOY_ANALOG_LX)
        h_input = sign(stick) if abs(stick) > 0.5 else 0
    
    # Jump Input
    jump_pressed = Input.is_action_just_pressed("jump")
    jump = Input.is_action_pressed("jump")
    
    if velocity.y < 0 and not jump:
        fast_fall = true


func _zero_input() -> void:
    h_input = 0
    d_input = false
    
    jump = false
    jump_pressed = false
    jump_timer = 0


func _movement(delta: float) -> void:
    # Horizontal Movement
    if sign(h_input) == sign(velocity.x) and abs(velocity.x) >= move_speed:
        if on_ground:
            _apply_friction(delta)
            if abs(velocity.x) < move_speed:
                velocity.x = h_input * move_speed
    elif h_input != 0:
        # Determine force applied to player
        var force = h_input * move_force * delta

        if not on_ground:
            force *= air_mobility
        elif sign(force) != sign(velocity.x):
            _apply_friction(delta)

        # Apply force
        if sign(force) == sign(velocity.x):
            velocity.x = sign(force) * min(abs(h_input) * move_speed, abs(velocity.x + force))
        else:
            velocity.x += force
    # Friction
    elif on_ground:
        _apply_friction(delta)

    # Vertical Movement
    # Jump
    if (on_ground or jump_timer > 0) and jump_pressed:
        velocity.y = jump_speed
        jump_timer = 0
        jump_sound.play()
    jump_timer = max(jump_timer - delta, 0)
    
    # Gravity
    var gravity_force = gravity * delta
    if fast_fall and velocity.y < 0:
         gravity_force /= jump_variance
    else:
        fast_fall = false
        
    velocity.y += gravity_force
        
    velocity.y = min(velocity.y, abs(jump_speed * 2))

    # Move and collide
    colY = move_and_collide(Vector2(0, velocity.y) * delta)
    colX = move_and_collide(Vector2(velocity.x + floor_velocity.x, 0) * delta)

    _handle_collisions(delta)


func _apply_friction(delta: float):
    var force = friction * delta
    if abs(velocity.x) <= force:
        velocity.x = 0
    else:
        velocity.x -= sign(velocity.x) * force


func _handle_collisions(delta: float) -> void:
    # Vertical
    if abs(velocity.y) > 0 and colY:
        var was_on_ground = on_ground
        self.on_ground = velocity.y > 0
        velocity.y = 0

        if on_ground:
            floor_velocity = colY.collider_velocity
            velocity.y = max(floor_velocity.y, 0)
            if not was_on_ground:
                velocity.x -= floor_velocity.x
    else:
        self.on_ground = false

    # Horizontal
    if velocity.x != 0:
        if colX:
            # Collide with wall
            if abs(colX.normal.x) > max_slope_normal.x:
                velocity.x = 0
                on_wall = true
            # Walk up slopes
            else:
                on_wall = false
                
                var y_off = -(colX.normal.x / colX.normal.y) * colX.remainder.x
                colY = move_and_collide(Vector2(0, y_off))
                colX = move_and_collide(colX.remainder)

                # Check for popping above slope
                _check_stick(-y_off)
        # Check if walked off ledge/down slope
        elif on_ground and not test_move(transform, Vector2(0, 0.1)):
            var slope_desc = abs(velocity.x) * delta / max_slope_normal.y
            _check_stick(slope_desc)
            


func _check_stick(stick: float) -> void:
    var should_stick = test_move(transform, Vector2(0, stick))

    if should_stick:
        colY = move_and_collide(Vector2(0, stick))
        self.on_ground = true
    else:
        self.on_ground = false


func _set_anim() -> void:
    if h_input != 0:
        dir = sign(h_input)
        sprite.flip_h = dir < 0
    
    sprite.offset = Vector2(0, 0)    
    if dead:
        sprite.play("dead")
    elif hit:
        sprite.play("hit")
    elif not on_ground:
        sprite.play("fall")
    elif abs(velocity.x) > 0:
        sprite.play("walk")
    elif d_input:
        sprite.offset = Vector2(0, 3.5 * sprite.frame)
        sprite.play("duck")
    else:
        sprite.play("idle")


# Signal Callbacks
func _on_Hurtbox_take_damage(dir) -> void:
    hit = true
    velocity = Vector2(-dir * move_speed / 2, jump_speed * 0.66)


func _die() -> void:
    if not dead:
        $RespawnTimer.start()
    dead = true


func _on_VisibilityNotifier2D_screen_exited() -> void:
    $FallSound.play()
    $RespawnTimer.start()


func _on_RespawnTimer_timeout() -> void:
    queue_free()
