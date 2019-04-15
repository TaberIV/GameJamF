extends Node2D

# Editor values
export var shoot_cooldown: float = 0.1
export var burst_num: int = 3
export var burst_cooldown: float = 0.6
export var shot_charge_time: float = 0.8

# Scenes
var Bullet: PackedScene = preload("res://scenes/Bullet.tscn")
var scene: Node2D
var player: CharacterController
var shoot_sound: AudioStreamPlayer2D
var shot_charged_sound: AudioStreamPlayer2D

# Constants
var offset

# Input state
var shoot_held: bool
var shoot_pressed: bool
var shoot_released: bool

# Shoot state
var shoot_hold_time: float = 0
var shoot_cooldown_timer: float = 0
var burst_counter: int = 0
var burst_cooldown_timer: float = 0

var shot_buffered: bool = false
var shot_charged: bool = false


func _ready() -> void:
    shoot_sound = $Shoot
    shot_charged_sound = $ShotCharged
    
    player = get_parent()
    scene = player.get_parent()
    
    offset = position


func _process(delta: float) -> void:
    # Manage shot timers
    if shoot_cooldown_timer != 0:
        shoot_cooldown_timer = max(shoot_cooldown_timer - delta, 0)
    if burst_cooldown_timer != 0:
        burst_cooldown_timer = max(burst_cooldown_timer - delta, 0)
    else:
        burst_counter = 0
  
    # Charge shot timer  
    if shoot_hold_time > shot_charge_time and shot_charged == false:
        shot_charged = true
        shot_charged_sound.play()
    
    # Action
    _get_input()

    if shoot_pressed or shot_buffered:
        var in_burst = burst_cooldown == 0 or burst_counter < burst_num
        
        if shoot_cooldown_timer == 0 and in_burst:
            # Manage cooldowns
            shoot_cooldown_timer = shoot_cooldown
            if burst_cooldown_timer == 0:
                burst_cooldown_timer = burst_cooldown
                burst_counter = 1
            else:
                burst_counter += 1
                if burst_cooldown / burst_counter > burst_cooldown_timer:
                    burst_cooldown_timer = burst_cooldown
                    burst_counter = 1
                
            shot_buffered = false
            
            # Shoot
            _shoot()
        else:
            shot_buffered = in_burst 
    elif shoot_held:
        shoot_hold_time += delta
    elif shoot_released:
        shoot_hold_time = 0
        shot_charged = false
        


func _shoot() -> void:
    # Values needed for bullet
    var current_offset = offset
    var dir = player.dir
    current_offset.x *= dir

    # Create bullet
    var bullet = Bullet.instance()
    bullet.position = player.global_position + current_offset
    bullet.velocity.x *= player.dir
    scene.add_child(bullet)
    
    # Play sound
    shoot_sound.play()
    

func _get_input() -> void:
    shoot_held = Input.is_action_pressed("shoot")
    shoot_pressed = Input.is_action_just_pressed("shoot")
    shoot_released = Input.is_action_just_released("shoot")
