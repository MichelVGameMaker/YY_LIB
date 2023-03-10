/// @description Create yy_room with all data
show_debug_message("[YY] Demo log: YY_DEMO_controler's create event.");

gm_directory = filename_dir(GM_project_filename); // the directory of the Game Maker project
selection    = noone;
initialized  = true;

show_debug_message("[L2G] log: Testing " + string(gm_directory) + " directory.");

if !directory_exists(gm_directory)
{
	show_message("[L2G] error: Game Maker Project directory " + string(gm_directory) + " cannot be accessed. It is likely you have not disabled Project Sandbox. The demo will not start.");
	initialized = false;
}
else
{
	// Create a yy_room with all data from the current room for further updates using F1, F2, mouse-click
	show_debug_message("[YY] Demo log: storing all data from " + room_get_name(room) + " room in a struct. Ready to modify.");
	room_struct = new yy_room(gm_directory, room_get_name(room));
	if room_struct.is_set() initialized = true;
}