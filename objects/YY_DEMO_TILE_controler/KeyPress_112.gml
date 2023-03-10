/// @description Clear layer in the room
if (!initialized) exit;
show_debug_message("[YY] Demo log: Pressed [F1] to clear the layer called 'Instances'");

// clear the layer at runtime
var _layer_id = layer_get_id("Tiles");
var _map_id   = layer_tilemap_get_id(_layer_id);
tilemap_clear(_map_id, 0);