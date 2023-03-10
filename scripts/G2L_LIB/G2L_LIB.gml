#macro L2G_LDTK_STRUCT        global.__L2G_LDTK_STRUCT			// Temporary struct holding the data parsed from LDtk file, when processing any relating operations (comparing Staging and LDtk file or pushing changes to LDtk file).
#macro L2G_GM_PROJECT_DIR     global.__L2G_GM_PROJECT_DIR		// Directory of the source Game Maker project.
#macro L2G_LDTK_FILE_PATH     global.__L2G_LDTK_FILE_PATH		// Path to the destination LDtk file.
#macro L2G_USER_FILE          "L2G_data.ini"					// File name for saving/loading user preferences.
#macro L2G_CONFIG_FILE        "L2G_config.json"					// File name for saving/loading LDtk parsing configuration.
#macro L2G_LDTK_CONFIG		  global.__ldtk_config
#macro L2G_UI_DATA			  global.__L2G_UI_DATA	
#macro L2G_DATABASE			  global.__L2G_DATABASE				// Levels database
#macro L2G_LDTK_UPDATE_KEYS	  keyboard_check(vk_control) and keyboard_check(vk_f1) 
#macro LDTK_FILE_HASH         global.__live_update_timer 

L2G_init_service();
L2G_user_load_ldtk_config(); // Path loading is not consistent with SNAP so I run the ini load after
//L2G_load_user_preferences();
L2G_ld_file_to_ld_struct();

#region L2G draft


