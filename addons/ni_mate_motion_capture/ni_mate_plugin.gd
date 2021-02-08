#*******************************************************************************#
#  ni_mate_plugin.gd                                                            #
#*******************************************************************************#
#                             This file is part of:                             #
#                            NI MATE MOTION CAPTURE                             #
#           https://github.com/hoontee/godot-ni-mate-animation-editor           #
#*******************************************************************************#
#  Copyright (c) 2021 hoontee @ Iron Stag Games.                                #
#                                                                               #
#  NMMC is free software: you can redistribute it and/or modify                 #
#  it under the terms of the GNU Affero General Public License as published by  #
#  the Free Software Foundation, either version 3 of the License, or            #
#  (at your option) any later version.                                          #
#                                                                               #
#  NMMC is distributed in the hope that it will be useful,                      #
#  but WITHOUT ANY WARRANTY; without even the implied warranty of               #
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                #
#  GNU Affero General Public License for more details.                          #
#                                                                               #
#  You should have received a copy of the GNU Affero General Public License     #
#  along with NMMC.  If not, see <https://www.gnu.org/licenses/>.               #
#*******************************************************************************#

tool
extends EditorPlugin

const spinner_icons := [
	preload("icon_progress_1.svg"),
	preload("icon_progress_2.svg"),
	preload("icon_progress_3.svg"),
	preload("icon_progress_4.svg"),
	preload("icon_progress_5.svg"),
	preload("icon_progress_6.svg"),
	preload("icon_progress_7.svg"),
	preload("icon_progress_8.svg")
]
const bone_control_nodes := {
	"Chest":			"Control_Torso",
	"Head":				"Control_Torso",
	"Left_Shoulder":	"Control_Torso",
	"Left_Elbow":		"Control_Left_Arm",
	"Left_Wrist":		"Control_Left_Arm",
	"Left_Hand":		"Left_Thumb",
	"Left_Knee":		"Control_Left_Leg",
	"Left_Ankle":		"Control_Left_Leg",
	"Left_Foot":		"Left_Knee",
	"Right_Shoulder":	"Control_Torso",
	"Right_Elbow":		"Control_Right_Arm",
	"Right_Wrist":		"Control_Right_Arm",
	"Right_Hand":		"Right_Thumb",
	"Right_Knee":		"Control_Right_Leg",
	"Right_Ankle":		"Control_Right_Leg",
	"Right_Foot":		"Right_Knee"
}
const bone_rotations := {
	"Left_Elbow": -PI/2.0,
	"Left_Wrist": -PI/2.0,
	"Left_Knee": PI/2.0,
	"Left_Ankle": PI/2.0,
	"Right_Elbow": -PI/2.0,
	"Right_Wrist": -PI/2.0,
	"Right_Knee": PI/2.0,
	"Right_Ankle": PI/2.0
}

var joint_maps := {}
var joint_connections := {}

var config := ConfigFile.new()
var dock := preload("ni_mate_dock.escn").instance()
var rig := dock.get_node("ViewportContainer/Viewport")
var udp := PacketPeerUDP.new()
var pr := PacketReader.new()

var ip := "127.0.0.1" setget set_ip
var port := 7000 setget set_port
var simple := false setget set_simple
var rotate_hands_with_thumbs := false setget set_rotate_hands_with_thumbs
var clamp_origin_x := false setget set_clamp_origin_x
var clamp_origin_y := false setget set_clamp_origin_y
var clamp_origin_z := false setget set_clamp_origin_z
var height_offset := 0.0 setget set_height_offset
var show_joints := true setget set_show_joints
var show_bones := true setget set_show_bones
var show_bone_axes := false setget set_show_bone_axes

var nimate_node: Node
var transforming := false
var recording_animation: Animation
var spinner := 0
var frame := -1

