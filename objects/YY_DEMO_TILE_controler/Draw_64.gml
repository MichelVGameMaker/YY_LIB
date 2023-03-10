/// @description Display Instructions

if (initialized)	
{
	draw_text(10, 10, "Welcome to YY_DEMO: This is the room 2/2 to showcase Tile features:\n" +
	                  ">Spawn tiles in a room at at runtime and then save them to update the .YY room file.\n" + 
					  ">[F4] to change to the room 1/2 for Instance features.");
	draw_text(10, 90, "[F1] to clear the layer called 'Tiles'.\n" +
	                  "[Left-click] to create tile  at mouse coordinates.\n" +
					  "[Right-click] to delete tile at mouse coordinates.\n" +
	                  "[F2] to save updated room to" + room_get_name(room) + ".yy file\n" +
					  "->Game Maker will ask you to reload those changes, 'Changes detected...',\n" +
					  "Click the [Reload] button, close the room and reopen it inside Game Maker Editor." +
					  "NB: yes, you need to close and reopen the room" + room_get_name(room) + "inside Game Maker Editor.");
}
else
{
	draw_text(10, 10,"Welcome to YY_DEMO:\n" +
	                 "Error: Game Maker Project directory " + string(gm_directory) + " cannot be accessed.\n" +
					 "It is likely you have not disabled Project Sandbox. The demo will not start.");
}