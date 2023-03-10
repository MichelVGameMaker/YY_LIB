if (initialized)	
{
	draw_text(10, 10, "Welcome to YY_DEMO: This is the room 1/2 to showcase Instance features:\n" +
	                  ">Spawn objects in a room at runtile and then save them to update the .YY room file.\n" + 
					  ">[F4] to change to the room 2/2 for Tile features.");
	draw_text(10, 90, "[F1] to clear the layer called 'Instances'.\n" +
	                  "[Left-click] an empty area to create instances of YY_DEMO_object1.\n" +
					  "[Left-click] an instance to select it and then,\n" +
	                  " - [arrows] to change scales, [space] to increment my_var, [return] to rotate.\n" +
					  " - [F2] to save updated room to" + room_get_name(room) + ".yy file\n" +
					  "->Game Maker will ask you to reload those changes, 'Changes detected...',\n" +
					  "Click the [Reload] button and the room will be updated inside Game Maker Editor.");
}
else
{
	draw_text(10, 10,"Welcome to YY_DEMO:\n" +
	                 "Error: Game Maker Project directory " + string(gm_directory) + " cannot be accessed.\n" +
					 "It is likely you have not disabled Project Sandbox. The demo will not start.");
}