function L2G_init_service()
{
	L2G_LDTK_CONFIG = 
	{
		ldtk_file:      "",			// Path to the LDtk file.
		directory:      "", 		// Path to the Game Maker directory.
		//level_name:     "",		// argument passed into LDtkLoad > config.level_name > current room level name
		live_frequency: 15,			// frequency to check if the source LDtk file has been update
		live_update:    false,
		blueprint_room: undefined,	// defined, the buleprint mode is enabled: all levels will be loaded using the same Game Maker room specified here
		escape_fields:  true,		// write loaded fields/variables into isolated struct to be reloaded at create event
									// (so that they don't get overwritten by Variable Definitions)
									// you will have to call LDtkReloadFields() somewhere in the Create Event
	
		// also note that LDtk defaults to the first letter being uppercase, this can be changed in the LDtk settings
		room_prefix:   "r",
		object_prefix: "o",
		stacked_tiles_support: false, // Whether stacked tiles will create new tilemaps (true) or overwrite tiles underneath (false)
		mappings: { // if a mapping doesn't exist - ldtk name (with a prefix) is used
			levels: { // ldtk_level_name -> gm_room_name
			},
			layers: { // ldtk_layer_name -> gm_room_layer_name
				Entities: "Instances"
			},
			enums: { // ldtk_enum_name -> { ldtk_enum_value -> gml_value }
			},
			entities: { // ldtk_entity_name -> gm_object_name
			},
			fields: { // ldtk_entity_name -> { ldtk_entity_field_name -> gm_instance_variable_name }
			},
			tilesets: { // ldtk_tileset_name -> gm_tileset_name
			}
		},
	}
	L2G_UI_DATA	=
	{
		tab : 0,
		popup_text : "",
		popup_active: false,
		import_levels: [],
		selector : new L2G_Asset_Selector(undefined),
	};
	L2G_DATABASE = {
		current_level  : undefined,
		level_database : {},
	};
	LDTK_FILE_HASH = "";
	L2G_LDTK_STRUCT = undefined;
}
function L2G_load_user_preferences()
{
	if !file_exists(L2G_USER_FILE) 
	{
		L2G_GM_PROJECT_DIR = undefined;
		L2G_LDTK_FILE_PATH = undefined;
		show_debug_message("[L2G] Warning: user preference file (" + string(L2G_USER_FILE) + ") does not exist. GMS source project folder and LDtk destination file will need to be defined before exporting.");
		exit;
	}
	ini_open(L2G_USER_FILE);
	L2G_GM_PROJECT_DIR = ini_read_string("Paths","GM_PROJECT_DIR", "");
	L2G_LDTK_FILE_PATH = ini_read_string("Paths","LDTK_FILE_PATH", "");
	if L2G_GM_PROJECT_DIR = "" L2G_GM_PROJECT_DIR = undefined;
	else 		L2G_LDTK_CONFIG.directory = L2G_GM_PROJECT_DIR;
	if L2G_LDTK_FILE_PATH = "" L2G_LDTK_FILE_PATH = undefined;
	else 		L2G_LDTK_CONFIG.ldtk_file = L2G_LDTK_FILE_PATH;
	ini_close();	
	if (L2G_GM_PROJECT_DIR !=  undefined) 
	{ 
		show_debug_message("[L2G] log: GMS source project folder retrieved from user preferences (" + string(L2G_USER_FILE) + ") and set to [" + string(L2G_GM_PROJECT_DIR) + "].");
	}
	if (L2G_LDTK_FILE_PATH !=  undefined) 
	{ 
		show_debug_message("[L2G] log: LDtk destination file retrieved from user preferences (" + string(L2G_USER_FILE) + ") and set to [" + string(L2G_LDTK_FILE_PATH) + "].");
	}
		/*
	var _obj_struct = new yy_object(L2G_GM_PROJECT_DIR, "oSCR_Room_Transition_Horizontal");
	var _prop = yy_property("door_id", "undefined", YY_varType.Integer);
	_obj_struct.add_property(_prop);
	//var _prop = yy_property("target_door", "undefined", YY_varType.Integer);
	//_obj_struct.add_property(_prop);
	//var _prop = yy_property("target_room", "undefined", YY_varType.Integer);
	//_obj_struct.add_property(_prop);
	shw(SnapToJSON(_obj_struct, true));
	_obj_struct.save_to_directory(true);*/
}
function L2G_user_select_gm_project_dir()									// This function prompts user to select a Game Maker project and saves its directory (jsut the folder, not the full path) in the LDtk parser data.
{
	var _file   = get_open_filename_ext("Project file|*.yyp", "", "", "Select the Game Maker .yy project file to set the associated folder");
	if (_file != "")
	{
		L2G_LDTK_CONFIG.directory = filename_dir(_file);
		L2G_GM_PROJECT_DIR        = filename_dir(_file);		
		ini_open(L2G_USER_FILE);
		ini_write_string("Paths","GM_PROJECT_DIR",L2G_GM_PROJECT_DIR);
		ini_close();
		show_debug_message("[L2G] log: Game Maker project directory is set to [" + string(L2G_GM_PROJECT_DIR) + "].");
		show_debug_message("[L2G] log: Game Maker project directory is set to [" + string(L2G_LDTK_CONFIG.directory) + "].");
		L2G_user_save_ldtk_config();
	}	
	else
	{
		show_debug_message("[L2G] log: User aborted the selection of Game Maker project directory. Current directory is set to [" + string(L2G_GM_PROJECT_DIR) + "].");
	}
}
function L2G_user_select_ldtk_file_path()									// This function prompts user to select a LDtk file and saves it path in the LDtk parser data.
{
	var _file   = get_open_filename_ext("*.ldtk", "", "", "Select the LDtk file");

	if (_file != "")
	{
		L2G_LDTK_CONFIG.ldtk_file = _file;
		L2G_LDTK_FILE_PATH        = _file;		
		ini_open(L2G_USER_FILE);
		ini_write_string("Paths","LDTK_FILE_PATH",L2G_LDTK_FILE_PATH);
		ini_close();
		show_debug_message("[L2G] log: LDtk file is set to [" + L2G_LDTK_FILE_PATH + "].");
		show_debug_message("[L2G] log: LDtk file is set to [" + string(L2G_LDTK_CONFIG.ldtk_file) + "].");
		L2G_user_save_ldtk_config();
	}	
	else
	{
		show_debug_message("[L2G] log: User aborted the selection of LDtk file. Current file is set to [" + string(L2G_LDTK_FILE_PATH) + "].");
	}
}
function L2G_user_save_ldtk_config()										// This function saves the LDtk parser data from the struct to the associated file.
{
	SnapStringToFile(SnapToJSON(L2G_LDTK_CONFIG), L2G_CONFIG_FILE);
}
function L2G_user_load_ldtk_config()										// This function loads the LDtk parser data from the file to the associated struct.
{
	if !file_exists(L2G_CONFIG_FILE) 
	{
		show_debug_message("[L2G] Warning: configuration file (" + string(L2G_CONFIG_FILE) + ") does not exist. LDtk import configuration is set to default (as defined in the code).");
		exit;
	}
	L2G_LDTK_CONFIG           = SnapFromJSON(SnapStringFromFile(L2G_CONFIG_FILE));
	show_debug_message("[L2G] log: LDtk import configuration is set to [" + string(L2G_LDTK_CONFIG) + "].");
}
function L2G_ld_file_to_ld_struct()							// This function parses the destination LDtk file to an internal struct that will be modified later on accordingly to user's choices, and then write back to the file.
{
	if L2G_LDTK_CONFIG.ldtk_file == undefined										// Manage exception if the destination LDtk file is not defined. Later operations will be impossible (comparing Staging and LDtk file or pushing changes to LDtk file).
	{
		show_debug_message("[L2G] Error! L2G_ld_file_to_ld_struct() Could not create structured data from LDtk file, because this file path is not defined [" + string(L2G_GM_PROJECT_DIR) + "].");
		return false;
	}
	var _hash = md5_file(L2G_LDTK_CONFIG.ldtk_file)	
	if (_hash != LDTK_FILE_HASH) 
	{
		__LDtkTrace("Updating data...");
		L2G_LDTK_STRUCT = SnapFromJSON(SnapStringFromFile(L2G_LDTK_CONFIG.ldtk_file));	// Parse the destination LDtk file to a temporary struct.
		LDTK_FILE_HASH = _hash;
	}
	else
	__LDtkTrace("Keeping data. File did not change since last time.");
	return true;
}


