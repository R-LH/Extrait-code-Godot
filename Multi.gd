extends Node3D

var menu_visibility=true
var invent_visibility = false
var player_alive = false
@export var max_id = 1
@export var Address = ""
@export var Port = 8915
@export var tab_pilier = []
var all_is_ok
var map_range = 1000

const PLAYER = preload("res://player.tscn")
const PILIER = preload("res://environnement/pilier.tscn")

var hosting=false
var peer
var ip_adress = ""

@export var team1s := Vector3(map_range,30,map_range)
@export var team2s := Vector3(-map_range,30,-map_range)


#ressources : 0blanc,1jaune,2orange,3rouge,4bleu,5vert,6noir
var Mblanc = preload("res://environnement/materials/pblanc.tres")
var Mjaune = preload("res://environnement/materials/pjaune.tres")
var Morange = preload("res://environnement/materials/porange.tres")
var Mrouge = preload("res://environnement/materials/prouge.tres")
var Mbleu = preload("res://environnement/materials/brouge.tres")
var Mvert =  preload("res://environnement/materials/pvert.tres")
var Mnoir = preload("res://environnement/materials/pnoir.tres")


#ressources : 0blanc,1jaune,2orange,3rouge,4bleu,5vert,6noir
func get_mat_color(a):
	match a:
			0:
				return Mblanc
			1:
				return Mjaune
			2:
				return Morange
			3:
				return Mrouge
			4:
				return Mbleu
			5:
				return Mvert
			6:
				return Mnoir

func _ready() -> void:
	upnp_setup()
	multiplayer.peer_disconnected.connect(remove_player)
	multiplayer.connected_to_server.connect(peer_connected_to_server)
	multiplayer.connection_failed.connect(peer_connection_failed)
	peer = ENetMultiplayerPeer.new()

func preparation():
	var densite = randi_range(2,10)
	var  num_pillier = int(map_range/densite)
	var c =0
	var serie= densite*10
	while num_pillier>0:
		var pilier = PILIER.instantiate()
		pilier.position.x=int(num_pillier*randi_range(50,100)*cos(num_pillier))%map_range
		pilier.position.z=int(num_pillier*randi_range(50,100)*sin(num_pillier))%map_range
		pilier.name = "Pilier"+str(num_pillier)
		add_child(pilier)
		pilier.set_color(c)
		if(serie<=0):
			c = randi_range(0,6)
			serie = densite * randi_range(1,20)
		else:
			serie -=1
		num_pillier-=1

func _on_host_pressed() -> void:
	if not hosting:
		peer.create_server(Port)
		multiplayer.peer_connected.connect(_add_player)
		multiplayer.set_multiplayer_peer(peer)
		preparation()
		%IP_EDIT.text = ip_adress
	hosting= true

func peer_connection_failed():
	%IP_EDIT.text="conexion failed"
	Address =str(%IP_EDIT.text)
	_on_join_pressed()

func peer_connected_to_server():
	print("Yeah you are connected to server ! and only you can read this message. Or i least I think.")
	%IP_EDIT.text="IP Hôte : "+%IP_EDIT.text

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id)) 
	if player:
		player.queue_free()

func _add_player(id=1):
	%Host.visible=false
	%Join.visible=false
	var player = PLAYER.instantiate()
	player.name = str(id)
	call_deferred("add_child",player)

func _on_join_pressed():
	print(Address)
	var error = peer.create_client(Address, Port)
	if error:
		return error
	multiplayer.multiplayer_peer = peer

func upnp_setup():
	var upnp = UPNP.new()
	
	var decouverte = upnp.discover()
	assert(decouverte==UPNP.UPNP_RESULT_SUCCESS, "UPNP PROBLEMATIQUE, L'ERREUR: "+str(decouverte))
	
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), "MAUVAISE GATEWAY UPNP")
	
	var maper = upnp.add_port_mapping(Port,0,"test","UDP",0)
	var maper2 = upnp.add_port_mapping(Port,0,"test","TCP",0)
	assert(maper == UPNP.UPNP_RESULT_SUCCESS, "UPNP --> PROBLEME DE PORT")
	assert(maper2 == UPNP.UPNP_RESULT_SUCCESS, "UPNP --> PROBLEME DE PORT")
	
	print("TOUT VA BIEN ! ADRESSE POUR REJOINDRE :"+str(upnp.query_external_address()))
	%IP_EDIT.text = upnp.query_external_address()


func _on_ip_edit_text_changed(_new_text: String) -> void:
	Address =str(%IP_EDIT.text) # Replace with function body.


func _on_local_join_pressed():
	var error = peer.create_client("127.0.0.1", Port)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
