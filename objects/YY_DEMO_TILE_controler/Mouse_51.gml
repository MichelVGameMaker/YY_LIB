/// @description Clear tile
if (!initialized) exit;

var _layer_id = layer_get_id("Tiles");
var _map_id   = layer_tilemap_get_id(_layer_id);

// Clear a tile
if (tilemap_get_at_pixel(_map_id, mouse_x, mouse_y) != 0) 
{
	tilemap_set_at_pixel(_map_id, 0, mouse_x, mouse_y);
	show_debug_message("[YY] Demo log: Right-click clears a tile at runtime and in yy_room data.");
}