func _init() -> void:
	dock.name = "NI mate"
	
	VisualServer.connect("frame_pre_draw", self, "on_frame_pre_draw")
	get_editor_interface().get_selection().connect("selection_changed", self, "on_selection_changed")
	dock.get_node("MenuBar/Rig").get_popup().connect("id_pressed", self, "rig_id_pressed")
	dock.get_node("MenuBar/Rig/ConfirmationDialog").connect("confirmed", self, "confirm_height_offset")
	dock.get_node("MenuBar/Rig/ConfirmationDialog").get_cancel().connect("pressed", self, "update_height_offset_text")
	dock.get_node("MenuBar/View").get_popup().connect("id_pressed", self, "view_id_pressed")
	dock.get_node("MenuBar/Connect").connect("pressed", dock.get_node("MenuBar/Connect/ConfirmationDialog"), "popup")
	dock.get_node("MenuBar/Connect/ConfirmationDialog").connect("confirmed", self, "confirm_connect")
	dock.get_node("MenuBar/Connect/ConfirmationDialog").get_cancel().connect("pressed", self, "update_ip_port_text")
	dock.get_node("MenuBar/Disconnect").connect("pressed", self, "listen", [false])
	dock.get_node("MenuBar/Record").connect("pressed", self, "record", [true])
	dock.get_node("MenuBar/Save").connect("pressed", self, "record", [false, true])
	
	if config.load("user://config.cfg") == OK:
		ip = config.get_value("osc", "ip", ip)
		port = int(config.get_value("osc", "port", port))
		simple = bool(config.get_value("rig", "simple", simple))
		rotate_hands_with_thumbs = bool(config.get_value("rig", "rotate_hands_with_thumbs", rotate_hands_with_thumbs))
		clamp_origin_x = bool(config.get_value("rig", "clamp_origin_x", clamp_origin_x))
		clamp_origin_y = bool(config.get_value("rig", "clamp_origin_y", clamp_origin_y))
		clamp_origin_z = bool(config.get_value("rig", "clamp_origin_z", clamp_origin_z))
		height_offset = float(config.get_value("rig", "height_offset", height_offset))
		show_joints = float(config.get_value("view", "show_joints", show_joints))
		show_bones = float(config.get_value("view", "show_bones", show_bones))
		show_bone_axes = float(config.get_value("view", "show_bone_axes", show_bone_axes))
	set_ip(ip, false)
	set_port(port, false)
	set_simple(simple, false)
	set_rotate_hands_with_thumbs(rotate_hands_with_thumbs, false)
	set_clamp_origin_x(clamp_origin_x, false)
	set_clamp_origin_y(clamp_origin_y, false)
	set_clamp_origin_z(clamp_origin_z, false)
	set_height_offset(height_offset, false)
	set_show_joints(show_joints, false)
	set_show_bones(show_bones, false)
	set_show_bone_axes(show_bone_axes, false)

func _enter_tree() -> void:
	add_custom_type("NImate", "Node", preload("ni_mate_node.gd"), preload("icon_bone_track.svg"))
	add_control_to_dock(DOCK_SLOT_RIGHT_BR, dock)

func _exit_tree() -> void:
	remove_custom_type("NImate")
	remove_control_from_docks(dock)
	listen(false)

