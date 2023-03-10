/// @description instance_create / selection
if (!initialized) exit;
show_debug_message("[YY] Demo log: Left-click creates an instance of YY_DEMO_object1 at runtime and in yy_room data.");

var _clicked = instance_position(mouse_x, mouse_y, YY_DEMO_object1)

// create instance at runtime
if (_clicked == noone)
{
	instance_create_layer(mouse_x, mouse_y, "Instances", YY_DEMO_object1);
	selection = noone;
}
else
{
	selection = _clicked;
}