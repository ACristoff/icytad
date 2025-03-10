class_name PlayerState extends State

var PLAYER : Player
#var PLAYERAUDIOMANAGER : PlayerAudioManager
#var ANIMATIONTREE : AnimationTree
#var ANIMATION_STATE_MACHINE : AnimationNodeStateMachinePlayback

func _ready():
	await owner.ready
	PLAYER = owner as Player
	#PLAYERAUDIOMANAGER = PLAYER.player_audio_manager
	#ANIMATIONTREE = PLAYER.ANIMATIONTREE
	#ANIMATION_STATE_MACHINE = ANIMATIONTREE["parameters/StateMachine/playback"]
