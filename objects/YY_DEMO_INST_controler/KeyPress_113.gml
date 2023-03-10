/// @description Write the yy_room data to the associated file
show_debug_message("[YY] Demo log: Pressed [F2] updating room " + room_get_name(room) + ".yy file in GM directory.");

// update room_struct, in case user has modified the file by him/herself (like clicking save)
room_struct = new yy_room(gm_directory, room_get_name(room));
if room_struct.is_set() initialized = true;

// exit in case of error
if (!initialized) exit;

// cache room_struct
var _room_struct = room_struct;

// get reference to the layer in yy_room data
var _layer = _room_struct.get_layer("Instances");
show_debug_message("Clear before");

// clear the layer in yy_room data
_room_struct.layer_instances_clear(_layer);

// inspect all instances from YY_DEMO_object1 and create them in yy file
with(YY_DEMO_object1)
{
	// create instance and passed a struct to set instance's variables
	var _inst = _room_struct.instance_create(x, y, _layer, object_get_name(object_index), { image_xscale : image_xscale });
	// set instance's variables (can also be done with a struct in instance_create() like above)
	_room_struct.instance_set_property(_inst, "image_yscale", image_yscale);
	_room_struct.instance_set_property(_inst, "image_angle",  image_angle);
	_room_struct.instance_set_property(_inst, "my_var_def",   my_var_def);
}

// save yy_room data back to the room .yy file
_room_struct.save_to_directory();

// log
show_debug_message("[YY] Demo log: Game Maker Editor should be asking you to save or reload: " + 
                   "'Changes detected...' popup. " +
				   "Click the [Reload] button inside Game Maker Editor, so that your changes are updated.");


/* Universal serialization code for all objects in the room
with(all)
{
	if (layer == -1 or layer == undefined) continue
	var _inst = _room_struct.instance_create(x, y, layer_get_name(layer), object_get_name(object_index), 
	{ image_xscale : other.image_xscale, image_yscale : other.image_yscale, image_angle : other.image_angle, image_blend : other.image_blend });
}
_room_struct.save_to_directory();