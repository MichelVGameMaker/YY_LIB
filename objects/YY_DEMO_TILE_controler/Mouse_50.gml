/// @description Paint tile
if (!initialized) exit;

var _layer_id = layer_get_id("Tiles");
var _map_id   = layer_tilemap_get_id(_layer_id);

// Paint a tile
if (tilemap_get_at_pixel(_map_id, mouse_x, mouse_y) != 1) 
{
	tilemap_set_at_pixel(_map_id, 1, mouse_x, mouse_y);
	show_debug_message("[YY] Demo log: Left-click creates a tile at runtime and in yy_room data.");
}