func _process(_delta) -> void:
	if udp.get_available_packet_count() > 0:
		transforming = false
		while udp.get_available_packet_count() > 0:
			var data := udp.get_packet()
			var decoded := pr.decode_osc(data)
			var joint_name := PoolByteArray(decoded[0]).get_string_from_utf8()
			if simple:
				if joint_name == "Pelvis" or joint_name == "Chest" or joint_name == "Left_Wrist" or joint_name == "Right_Wrist" or joint_name == "Left_Ankle" or joint_name == "Right_Ankle":
					joint_name = "?"
				elif joint_name == "Torso":
					joint_name = "Pelvis"
				elif joint_name == "Neck":
					joint_name = "Chest"
				elif joint_name == "Left_Hand":
					joint_name = "Left_Wrist"
				elif joint_name == "Right_Hand":
					joint_name = "Right_Wrist"
				elif joint_name == "Left_Foot":
					joint_name = "Left_Ankle"
				elif joint_name == "Right_Foot":
					joint_name = "Right_Ankle"
			var joint := rig.get_node_or_null(joint_name)
			if joint_name.begins_with("@"):
				# Ignored for now
				pass
			elif joint_name.begins_with("?"):
				# Ignored for now
				pass
			elif len(decoded) == 3: #one value
				# Ignored for now
				pass
			elif len(decoded) == 5: #location
				if joint:
					joint.global_transform = Transform(Basis(), Vector3(decoded[2], decoded[3], decoded[4]))
					transforming = true
			elif len(decoded) == 6: #quaternion
				if joint:
					joint.global_transform = Transform(Quat(decoded[6], decoded[7], decoded[8], -decoded[5]))
					transforming = true
			elif len(decoded) == 9: #location & quaternion
				if joint:
					joint.global_transform = Transform(Quat(decoded[6], decoded[7], decoded[8], -decoded[5]),
														Vector3(decoded[2], decoded[3], decoded[4]))
					transforming = true
			else:
				printerr("Delicode NI mate Tools error parsing OSC message: " + str(decoded))
		transform_control(rig.get_node("Control_Torso"), rig.get_node("Right_Hip"), rig.get_node("Left_Hip"), rig.get_node("Chest"), (rig.get_node("Left_Shoulder").global_transform.origin + rig.get_node("Right_Shoulder").global_transform.origin)/2.0)
		transform_control(rig.get_node("Control_Left_Arm"), rig.get_node("Left_Shoulder"), rig.get_node("Left_Elbow"), rig.get_node("Left_Wrist"))
		transform_control(rig.get_node("Control_Left_Leg"), rig.get_node("Left_Hip"), rig.get_node("Left_Knee"), rig.get_node("Left_Ankle"))
		transform_control(rig.get_node("Control_Right_Arm"), rig.get_node("Right_Shoulder"), rig.get_node("Right_Elbow"), rig.get_node("Right_Wrist"))
		transform_control(rig.get_node("Control_Right_Leg"), rig.get_node("Right_Hip"), rig.get_node("Right_Knee"), rig.get_node("Right_Ankle"))
		for joint in rig.get_children():
			var joint_name: String = joint.name
			if joint_connections.has(joint_name):
				var bone := rig.get_node_or_null(joint_name + "/Bone")
				var joint2 := rig.get_node_or_null(joint_connections[joint_name])
				if bone.global_transform.origin != joint2.global_transform.origin:
					var control_node := rig.get_node(bone_control_nodes[joint_name])
					bone.global_transform = Transform(Basis(), (joint.global_transform.origin + joint2.global_transform.origin)/2.0)
					bone.look_at(joint2.global_transform.origin, control_node.global_transform.origin.direction_to(bone.global_transform.origin))
					bone.rotate_object_local(Vector3.RIGHT, PI/2.0)
					bone.rotate_object_local(Vector3.UP, PI)
					if bone_rotations.has(joint_name):
						bone.rotate_object_local(Vector3.UP, bone_rotations[joint_name])
					bone.scale = Vector3(1, (joint.global_transform.origin - joint2.global_transform.origin).length()/0.01, 1)
					bone.get_node("Axis").scale = Vector3(1, 5, 1/bone.scale.y)
					bone.get_node("Axis").translation = Vector3(0, 0, -0.025)
		if transforming and recording_animation:
			frame += 1
			var t := frame / 20.0
			var s: Skeleton = nimate_node.get_node(nimate_node.get("skeleton"))
			var i := 0
			for key in joint_maps:
				transform_bone(s, t, key, nimate_node.get(joint_maps[key]))
				i += 1
			recording_animation.length = t

func transform_bone(s: Skeleton, time: float, s_bone: String, s_track: String) -> void:
	# Ordering will be different between Skeleton and AnimationPlayer
	var i_track := recording_animation.find_track(".:" + s_track)
	var i_bone := s.find_bone(s_track)
	if i_bone >= 0 and i_track >= 0:
		var basis: Basis = (
			(s.get_bone_rest(i_bone).basis.inverse() if not s.is_bone_rest_disabled(i_bone) else Basis())
			* (s.get_bone_global_pose(s.get_bone_parent(i_bone)).basis.inverse() if s.get_bone_parent(i_bone) >= 0 else Basis())
			* Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1))
			* rig.get_node(s_bone + "/Bone").global_transform.basis.orthonormalized()
			* Basis(Vector3(-1, 0, 0), Vector3(0, 0, -1), Vector3(0, -1, 0))
		).orthonormalized()
		if s_bone == "Chest":
			var origin: Vector3 = (
				s.get_bone_rest(i_bone).basis.xform_inv(-rig.get_node("Pelvis").global_transform.origin - Vector3(0, height_offset, 0))
				- s.get_bone_rest(i_bone).basis.xform(s.get_bone_rest(i_bone).origin)
			) * s.get_bone_rest(i_bone).basis.xform_inv(Vector3(int(not clamp_origin_x), int(not clamp_origin_y), int(not clamp_origin_z)))
			s.set_bone_pose(i_bone, Transform(basis, origin))
			recording_animation.transform_track_insert_key(i_track, time, origin, basis, Vector3.ONE)
		else:
			s.set_bone_pose(i_bone, basis)
			recording_animation.transform_track_insert_key(i_track, time, Vector3.ZERO, basis, Vector3.ONE)

