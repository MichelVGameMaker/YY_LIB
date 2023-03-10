/// @description Write the yy_room data to the associated file
show_debug_message("[YY] Demo log: Pressed [F2] updating room " + room_get_name(room) + ".yy file in GM directory.");

// update room_struct, in case user has modified the file by him/herself (like clicking save)
room_struct = new yy_room(gm_directory, room_get_name(room));
if room_struct.is_set() initialized = true;

// exit in case of error
if (!initialized) exit;

// cache tiles data
var _layer_id = layer_get_id("Tiles");
var _map_id   = layer_tilemap_get_id(_layer_id);
var _width    = tilemap_get_width(_map_id);
var _height   = tilemap_get_height(_map_id);
var _map_data = array_create();
for (var _j = 0; _j < _height; _j++)
{
	for (var _i = 0; _i < _width; _i++)
	{
		array_push(_map_data, tilemap_get(_map_id, _i, _j));
	}
}

// cache room_struct
var _room_struct = room_struct;

// get reference to the layer in yy_room data
var _layer = _room_struct.get_layer("Tiles");

// clear the layer in yy_room data
_room_struct.layer_tiles_data_set(_layer, _width, _height, _map_data)

// save yy_room data back to the room .yy file
_room_struct.save_to_directory();

// log
show_debug_message("[YY] Demo log: Game Maker Editor should be asking you to save or reload" + 
                   ": 'Changes detected...' popup. " +
				   "Click the [Reload] button, close the room and reopen it inside Game Maker Editor, so that your changes are updated.");