#endregion

#region L2G window	------------------------------------------------------------------------
function L2G_imguigml_step() {
	if L2G_LDTK_UPDATE_KEYS 
	{
		ENGINE.transition_ldtk_run_to_room(L2G_DATABASE.current_level, undefined, PLAYER.x, PLAYER.y);
	}
	imguigml_set_next_window_pos(0, 0, EImGui_Cond.Once);
	imguigml_set_next_window_size(300, 300, EImGui_Cond.Once);
	var _input;	
	var _width, _height;
	var _struct = L2G_LDTK_CONFIG;
	var _arr = []
	array_push(_arr, [0, 1]);
	array_push(_arr, [0, 1]);

	// Navigation tabs
	imguigml_columns(4, undefined, false);
	_width  = imguigml_get_column_width();
	_height = 25;
	if imguigml_button("Navigation",    _width, _height)  L2G_UI_DATA.tab = 0;
	imguigml_next_column();
	if imguigml_button("File & Options", _width, _height) L2G_UI_DATA.tab = 1;
	imguigml_next_column();
	if imguigml_button("Mappings",     _width, _height)   L2G_UI_DATA.tab = 2;
	imguigml_next_column();
	if imguigml_button(".YY import",     _width, _height) L2G_UI_DATA.tab = 3;
	imguigml_columns(1)
	// Content
	imguigml_begin_child("Body", 0, 0, true); 
	switch(L2G_UI_DATA.tab)
	{
		case 0:	// Navigation
		{
			// Title
			imguigml_text("   Navigation");
			imguigml_separator();
			// Level name
			imguigml_text("Level:" + string(L2G_DATABASE.current_level));
			imguigml_begin_child("Level Restart", 0, 70, true); 
			// Refresh & restart buttons
			imguigml_columns(2, undefined, false);
			_width  = imguigml_get_column_width();
			_input = imguigml_button("Refresh", _width) ;
			if imguigml_is_item_hovered() imguigml_set_tooltip("Reload current level and keep player where it is");
			if _input 
			{
				ENGINE.transition_ldtk_run_to_room(L2G_DATABASE.current_level, undefined, PLAYER.x, PLAYER.y);
				/*engine_room_init_destroy_instances(); // home made cleaning of instance but not tiles
				LDtkLoad();
				with(oSYS_Room_Engine) {init_done = false;} */// to retrigger objecti nit
			} 
			imguigml_next_column();
			_input = imguigml_button("Restart", _width)
			if imguigml_is_item_hovered() imguigml_set_tooltip("Restart room and reload current level.");
			if _input 
			{
				ENGINE.transition_ldtk_run_to_room(L2G_DATABASE.current_level, -1);
			} 
			imguigml_columns(1);
			imguigml_end_child(); 
			// choose level
			imguigml_text("Load a level");
			imguigml_begin_child("Choose Level", 0, 0, true);
			_width  = imguigml_get_window_width();
			if L2G_LDTK_STRUCT != undefined 
			{
				imguigml_columns(2);
				var _len = array_length(L2G_LDTK_STRUCT.levels);
				for (var _i = 0; _i < _len; _i++) 
				{
					var _level_i = L2G_LDTK_STRUCT.levels[_i].identifier;
					if imguigml_button(_level_i+"##load"+string(_i), _width * 0.5)
					{
						ENGINE.transition_ldtk_run_to_room(_level_i, -1);		
					}
					imguigml_next_column();
					/*var _room_id = L2G_LDTK_CONFIG.blueprint_room;
					if _room_id == undefined
					{
						var _room_name = L2G_LDTK_CONFIG.mappings.levels[$ _level_name];
						if _room_name == undefined _room_name = L2G_LDTK_CONFIG.room_prefix + string(L2G_DATABASE.current_level);
						_room_id = asset_get_index(_room_name);
					}
					if room_exists(_room_id) 
					{
						room_goto(_room_id);
					}
					else 
					{
						L2G_UI_DATA.popup_text = "Error when loading level called (" + string(_level_name) + "). There is no room called (" +  string(_room_name) + ") in this Game Maker project."; 
						L2G_UI_DATA.popup_active = true;
					}*/
				}
				imguigml_columns(1);
			}
			else
			{
				imguigml_text("No levels data");
			}
			imguigml_end_child(); 
		}	
		break;
		case 1: // File
		{
			_width  = imguigml_get_window_width();
			// Title
			imguigml_text("   File & Options");
			imguigml_separator();
			// File selection
			imguigml_text("LDtk file");
			imguigml_begin_child("File selection", 0, 70, true); 
			imguigml_text_wrapped( "File:" + string(_struct.ldtk_file), _width); 
			_input = imguigml_button("Load .ldtk", _width)
			if imguigml_is_item_hovered() imguigml_set_tooltip("Select .ldtk file for furher imports.");
			if _input 
			{
				L2G_user_select_ldtk_file_path();
				L2G_ld_file_to_ld_struct();
				L2G_create_level_database();
			} 	
			imguigml_end_child();
			// Options
			imguigml_text("Parser options");
			imguigml_begin_child("Parser options", 0, 0, true); 
			_input = imguigml_checkbox("Auto refresh", L2G_LDTK_CONFIG.live_update);
			if imguigml_is_item_hovered() imguigml_set_tooltip("Automatic refresh the running room when changes are detected in .ldtk file");
			if(_input[0]) 
			{
				L2G_LDTK_CONFIG.live_update = _input[1];
				L2G_user_save_ldtk_config();
				if   _input[1] 
				{
					if !time_source_exists(global.__ldtk_time_source) 
					{
						global.__ldtk_time_source = time_source_create(time_source_global, L2G_LDTK_CONFIG.live_frequency, time_source_units_frames, function() {
							__LDtkLive()

						}, [], -1);
						time_source_start(global.__ldtk_time_source);
					}
					else       time_source_resume(global.__ldtk_time_source);
				}
				else           time_source_pause(global.__ldtk_time_source);
			}
			if L2G_LDTK_CONFIG.live_update
			{
				imguigml_same_line();
				_input = imguigml_slider_int("Refresh Frequency", L2G_LDTK_CONFIG.live_frequency, 0, 60); 
				if imguigml_is_item_hovered() imguigml_set_tooltip("Refresh frequency for automatic refresh");
				if(_input[0]) 
				{
					L2G_LDTK_CONFIG.live_frequency = _input[1];
					L2G_user_save_ldtk_config();
					if time_source_exists(global.__ldtk_time_source)
					{
						var _start = time_source_get_state(global.__ldtk_time_source) = time_source_state_active;
						time_source_reconfigure(global.__ldtk_time_source, L2G_LDTK_CONFIG.live_frequency, time_source_units_frames, function() {
							__LDtkLive()

						}, [], -1);	
						if _start time_source_start(global.__ldtk_time_source);
					}
				}
			}
			else
			{
				imguigml_text("(Refresh Frequency:"+string(L2G_LDTK_CONFIG.live_frequency)+")");
			}			
			imguigml_end_child();
		}
		break;

		case 2:	// Mappings
		{
			// Title
			imguigml_text("   Mappings");
			imguigml_separator();
			// Level name
			_width  = imguigml_get_window_width();
			imguigml_columns(4);
			if imguigml_button("Levels", imguigml_get_column_width(-1))   { mapping_name  = "levels"; L2G_UI_DATA.selector.set_type(asset_room); }
			imguigml_next_column();
			if imguigml_button("Layers", imguigml_get_column_width(-1))   { mapping_name  = "layers";  L2G_UI_DATA.selector.set_type(asset_unknown); L2G_UI_DATA.selector.set_scan_room(ROOM_LDTK_TEMPLATE); }
			imguigml_next_column();
			if imguigml_button("Entities", imguigml_get_column_width(-1)) { mapping_name  = "entities"; L2G_UI_DATA.selector.set_type(asset_object); }
			imguigml_next_column();
			if imguigml_button("Tilesets", imguigml_get_column_width(-1)) { mapping_name  = "tilesets"; L2G_UI_DATA.selector.set_type(asset_tiles); }
			//imguigml_next_column();	//imguigml_button("Fields")    mapping_name  = "fields";
			L2G_UI_DATA.selector.__process_scan(); // silent scan to update list
			imguigml_columns(1);	
			imguigml_separator();
			// header
			imguigml_text("Mappings for " + mapping_name);
			switch(mapping_name)
			{
				case "levels"   : 
					var _prefix = _struct.room_prefix;   // 15 janvier effacer ça j'utilsie le get mapping
					var _get_mapping = __LDtkMappingGetLevel;
					var _ldtk_struct = L2G_LDTK_STRUCT.levels;
					//var _assets = L2G_assets_scan( function(_index) { return room_exists(_index) });
					var _gm_type = "Room";
					var _asset = asset_room;
					break;
				case "layers"   : 
					var _prefix = "";// 15 janvier effacer ça j'utilsie le get mapping
					var _get_mapping = __LDtkMappingGetLayer;
					var _ldtk_struct = L2G_LDTK_STRUCT.defs.layers;
					layer_set_target_room(ROOM_LDTK_TEMPLATE);
					//var _assets = layer_get_all();
					layer_reset_target_room();
					var _gm_type = "Layer";
					var _asset = asset_unknown;
					break;
				case "entities" : 
					var _prefix = _struct.object_prefix;// 15 janvier effacer ça j'utilsie le get mapping
					var _get_mapping = __LDtkMappingGetEntity;
					var _ldtk_struct = L2G_LDTK_STRUCT.defs.entities;
					//var _assets = L2G_assets_scan( function(_index) { return object_exists(_index) });
					var _gm_type = "Object";
					var _asset = asset_object;
					break;
				case "tilesets" : 
					var _prefix = "";
					var _get_mapping = __LDtkMappingGetTileset;
					var _ldtk_struct = L2G_LDTK_STRUCT.defs.tilesets;
					//var _assets = [];
					var _gm_type = "Tileset";
					var _asset = asset_tiles;
					break;
				//case "fields"   : var _prefix = "";                    var _ldtk_struct = L2G_LDTK_STRUCT.levels; imguigml_text("Fields Mapping"); break;
			}	
			// Add Mappings
			imguigml_text("Add new mapping");
			imguigml_begin_child("Add new mapping", 0, 75, true); 
				// Add section - Header
				_width = imguigml_get_content_region_avail_width() - 40
				imguigml_columns(3, undefined ,false);
				imguigml_set_column_width(0, 0.5 * _width);
				imguigml_set_column_width(1, 0.5 * _width);
				imguigml_set_column_width(2, 40); 
				imguigml_text("From this in LDtk");
				imguigml_next_column();
				imguigml_text("To this in GM");
				imguigml_next_column();		
				imguigml_next_column();		
				// Add section - Body
				var _input   =  imguigml_input_text("##ld_item_txt", imguigml_mem("ld_item","ldtk_name"), 40);
				if _input[0] imguigml_memset("ld_item", _input[1]);
				imguigml_next_column();	
				var _output = imguigml_input_text("##gm_item_txt", imguigml_mem("gm_item","gm_name"), 40);
				if _output[0] imguigml_memset("gm_item", _output[1]);
				imguigml_next_column();	
				if imguigml_button("Add") and _input[1] != "" and _output[1] != ""
				{
					var _add_struct = { }
					_add_struct[$ mapping_name] = {};
					_add_struct[$ mapping_name][$ _input[1]] = _output[1];
					LDtkMappings(_add_struct);
					L2G_user_save_ldtk_config();
				} 
				imguigml_columns(1);	
			imguigml_end_child(); 
			
			// List of mappings that will be applied
			imguigml_text("List of mappings for " + mapping_name);
			imguigml_begin_child("Mappings", 0, 0, true); 
				// Mapping list header
				_width = imguigml_get_content_region_avail_width() - 40
				imguigml_columns(3, undefined ,false);
				imguigml_set_column_width(0, 0.5 * _width);
				imguigml_set_column_width(1, 0.5 * _width);
				imguigml_set_column_width(2, 40); 
				imguigml_text("From this in LDtk");
				imguigml_next_column();
				imguigml_text("To this in GM");
				imguigml_next_column();
				imguigml_text("asset");
				imguigml_next_column();
				var _level_names = [];

				// Mapping list rows
				if L2G_LDTK_STRUCT != undefined 
				{
					var _pop = -1;
					var _len = array_length(_ldtk_struct);
					for (var _i = 0; _i < _len; _i++) 
					{
						var _L2G_input_name  = _ldtk_struct[_i].identifier;
						//var _L2G_output_name = _struct.mappings[$ mapping_name][$ _L2G_input_name];
						var _L2G_output_name = string(_get_mapping(_L2G_input_name));
						/*if _L2G_output_name == undefined or _L2G_output_name = "" or ( _prefix != "" and string_char_at(_L2G_output_name, 1) != _prefix) // Not defined by user
						{
							_L2G_output_name = _prefix + _L2G_input_name;
						}
						else
						{
							_L2G_output_name = string(_L2G_output_name);
						}*/
						imguigml_text(_L2G_input_name);
						imguigml_next_column();
						_input = imguigml_input_text("##gm_asset_txt"+string(_i), imguigml_mem("gm_"+string(mapping_name)+string(_i), _L2G_output_name ), 40);
						if _input[0] and _input[1] != _prefix + _L2G_input_name and _input[1] !=  _struct.mappings[$ mapping_name][$ _L2G_input_name] 
						{
							imguigml_memset("gm_"+string(mapping_name)+string(_i), _input[1]);
							var _map_struct             = {};
							_map_struct[$ mapping_name] = {};
							_map_struct[$ mapping_name][$ _L2G_input_name] = _input[1];
							LDtkMappings(_map_struct);
							L2G_user_save_ldtk_config();
						}
						imguigml_next_column();
						//if array_find(_assets, asset_get_index(_input[1]))!= undefined 
						if L2G_UI_DATA.selector.asset_name_exists(_input[1]) { var _button = "ok##" + string(_i); var _tooltip = " does exist in the current Game Maker project."; }
						else                                                 { var _button = "!!##" + string(_i); var _tooltip = " does not exist in the current Game Maker project. Click to select another existing asset."; }
						if imguigml_small_button(_button) 
						{
							imguigml_open_popup("select_asset_pop"+string(_i));
						}
						if imguigml_is_item_hovered() imguigml_set_tooltip(_gm_type + " " + string(_input[1]) + _tooltip);	
						imguigml_next_column();
					// Mapping list pop up
	
					if imguigml_begin_popup("select_asset_pop"+string(_i))
					{
						imguigml_text(_gm_type + " Selection")
						//_input =  imguigml_combo("Choose a " + _gm_type, imguigml_mem("selected_asset",0), _asset_names);
						_input =  L2G_UI_DATA.selector.imguigml_step();
						//imguigml_list_box("##" + _gm_type, imguigml_mem("selected_asset",0), _asset_names, 10);
						if(_input[0]) 
						{
							//imguigml_memset("gm_"+string(mapping_name)+string(_i), _asset_names[_input[1]]);
							imguigml_memset("gm_"+string(mapping_name)+string(_i),_input[2]);
							var _map_struct             = {};
							_map_struct[$ mapping_name] = {};
							//_map_struct[$ mapping_name][$ _L2G_input_name] = _asset_names[_input[1]];
							_map_struct[$ mapping_name][$ _L2G_input_name] = _input[2];
							LDtkMappings(_map_struct);
							L2G_user_save_ldtk_config();
							//imguigml_close_current_popup()
						}
						imguigml_end_popup();		
					}
				}

			}

				imguigml_columns(1);
				// List of custom mappings	
				if imguigml_collapsing_header("Unused mappings, not in LDtk file")[0]
				{
					imguigml_columns(2);
					imguigml_text("From this in LDtk");
					imguigml_next_column();
					imguigml_text("To this in GM");
					imguigml_next_column();
					var _struct_names = variable_struct_get_names(_struct.mappings[$ mapping_name]);
					var _names_len    = array_length(_struct_names);
					for(var _i = 0; _i < _names_len; ++_i) 
					{
						var _L2G_input_name = _struct_names[_i];
						if array_find_with_struct_variable(_ldtk_struct, "identifier", _L2G_input_name) == undefined
						{
							var _L2G_output_name = string(_struct.mappings[$ mapping_name][$ _L2G_input_name]);
							if imguigml_small_button("-##"+string(_i)) 
							{
								variable_struct_remove(_struct.mappings[$ mapping_name],  _L2G_input_name)
								L2G_user_save_ldtk_config();
							}
							imguigml_same_line()
							imguigml_text(_L2G_input_name);
							imguigml_next_column();
							imguigml_text(_L2G_output_name);		
							imguigml_next_column();
						}
					}
					imguigml_columns(1);
				}
			imguigml_end_child(); 
		}
		break;
		case 3: // Import
		{
			_width  = imguigml_get_window_width();
			// Title
			imguigml_text("   .YY imports");
			imguigml_separator();
			imguigml_begin_child("Import", 0, 150, true); 
			imguigml_columns(1, undefined, false);
			imguigml_text("   File & Options");
			imguigml_separator();
			imguigml_text_wrapped( "Repo:" + string(L2G_LDTK_CONFIG.directory), _width); 
			_input = imguigml_button("Select Game Maker project", _width)
			if imguigml_is_item_hovered() imguigml_set_tooltip("Select Game Maker repository for further imports.");
			if _input 
			{
				L2G_user_select_gm_project_dir();
			} 	
			_width  = imguigml_get_column_width();
			_input = imguigml_button("Import Fields", _width) ;
			if imguigml_is_item_hovered() imguigml_set_tooltip("Import all fields definition into the target/current Game Maker project");
			if _input 
			{
				var _data = SnapFromJSON(SnapStringFromFile(L2G_LDTK_CONFIG.ldtk_file))
				L2G_import_all_ld_entities_fields_defs_2_gm_yy_objects(_data.defs.entities, L2G_LDTK_CONFIG.directory, true)
			} 
			if array_length(L2G_UI_DATA.import_levels) > 0
			{
				_input = imguigml_button("Import Levels", _width) ;
				if imguigml_is_item_hovered() imguigml_set_tooltip("Import selected LDtk levels into the target/current Game Maker project");
				if _input 
				{
					LDtk_import(L2G_LDTK_CONFIG.ldtk_file, L2G_LDTK_CONFIG.directory, L2G_UI_DATA.import_levels)
				} 
			}
			imguigml_end_child(); 
			// choose level
			imguigml_text("Select levels");
			imguigml_begin_child("Select levels", 0, 0, true);
			_width  = imguigml_get_window_width();
			if L2G_LDTK_STRUCT != undefined 
			{
				imguigml_columns(2);
				imguigml_set_column_width(0, 30);
				var _len = array_length(L2G_LDTK_STRUCT.levels);
				for (var _i = 0; _i < _len; _i++) 
				{
					var _level_i = L2G_LDTK_STRUCT.levels[_i].identifier;
					_input = imguigml_checkbox(_level_i+"##import"+string(_i), imguigml_mem("import"+string(_i), false)) ;
					if _input[0] 
					{
						imguigml_memset("import"+string(_i), _input[1]);
						if _input[1]
						{
							var _idx = array_find(L2G_UI_DATA.import_levels, string(_level_i));
							if _idx == -1 array_push(L2G_UI_DATA.import_levels, string(_level_i));
							shw(L2G_UI_DATA.import_levels)
						}
						else
						{
							var _idx = array_find(L2G_UI_DATA.import_levels, string(_level_i));
							if _idx != -1 array_delete(L2G_UI_DATA.import_levels, _idx, 1);
							shw(L2G_UI_DATA.import_levels)
						}
						
					}
					imguigml_next_column();
					imguigml_text(string(_level_i));
					imguigml_next_column();
				}
				imguigml_columns(1);
			}
			else
			{
				imguigml_text("No levels data");
			}
			imguigml_end_child(); 
		}
		break;
	}
	imguigml_end_child(); 
	
	if L2G_UI_DATA.popup_active { imguigml_open_popup("L2G_popup"); L2G_UI_DATA.popup_active = false; }
	if imguigml_begin_popup("L2G_popup")
	{
		imguigml_text(L2G_UI_DATA.popup_text)
		imguigml_end_popup()		
	}
	if !imguigml_is_popup_open("L2G_popup") { L2G_UI_DATA.popup_text = ""; }
	
	
}

#endregion

#region unused HYOMOTO helpers
/// @param _exists	The function to use to check if the asset exists
/// @param {Function} _filter	A function that, if true, omits this entry from the list.
function L2G_assets_scan( _exists, _filter = function( _a ) { return false; }) 
{
	var _array	= [];
	
	var _i = 0; while( _exists( _i )) 
	{
		if ( _filter( _i++ ) == false )	array_push( _array, _i - 1 );	
	}
	return _array;
}

function L2G_asset_get_name(_asset, _gm_type) 
{
	switch(_gm_type)
	{ 
		case "Room"    :
			return room_get_name(_asset);
			break;
		case "Layer"   : 
			return layer_get_name(_asset);
			break;
		case "Object" : 
			return object_get_name(_asset);
			break;
		case "Tileset" : 
			return tileset_get_name(_asset);
			break;
	}	
}
	
#endregion