func set_ip(new_value := "", update_config := true) -> void:
	ip = new_value
	update_ip_port_text()
	if update_config:
		save_config()

func set_port(new_value := 0, update_config := true) -> void:
	port = clamp(new_value, 0, 65535)
	update_ip_port_text()
	if update_config:
		save_config()

func update_ip_port_text() -> void:
	dock.get_node("MenuBar/Connect/ConfirmationDialog/HBoxContainer2/IPAddress").text = ip
	dock.get_node("MenuBar/Connect/ConfirmationDialog/HBoxContainer2/Port").text = str(port)
	dock.get_node("MenuBar/Connect/AcceptDialog").dialog_text = "Failed to connect to OSC at " + ip + ":" + str(port)

func set_simple(new_value := false, update_config := true) -> void:
	simple = new_value
	if simple:
		set_rotate_hands_with_thumbs(false)
		joint_maps = {
			"Chest":			"bone_root",
			"Head":				"bone_neck",
			"Left_Shoulder":	"bone_left_shoulder",
			"Left_Elbow":		"bone_left_upper_arm",
			"Left_Wrist":		"bone_left_forearm",
			"Left_Knee":		"bone_left_thigh",
			"Left_Ankle":		"bone_left_shin",
			"Right_Shoulder":	"bone_right_shoulder",
			"Right_Elbow":		"bone_right_upper_arm",
			"Right_Wrist":		"bone_right_forearm",
			"Right_Knee":		"bone_right_thigh",
			"Right_Ankle":		"bone_right_shin"
		}
		joint_connections = {
			"Chest":			"Pelvis",
			"Head":				"Chest",
			"Left_Shoulder":	"Chest",
			"Left_Elbow":		"Left_Shoulder",
			"Left_Wrist":		"Left_Elbow",
			"Left_Knee":		"Left_Hip",
			"Left_Ankle":		"Left_Knee",
			"Right_Shoulder":	"Chest",
			"Right_Elbow":		"Right_Shoulder",
			"Right_Wrist":		"Right_Elbow",
			"Right_Knee":		"Right_Hip",
			"Right_Ankle":		"Right_Knee"
		}
	else:
		joint_maps = {
			"Chest":			"bone_root",
			"Head":				"bone_neck",
			"Left_Shoulder":	"bone_left_shoulder",
			"Left_Elbow":		"bone_left_upper_arm",
			"Left_Wrist":		"bone_left_forearm",
			"Left_Hand":		"bone_left_hand",
			"Left_Knee":		"bone_left_thigh",
			"Left_Ankle":		"bone_left_shin",
			"Left_Foot":		"bone_left_foot",
			"Right_Shoulder":	"bone_right_shoulder",
			"Right_Elbow":		"bone_right_upper_arm",
			"Right_Wrist":		"bone_right_forearm",
			"Right_Hand":		"bone_right_hand",
			"Right_Knee":		"bone_right_thigh",
			"Right_Ankle":		"bone_right_shin",
			"Right_Foot":		"bone_right_foot"
		}
		joint_connections = {
			"Chest":			"Pelvis",
			"Head":				"Neck",
			"Left_Shoulder":	"Chest",
			"Left_Elbow":		"Left_Shoulder",
			"Left_Wrist":		"Left_Elbow",
			"Left_Hand":		"Left_Wrist",
			"Left_Knee":		"Left_Hip",
			"Left_Ankle":		"Left_Knee",
			"Left_Foot":		"Left_Ankle",
			"Right_Shoulder":	"Chest",
			"Right_Elbow":		"Right_Shoulder",
			"Right_Wrist":		"Right_Elbow",
			"Right_Hand":		"Right_Wrist",
			"Right_Knee":		"Right_Hip",
			"Right_Ankle":		"Right_Knee",
			"Right_Foot":		"Right_Ankle"
		}
	rig.get_node("Neck").visible = not simple
	rig.get_node("Left_Hand").visible = not simple
	rig.get_node("Right_Hand").visible = not simple
	rig.get_node("Left_Foot").visible = not simple
	rig.get_node("Right_Foot").visible = not simple
	dock.get_node("MenuBar/Rig").get_popup().set_item_disabled(1, simple)
	dock.get_node("MenuBar/Rig").get_popup().set_item_checked(0, simple)
	if update_config:
		save_config()

