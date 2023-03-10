/// @description Higlight selection
if (!initialized) exit;
var _x = 32 * floor( mouse_x / 32);
var _y = 32 * floor( mouse_y / 32);
draw_rectangle(_x, _y, _x + 31, _y + 31, true)

