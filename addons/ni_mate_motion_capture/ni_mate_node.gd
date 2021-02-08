#*******************************************************************************#
#  ni_mate_node.gd                                                              #
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
extends Node

var bone_root: String
var bone_neck: String
var bone_left_shoulder: String
var bone_left_upper_arm: String
var bone_left_forearm: String
var bone_left_hand: String
var bone_left_thigh: String
var bone_left_shin: String
var bone_left_foot: String
var bone_right_shoulder: String
var bone_right_upper_arm: String
var bone_right_forearm: String
var bone_right_hand: String
var bone_right_thigh: String
var bone_right_shin: String
var bone_right_foot: String
var bone_rotation_root: String

export(NodePath) onready var skeleton: NodePath setget _skeleton_set
export(NodePath) onready var animation_player: NodePath setget _animation_player_set

signal variable_changed

func _get_property_list() -> Array:
	return [
		{name = "Bone Names", type = TYPE_NIL, hint_string = "bone_", usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE},
		{name = "bone_root", type = TYPE_STRING, usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE},
		{name = "bone_neck", type = TYPE_STRING, usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE},
		{name = "bone_left_shoulder", type = TYPE_STRING, usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE},
		{name = "bone_left_upper_arm", type = TYPE_STRING, usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE},
		{name = "bone_left_forearm", type = TYPE_STRING, usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE},
		{name = "bone_left_hand", type = TYPE_STRING, usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE},
		{name = "bone_left_thigh", type = TYPE_STRING, usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE},
		{name = "bone_left_shin", type = TYPE_STRING, usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE},
		{name = "bone_left_foot", type = TYPE_STRING, usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE},
		{name = "bone_right_shoulder", type = TYPE_STRING, usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE},
		{name = "bone_right_upper_arm", type = TYPE_STRING, usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE},
		{name = "bone_right_forearm", type = TYPE_STRING, usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE},
		{name = "bone_right_hand", type = TYPE_STRING, usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE},
		{name = "bone_right_thigh", type = TYPE_STRING, usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE},
		{name = "bone_right_shin", type = TYPE_STRING, usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE},
		{name = "bone_right_foot", type = TYPE_STRING, usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE}
	]

func _skeleton_set(new_value: NodePath) -> void:
	if not has_node(new_value) or get_node(new_value) is Skeleton:
		skeleton = new_value
		emit_signal("variable_changed")
	else:
		printerr("Selected node is not a Skeleton")

func _animation_player_set(new_value: NodePath) -> void:
	if not has_node(new_value) or get_node(new_value) is AnimationPlayer:
		animation_player = new_value
		emit_signal("variable_changed")
	else:
		printerr("Selected node is not an AnimationPlayer")