func set_rotate_hands_with_thumbs(new_value := false, update_config := true) -> void:
	rotate_hands_with_thumbs = new_value
	if rotate_hands_with_thumbs:
		set_simple(false)
		bone_control_nodes["Left_Hand"] = "Left_Thumb"
		bone_control_nodes["Right_Hand"] = "Right_Thumb"
		bone_rotations["Left_Hand"] = 0
		bone_rotations["Right_Hand"] = 0
	else:
		bone_control_nodes["Left_Hand"] = "Control_Left_Arm"
		bone_control_nodes["Right_Hand"] = "Control_Right_Arm"
		bone_rotations["Left_Hand"] = -PI/2.0
		bone_rotations["Right_Hand"] = -PI/2.0
	dock.get_node("MenuBar/Rig").get_popup().set_item_disabled(0, rotate_hands_with_thumbs)
	dock.get_node("MenuBar/Rig").get_popup().set_item_checked(1, rotate_hands_with_thumbs)
	if update_config:
		save_config()

func set_clamp_origin_x(new_value := true, update_config := true) -> void:
	clamp_origin_x = new_value
	dock.get_node("MenuBar/Rig").get_popup().set_item_checked(3, clamp_origin_x)
	if update_config:
		save_config()

func set_clamp_origin_y(new_value := false, update_config := true) -> void:
	clamp_origin_y = new_value
	dock.get_node("MenuBar/Rig").get_popup().set_item_checked(4, clamp_origin_y)
	if update_config:
		save_config()

func set_clamp_origin_z(new_value := true, update_config := true) -> void:
	clamp_origin_z = new_value
	dock.get_node("MenuBar/Rig").get_popup().set_item_checked(5, clamp_origin_z)
	if update_config:
		save_config()

func set_height_offset(new_value := 0.0, update_config := true) -> void:
	height_offset = new_value
	update_height_offset_text()
	if update_config:
		save_config()

func set_show_joints(new_value := true, update_config := true) -> void:
	show_joints = new_value
	var mat := preload("Joint.tres")
	mat.albedo_color = Color(mat.albedo_color.r, mat.albedo_color.g, mat.albedo_color.b, int(show_joints))
	dock.get_node("MenuBar/View").get_popup().set_item_checked(0, show_joints)
	if update_config:
		save_config()

func set_show_bones(new_value := true, update_config := true) -> void:
	show_bones = new_value
	var mat := preload("Bone.tres")
	mat.albedo_color = Color(mat.albedo_color.r, mat.albedo_color.g, mat.albedo_color.b, int(show_bones))
	dock.get_node("MenuBar/View").get_popup().set_item_checked(1, show_bones)
	if update_config:
		save_config()

func set_show_bone_axes(new_value := true, update_config := true) -> void:
	show_bone_axes = new_value
	var mat := preload("Axis.tres")
	mat.albedo_color = Color(mat.albedo_color.r, mat.albedo_color.g, mat.albedo_color.b, int(show_bone_axes))
	dock.get_node("MenuBar/View").get_popup().set_item_checked(2, show_bone_axes)
	if update_config:
		save_config()

func update_height_offset_text() -> void:
	dock.get_node("MenuBar/Rig/ConfirmationDialog/HeightOffset").text = str(height_offset)

func save_config() -> void:
	config.load("user://config.cfg")
	config.set_value("osc", "ip", ip)
	config.set_value("osc", "port", port)
	config.set_value("rig", "simple", simple)
	config.set_value("rig", "rotate_hands_with_thumbs", rotate_hands_with_thumbs)
	config.set_value("rig", "clamp_origin_x", clamp_origin_x)
	config.set_value("rig", "clamp_origin_y", clamp_origin_y)
	config.set_value("rig", "clamp_origin_z", clamp_origin_z)
	config.set_value("rig", "height_offset", height_offset)
	config.set_value("view", "show_joints", show_joints)
	config.set_value("view", "show_bones", show_bones)
	config.set_value("view", "show_bone_axes", show_bone_axes)
	config.save("user://config.cfg")

func on_frame_pre_draw() -> void:
	if transforming:
		spinner = (spinner + (3 if recording_animation else 1)) % (8 * 5)
		dock.get_node("MenuBar/Disconnect").icon = spinner_icons[spinner / 5]

func on_selection_changed() -> void:
	if nimate_node:
		nimate_node.disconnect("variable_changed", self, "on_selection_changed")
		nimate_node = null
	if get_editor_interface().get_selection().get_selected_nodes().size() > 0:
		var new_nimate_node: Node
		var number_of_nimate_nodes := 0
		for node in get_editor_interface().get_selection().get_selected_nodes():
			if node.get_script() == preload("ni_mate_node.gd"):
				if number_of_nimate_nodes > 0:
					clear()
					return
				else:
					new_nimate_node = node
					number_of_nimate_nodes += 1
		if new_nimate_node:
			nimate_node = new_nimate_node
			nimate_node.connect("variable_changed", self, "on_selection_changed")
			if nimate_node.has_node(nimate_node.get("skeleton")) and nimate_node.has_node(nimate_node.get("animation_player")):
				dock.get_node("MenuBar").visible = true
				dock.get_node("ViewportContainer").visible = true
				dock.get_node("ErrorSelect").visible = false
				dock.get_node("ErrorMissing").visible = false
			else:
				dock.get_node("MenuBar").visible = false
				dock.get_node("ViewportContainer").visible = false
				dock.get_node("ErrorSelect").visible = false
				dock.get_node("ErrorMissing").visible = true
		else:
			clear()
	else:
		clear()

func clear() -> void:
	dock.get_node("MenuBar").visible = false
	dock.get_node("ViewportContainer").visible = false
	dock.get_node("ErrorSelect").visible = true
	dock.get_node("ErrorMissing").visible = false
	record(false)

func rig_id_pressed(id: int) -> void:
	match id:
		0:
			set_simple(not simple)
		1:
			set_rotate_hands_with_thumbs(not rotate_hands_with_thumbs)
		3:
			set_clamp_origin_x(not clamp_origin_x)
		4:
			set_clamp_origin_y(not clamp_origin_y)
		5:
			set_clamp_origin_z(not clamp_origin_z)
		7:
			dock.get_node("MenuBar/Rig/ConfirmationDialog").popup()

func view_id_pressed(id: int) -> void:
	match id:
		0:
			set_show_joints(not show_joints)
		1:
			set_show_bones(not show_bones)
		2:
			set_show_bone_axes(not show_bone_axes)

func confirm_connect() -> void:
	var ip: String = dock.get_node("MenuBar/Connect/ConfirmationDialog/HBoxContainer2/IPAddress").text
	var port := int(dock.get_node("MenuBar/Connect/ConfirmationDialog/HBoxContainer2/Port").text)
	set_ip(ip)
	set_port(port)
	listen(true)

func confirm_height_offset() -> void:
	set_height_offset(float(dock.get_node("MenuBar/Rig/ConfirmationDialog/HeightOffset").text))

func listen(listen: bool) -> void:
	if listen:
		if ip and port:
			var err: int = udp.listen(port, ip)
			if err == OK:
				dock.get_node("MenuBar/Record").disabled = false
				dock.get_node("MenuBar/Connect").visible = false
				dock.get_node("MenuBar/Disconnect").visible = true
			else:
				dock.get_node("MenuBar/Connect/AcceptDialog").popup()
		else:
			dock.get_node("MenuBar/Connect/AcceptDialog").popup()
	else:
		udp.close()
		dock.get_node("MenuBar/Record").disabled = true
		dock.get_node("MenuBar/Connect").visible = true
		dock.get_node("MenuBar/Disconnect").visible = false

func record(record: bool, save := false) -> void:
	if record:
		dock.get_node("MenuBar/Record").visible = false
		dock.get_node("MenuBar/Save").visible = true
		dock.get_node("MenuBar/Disconnect").disabled = true
		dock.get_node("ViewportContainer/ReferenceRect").visible = true
		nimate_node.get_node(nimate_node.get("animation_player")).stop()
		recording_animation = Animation.new()
		recording_animation.loop = true
		for key in joint_maps:
			recording_animation.track_set_path(recording_animation.add_track(Animation.TYPE_TRANSFORM), ".:" + nimate_node.get(joint_maps[key]))
	else:
		dock.get_node("MenuBar/Record").visible = true
		dock.get_node("MenuBar/Save").visible = false
		dock.get_node("MenuBar/Disconnect").disabled = false
		dock.get_node("ViewportContainer/ReferenceRect").visible = false
		frame = -1
		if save:
			var t := OS.get_datetime()
			var n := "Recording " + str(t.year) + "." + ("0" if t.month < 10 else "") + str(t.month) + "." + ("0" if t.day < 10 else "") + str(t.day) + " " + ("0" if t.hour < 10 else "") + str(t.hour) + "-" + ("0" if t.minute < 10 else "") + str(t.minute) + "-" + ("0" if t.second < 10 else "") + str(t.second) + "." + str(OS.get_ticks_msec())
			for i in 15:
				if recording_animation.track_get_path(i).get_subname_count() == 0:
					recording_animation.remove_track(i)
			nimate_node.get_node(nimate_node.get("animation_player")).add_animation(n, recording_animation)
			nimate_node.get_node(nimate_node.get("animation_player")).play(n)
		recording_animation = null

func transform_control(control: Spatial, a: Spatial, b: Spatial, c: Spatial, t = null) -> void:
	var side1 := b.global_transform.origin - a.global_transform.origin
	var side2 := c.global_transform.origin - a.global_transform.origin
	var n := side1.cross(side2)
	if t:
		control.global_transform = Transform(Basis(), t + n.normalized()*100.0)
	else:
		control.global_transform = Transform(Basis(), (a.global_transform.origin + b.global_transform.origin + c.global_transform.origin)/3.0 + n.normalized()*100.0)

class PacketReader:
	var ser_des := StreamPeerBuffer.new()
	var first = null
	var second = null
	func _init() -> void:
		ser_des.big_endian = true
	func read_byte(data) -> void:
		var length := Array(data).find(0)
		var next_data := int(ceil((length + 1) / 4.0) * 4)
		first = Array(data.subarray(0, length - 1))
		second = Array(data.subarray(next_data, -1))
	func read_string(_data) -> void:
		# Unused for now
		pass
	func read_blob(_data) -> void:
		# Unused for now
		pass
	func read_int(data) -> void:
		if len(data) < 4:
			printerr("Error: too few bytes for int", data, len(data))
			first = 0
			second = Array(data)
		else:
			ser_des.set_data_array(data.subarray(0, 3))
			first = ser_des.get_32()
			if len(data) > 4:
				second = Array(data.subarray(4, -1))
			else:
				second = null
	func read_long(_data) -> void:
		# Unused for now
		pass
	func read_double(_data) -> void:
		# Unused for now
		pass
	func read_float(data) -> void:
		if len(data) < 4:
			printerr("Error: too few bytes for float", data, len(data))
			first = 0.0
			second = Array(data)
		else:
			ser_des.set_data_array(data.subarray(0, 3))
			first = ser_des.get_float()
			if len(data) > 4:
				second = Array(data.subarray(4, -1))
			else:
				second = null
	func decode_osc(data: PoolByteArray) -> Array:
		read_byte(data)
		var address = first
		var rest = second
		var decoded := []
		if len(rest) > 0:
			read_byte(PoolByteArray(rest))
			var typetags = first
			rest = second
			decoded.append(address)
			decoded.append(typetags)
			if len(typetags) > 0:
				if char(typetags[0]) == ',':
					for tag in PoolByteArray(typetags).subarray(1, -1):
						match char(tag):
							"i": read_int(PoolByteArray(rest))
							"f": read_float(PoolByteArray(rest))
							"s": read_string(PoolByteArray(rest))
							"b": read_blob(PoolByteArray(rest))
							"d": read_double(PoolByteArray(rest))
						var value = first
						rest = second
						decoded.append(value)
				else:
					printerr("Oops, typetag lacks the magic")
		return decoded
