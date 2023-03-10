// REMEMBER TO TURN ON "disable file system sandbox" WHEN USING LIVE UPDATING

// #macro LDTK_LIVE false
// #macro LDTK_LIVE_FREQUENCY 15

#macro LDTK_IMPORT_LAYERS_CLEAR     false // clear all existing layers
#macro LDTK_IMPORT_INSTANCES_CLEAR  true  // clear existing instances on existing layers
#macro LDTK_IMPORT_TILES_CLEAR      true  // clear existing tiles on existing layers
#macro LDTK_LAYER_CREATE            false // create a layer if it does not currently exist
#macro LDTK_BACKGROUND_CREATE       true // create a background layer, beware if you LAYERS_CLEAR 
#macro LDTK_OBJECT_INDEX_OVERRIDE   true
#macro LDTK_FIELD_SKIP_UNDEFINED    true
#macro LDTK_FIELD_SKIP_EMPTY_ARRAY  true
#macro LDTK_CLEAR_TILE_MAP          true

global.__live_update_timer          = -1
global.__live_update_update_pending = false
global.__ldtk_entities              = {};
global.__ldtk_time_source           = noone;
// Set up live reloading
if ( variable_global_exists("__ldtk_config") and L2G_LDTK_CONFIG.live_update )
{
	global.__ldtk_time_source = time_source_create(time_source_global, L2G_LDTK_CONFIG.live_frequency, time_source_units_frames, function() { __LDtkLive(); }, [], -1)
	time_source_start(global.__ldtk_time_source)
}


	
///@function	LDtkConfig(_config)
///@description Changes some _config variables
function LDtkConfig(_config) {
	var config_names = variable_struct_get_names(_config)
	
	for(var _i = 0; _i < array_length(config_names); ++_i) {
		var config_name = config_names[_i]
		var config_value = variable_struct_get(_config, config_name)
		
		if (config_name == "mappings") {
			// nested struct
			LDtkMappings(config_value)
		}
		else {
			variable_struct_set(L2G_LDTK_CONFIG, config_name, config_value)
		}
	}
}

///@function	LDtkMappings(mappings)
///@description	Updates __ldtk_config.mappings
function LDtkMappings(mappings) {
	__LDtkDeepInheritVariables(mappings, L2G_LDTK_CONFIG.mappings)
}

///@function	LDtkLoad([level_name])
///@description	Loads a level from an LDtk project
///@param		{string} [level_name]
function LDtkLoad(level_name) {
	__LDtkTrace("Log: Starting to load...")
	var _config = L2G_LDTK_CONFIG;
	// Exception : no LDtk file
	var file = _config.ldtk_file
	if (!file_exists(file)) 
	{
		if (global.__live_update_update_pending) 
		{
			global.__live_update_update_pending = false;
			__LDtkTrace("Error! Live Updated Failed. LDtk project file <%> is not specified or file does not exist.", string(file));
		} 
		else 
		{
			__LDtkTrace("Error! LDtk project file <%> is not specified or file does not exist!", string(file));
		}
		return false;
	}	
	L2G_ld_file_to_ld_struct();
	// Load data from file
	data = L2G_LDTK_STRUCT; //SnapFromJSON(SnapStringFromFile(file))
	// Define the name of the level to load
	if (is_undefined(argument[0]) or level_name == "")
	{
		if (L2G_DATABASE.current_level != "")
		{
			level_name = L2G_DATABASE.current_level;
			__LDtkTrace("Log: LDtk level is not specified in function call, parser will search LDtk file for a level named as defined in configuration data <%>.", level_name);
		}
		else
		{
			level_name = "" // then defined below
			__LDtkTrace("Log: LDtk level is not specified in function call nor in configuration data, parser will search LDtk file for a level identified after room <%>.", room_get_name(room));
		}
	}
	else
	{
		__LDtkTrace("Log: LDtk level is specified in function call, parser will search LDtk file for a level named <%>.", level_name);
	}
	// Cache the level data	
	var level = undefined
	for (var _i = 0; _i < array_length(data.levels); ++_i) 
	{
		var _level_i      = data.levels[_i];
		var _level_name_i = _level_i.identifier;
		
		if (level_name == "") // level mapped to the current room
		{ 
			var _room_name = _config.mappings.levels[$ (_level_name_i)];
			if _room_name == undefined _room_name = _level_name_i;
			if string_char_at(_room_name, 1) != _config.room_prefix	_room_name = _config.room_prefix + _room_name;
			
			if (_room_name == room_get_name(room)) 
			{
				level = _level_i;
				break
			}
		}
		else // load target level
		{ 
			if (_level_name_i == level_name) 
			{
				level = _level_i;
				break
			}
		}
	}
	// Exception : no matching level
	if (is_undefined(level))
	{
		if (global.__live_update_update_pending) 
		{
			global.__live_update_update_pending = false;
			__LDtkTrace("Error! Live update failed. Cannot find the matching level in LDtk file <%>.", string(file));
		} 
		__LDtkTrace("Error! Cannot find the matching level in LDtk file <%>.", string(file));
		return false;
	}	
	// Cache Entities properties
	var _entities_properties = {};
	for (var _ient = 0; _ient < array_length(data.defs.entities); ++_ient) 
	{
		var _entity_i = data.defs.entities[_ient];
		_entities_properties[$ _entity_i.identifier] = { pivot_x: _entity_i.pivotX, pivot_y: _entity_i.pivotY, width: _entity_i.width, height: _entity_i.height,  };
	}	
	// To store cleared tilemaps
	var _cleared_tilemaps = {};
	// Resize the room
	global.__ldtk_entities = {};
	var level_w  = level.pxWid;
	var level_h  = level.pxHei;
	room_width   = level_w;
	room_height  = level_h;
	var _depth_i = - 5000;	// in case we need to create our own layer
	// Load each layer in the level
	for (var _i = 0; _i < array_length(level.layerInstances); _i++) 
	{
		var _layer_i      = level.layerInstances[_i];
		var _layer_name   = _layer_i.__identifier;
		var gm_layer_name = __LDtkMappingGetLayer(_layer_name);
		var gm_layer_id   = layer_get_id(gm_layer_name);
		if (gm_layer_id   == -1) 
		{
			if LDTK_LAYER_CREATE and _layer_i.__type == "Entities"
			{
				_depth_i++;
				gm_layer_id = layer_create(_depth_i, gm_layer_name);
				__LDtkTrace("Log: Layer named <%> did not exis in current room <%>, it is created at depth.", gm_layer_name, room_get_name(room), _depth_i);			
			}
			else 
			{
				__LDtkTrace("Error! Layer named <%> does not exist in current room <%>, it will be ignored. Note that you can also layer_create instead.", gm_layer_name, room_get_name(room));
				continue
			}
		}
		else 
		{
			_depth_i = layer_get_depth(gm_layer_id);
		}
		switch(_layer_i.__type) 
		{
			case "Entities": // instances
				__LDtkTrace("Log: Loading an Entities Layer. LDtk layer <%> associated to Game Maker layer <%> in current room <%>.", _layer_name, gm_layer_name, room_get_name(room));
				var tile_size = _layer_i.__gridSize; // for scaling

				var entity_ref_fetch_list = [];
				
				// Load every entity / instance in this layer
				for (var e = 0; e < array_length(_layer_i.entityInstances); ++e) 
				{
					var entity_e    = _layer_i.entityInstances[e];
					var entity_name = entity_e.__identifier;
					// Fetch Object index				
					var obj_name = __LDtkMappingGetEntity(entity_name);
					var object_id = asset_get_index(obj_name);		
					// Fetch coordinates
					var _x = entity_e.px[0] + _layer_i.__pxTotalOffsetX;
					var _y = entity_e.px[1] + _layer_i.__pxTotalOffsetY;
					// Build field struct
					var _field_struct = 
					{
						image_xscale: 1,
						image_yscale: 1,
					};
					var spr = object_get_sprite(object_id);
					if (sprite_exists(spr)) 
					{
						var sw = sprite_get_width(spr);
						var sh = sprite_get_height(spr);
						_field_struct.image_xscale = entity_e.width  / sw;
						_field_struct.image_yscale = entity_e.height / sh;
						// This will translate the object to keep the bounding box as it is within LDtk (otherwise, it is the center that is kept)  
						var _entity_definition = _entities_properties[$ entity_name];
						if _entity_definition.width != sw or _entity_definition.height != sh 
						{
							__LDtkTrace("Warning: Sprite dimensions do no match for entity <%> between Game Maker [%,%] and LDtk [%,%]. This can cause unexpected behavior in instance scale and position.", entity_name, sw, sh, _entity_definition.width, _entity_definition.height);
						}
						var _gm_pivot_x = sprite_get_xoffset(spr) / sw;
						var _gm_pivot_y = sprite_get_yoffset(spr) / sh;
						var _ld_pivot_x = _entity_definition.pivot_x;
						var _ld_pivot_y = _entity_definition.pivot_y;
						_x += (_gm_pivot_x - _ld_pivot_x) * entity_e.width;
						_y += (_gm_pivot_y - _ld_pivot_y) * entity_e.height;
					}
					
					var _entityRefFieldPromise = [];
					var _entity_object_index = object_id;
					// for each field of the entity
					for (var _f = 0; _f < array_length(entity_e.fieldInstances); ++_f) 
					{
						var _field = entity_e.fieldInstances[_f];
						
						var _field_value = _field.__value;
						if LDTK_FIELD_SKIP_UNDEFINED and _field_value == undefined continue;
						var _field_name  = _field.__identifier;
						var _field_type  = _field.__type;					
						if (LDTK_OBJECT_INDEX_OVERRIDE and _field_name == "object_index" and asset_get_index(_field_value) != -1)
						{
							var object_id = asset_get_index(_field_value);
							continue	
						}
						var gm_field_name = __LDtkMappingGetField(entity_name, _field_name);
						if gm_field_name == undefined gm_field_name = _field_name;
						
						// some types require additional work
						switch(_field_type) 
						{
							case "Point":
								_field_value = __LDtkPreparePoint(_field_value, tile_size);
								break
							case "Array<Point>":
								var _len_fields = array_length(_field_value)
								if LDTK_FIELD_SKIP_EMPTY_ARRAY and _len_fields == 0 continue
								for(var j = 0; j < _len_fields; j++)
								{
									_field_value[@ j] = __LDtkPreparePoint(_field_value[j]);
								}
								break
							case "Color": // colors should be actual colors
								_field_value = __LDtkPrepareColor(_field_value);
								break
							case "Array<Color>":
								var _len_fields = array_length(_field_value)
								if LDTK_FIELD_SKIP_EMPTY_ARRAY and _len_fields == 0 continue
								for(var j = 0; j < _len_fields; j++)
								{
									_field_value[@ j] = __LDtkPrepareColor(_field_value[j]);
								}
								break
							case "EntityRef":
								// add to _entityRefFieldPromise so we can add the proper reference later
								array_push(_entityRefFieldPromise, {"gm_var_name": gm_field_name, "entity_ref": _field_value.entityIid});
								_field_value = undefined; // it is not defined upon creation but after creating all entities
								/*	"entityIid": "6da61610-7820-11ed-89ac-150b261ceae6","layerIid": "3fdb9d40-7820-11ed-9ba4-ab93e0e237d1",	"levelIid": "3fdb7630-7820-11ed-9ba4-9dacceea6cd9",	"worldIid": "83e040f0-7820-11ed-9d2f-3bd631b73e3d"*/
								break
							case "Array<EntityRef>":
								var _len_fields = array_length(_field_value)
								if LDTK_FIELD_SKIP_EMPTY_ARRAY and _len_fields == 0 continue
								var _promised_value = array_create(_len_fields);
								for(var j = 0; j < _len_fields; j++)
								{
									_field_value[@ j] = _field_value[@ j].entityIid;
									_promised_value[j] = _field_value[@ j].entityIid;
								}
								array_push(_entityRefFieldPromise, {"gm_var_name": gm_field_name, "entity_ref": _field_value});
								_field_value = undefined; // it is not defined upon creation but after creating all entities
								break
							default:
								if (string_pos("LocalEnum", _field_type))
								{
									var enum_name_idx = string_pos(".", _field_type);
									var enum_name_len = string_length(_field_type);
									var _enum_name    = string_copy(_field_type, enum_name_idx+1, 999);
									
									if (string_pos("Array<", _field_type))
									{
										for(var j = 0; j < array_length(_field_value); j++)
										{
											_field_value[@ j] = __LDtkPrepareEnum(_enum_name, _field_value[j]);
										}
									}
									else
									{
										_field_value = __LDtkPrepareEnum(_enum_name, _field_value);
									}
								}
								break
						}
						variable_struct_set(_field_struct, gm_field_name, _field_value);
					}
					// Exception : no object with that name
					if (object_id == -1) 
					{
						__LDtkTrace("Error! Object named <%> does not exist in the current Game Maker project, it will be ignored.", obj_name);
						continue
					}	
					// Instance creation
					// Note I floor my coordinates for uneven sizes, because LDtk only give integers for coordinates 
					var inst = instance_create_layer(floor(_x), floor(_y), gm_layer_id, object_id, _field_struct);
					
					for (var j = 0; j < array_length(_entityRefFieldPromise); ++j) 
					{
						array_push(entity_ref_fetch_list, 
						{
							"gm_instance": inst,
							"gm_var_name": _entityRefFieldPromise[j].gm_var_name,
							"entity_ref" : _entityRefFieldPromise[j].entity_ref,
						})
					}
					
					global.__ldtk_entities[$ entity_e.iid] = inst;
					
					__LDtkTrace("Log: <%> Layer loaded entity: Game Maker instance of object <%> with instance_id <%>. It was fed with this field struct <%>", _layer_name, object_get_name(object_id), inst, _field_struct);
				}
				// Add proper instance references to entity reference fields
				for (var _iref = 0; _iref < array_length(entity_ref_fetch_list); ++_iref) 
				{
					var _entity_ref_i = entity_ref_fetch_list[_iref];
					var _gm_inst      = _entity_ref_i.gm_instance;
					var _gm_var_name  = _entity_ref_i.gm_var_name;
					var _entity_ref   = _entity_ref_i.entity_ref;
					if is_array(_entity_ref)
					{
						for(var j = 0; j < array_length(_entity_ref); j++)
						{
							_entity_ref[@ j] = global.__ldtk_entities[$ _entity_ref[j]];
						}	
					}
					else
					{
						_entity_ref =  global.__ldtk_entities[$ _entity_ref]
					}
					
					//__LDtkTrace("Verbose:  Instance <%> added reference <%>  in var <%>",_gm_inst,  _entity_ref, _gm_var_name);
					variable_instance_set(_gm_inst, _gm_var_name, _entity_ref);
				}
				__LDtkTrace("Log: Completed loading of a % Layer. LDtk layer <%> associated to Game Maker layer <%> in current room <%>.", _layer_i.__type, _layer_name, gm_layer_name, room_get_name(room));				
				break
			case "IntGrid"  :
				__LDtkTrace("Warning: IntGrid layers are ignored. Ignoring LDtk layer <%> in current room <%>.", _layer_name, room_get_name(room));
				__LDtkTrace("Dev Note: We could also store that in a ds_grid or an invisible layer if needed.");
				break
			case "AutoLayer":
			case "Tiles"    : 
				var tilemap = layer_tilemap_get_id(gm_layer_id)
				__LDtkTrace("Log: Loading a % Layer. LDtk layer <%> associated to Game Maker layer <%> in current room <%>.", _layer_i.__type, _layer_name, gm_layer_name, room_get_name(room));
				if      (_layer_i.__type == "Tiles")      var _all_tiles = _layer_i.gridTiles;
				else if (_layer_i.__type == "AutoLayer")  var _all_tiles = _layer_i.autoLayerTiles;	
				// Fetch cell size defined in LDtk for the tileset associated to this layer
				var _tileset_width        = -1;
				var _tileset_height        = -1;
				var tileset_def = undefined;
				for (var _tset = 0; _tset < array_length(data.defs.tilesets); ++_tset)
				{
					tileset_def = data.defs.tilesets[_tset];
					if tileset_def.uid == _layer_i.__tilesetDefUid 
					{
						_tileset_width = tileset_def.__cWid;
						_tileset_height = tileset_def.__cHei;
						break
					}
				}
				// LDtk mismatch error
				if tileset_def == undefined
				{
					__LDtkTrace("Error! Identifier mismatch within LDtk file, The Tileset <%> specified for this layer does not exist in the definition section.", _layer_i.__tilesetDefUid);
					break
				}
				// Prepare tilemaps
				var tile_size = _layer_i.__gridSize;		
				var _highest_depth = 0;
				if (_config.stacked_tiles_support) 
				{
				__LDtkTrace(_layer_name,"Using stacked tile");
					// Preprocess the highest depth for tile stacking
					var _depth_grid = ds_grid_create(_tileset_width * tile_size, _tileset_height * tile_size);
					ds_grid_clear(_depth_grid, -1);
					for (var _til = 0; _til < array_length(_all_tiles); ++_til) 
					{
						var _cell_x = _all_tiles[_til].px[0] div tile_size;
						var _cell_y = _all_tiles[_til].px[1] div tile_size;
						ds_grid_set(_depth_grid, _cell_x, _cell_y, ds_grid_get(_depth_grid, _cell_x, _cell_y) + 1);
					}
					
					_highest_depth = max(0, ds_grid_get_max(_depth_grid, 0, 0, ds_grid_width(_depth_grid) - 1, ds_grid_height(_depth_grid) - 1));
					ds_grid_destroy(_depth_grid);
				}	
				
				// Fetch Tileset asset
				var gm_tileset_name = __LDtkMappingGetTileset(tileset_def.identifier);	
				if (gm_tileset_name == undefined) gm_tileset_name = tileset_def.identifier;
				var gm_tileset_id = asset_get_index(gm_tileset_name);
				if (gm_tileset_id == -1) 
				{
					__LDtkTrace("Error! Tileset named <%> does not exist in the current Game Maker project, it will be ignored.", tileset_def.identifier);
					break
				}
				// Cache Tilemaps data
				var tilemaps = array_create(_highest_depth + 1, -1);
				//__LDtkTrace("Verbose: There are % tilemaps for <%> LDtk layer to populate <%> GM layer", _highest_depth + 1, _layer_name, gm_layer_name);
				tilemaps[array_length(tilemaps) - 1] = layer_tilemap_get_id(gm_layer_id);
				for (var t = _highest_depth; t >= 0; --t) 
				{
					var tilemap_t = tilemaps[t];
					if (tilemap_t == -1) 
					{
						tilemap_t = layer_tilemap_create(gm_layer_id, _layer_i.__pxTotalOffsetX, _layer_i.__pxTotalOffsetY, gm_tileset_id,  room_width  div tile_size, room_height div tile_size);
						//__LDtkTrace("Verbose: Tilemap <%> created on <%> GM layer.", tilemap_t, gm_layer_name);
					}		
					else
					{
						//__LDtkTrace("Verbose: Tilemap <%> already exists on <%> GM layer. No Tilemap created.", tilemap_t, gm_layer_name);					
					}
					tilemap_set_width(tilemap_t,  room_width   div tile_size);
					tilemap_set_height(tilemap_t, room_height div  tile_size);	
					tilemap_x(tilemap_t, _layer_i.__pxTotalOffsetX);
					tilemap_y(tilemap_t, _layer_i.__pxTotalOffsetY);
					if LDTK_CLEAR_TILE_MAP and _cleared_tilemaps[$ tilemap_t] == undefined 
					{
						tilemap_clear(tilemap_t, 0);
						_cleared_tilemaps[$ tilemap_t] = tilemap_t;
						//__LDtkTrace("Verbose: Tilemap <%> cleared.", tilemap_t, gm_layer_name);
					}

				}
				// Apply x-y flips to tiles data, and apply to tilemap
				for (var t = 0; t < array_length(_all_tiles); ++t) 
				{
					var this_tile = _all_tiles[t];	
					// Cache coordinates
					var _x         = this_tile.px[0];
					var _y         = this_tile.px[1];
					var cell_x     = _x div tile_size;
					var cell_y     = _y div tile_size;
					var tile_src_x = this_tile.src[0],
						tile_src_y = this_tile.src[1];
					// Build data for this tile
					var tile_id    = this_tile.t;
					var tile_data  = tile_id;
					var x_flip     = this_tile.f & 1;
					var y_flip     = this_tile.f & 2;
					tile_data      = tile_set_mirror(tile_data, x_flip);
					tile_data      = tile_set_flip(tile_data,   y_flip);
					var _tilemap   = tilemaps[0];
					// Check if this is a stacked tile
					/*if (_config.stacked_tiles_support) 
					{
						var _tilemap_depth = 0;
						while (tilemap_get(_tilemap, cell_x, cell_y) != 0) 
						{
							++_tilemap_depth
							_tilemap = tilemaps[_tilemap_depth]
						}
					}
					*/
					// Apply data to tilemap
					tilemap_set(_tilemap, tile_data, cell_x, cell_y);
				}			
				__LDtkTrace("Log: Completed loading of a % Layer. LDtk layer <%> associated to Game Maker layer <%> in current room <%>.", _layer_i.__type, _layer_name, gm_layer_name, room_get_name(room));
				break
			default:
				__LDtkTrace("Error! Undefined layer type <%>", _layer_i.__type);
				break
		}
	}
	
	LDTK_FILE_HASH = md5_file(_config.ldtk_file)
	if (global.__live_update_update_pending) 
	{
		global.__live_update_update_pending = false;
		__LDtkTrace("Log: <%> live updated.", level_name);
	} 
	else 
	{
		__LDtkTrace("Log: <%> loaded.", level_name);
	}
	
	return 0
}

function L2G_create_level_database() {
	var _config = L2G_LDTK_CONFIG;
	// Exception : no LDtk file
	var file = _config.ldtk_file
	if (!file_exists(file)) 
	{
		if (global.__live_update_update_pending) 
		{
			global.__live_update_update_pending = false;
			__LDtkTrace("Error! Live Updated Failed. LDtk project file <%> is not specified or file does not exist.", string(file));
		} 
		else 
		{
			__LDtkTrace("Error! LDtk project file <%> is not specified or file does not exist!", string(file));
		}
		return false;
	}	
	// Load data from file
	data = SnapFromJSON(SnapStringFromFile(file))
	// Create / Clean Transition data
	L2G_DATABASE = {
		current_level  : undefined,
		level_database : {},
	};
	var _array      = data.levels, _len_i = array_length(_array);
	var _name_from_iid = {};
	// Build transcodification iid -> name
	for (var _i = 0; _i < _len_i; _i++) 
	{
		var _level_i = _array[_i];
		_name_from_iid[$ _level_i.iid] = _level_i.identifier;
	}	
	// Build database
	for (var _i = 0; _i < _len_i; _i++) 
	{
		var _level_i = _array[_i];
		var _out = []
		var _neighbours = _level_i.__neighbours, _len_j = array_length(_neighbours);
		for (var _j = 0; _j < _len_j; _j++) 
		{
			var _neighbour_j = _neighbours[_j];
			array_push(_out, _name_from_iid[$_neighbour_j.levelIid]);
		}
		L2G_DATABASE.level_database[$ _level_i.iid] = 
		{ 
			name        : _level_i.identifier,
			iid         : _level_i.iid,
			gm_room     : _config.mappings.levels[$ (_level_i.identifier)],
			room_left   : _level_i.worldX,
			room_top    : _level_i.worldY, 
			room_right  : _level_i.worldX + _level_i.pxWid,
			room_bottom : _level_i.worldY + _level_i.pxHei,
			neighbours  : _out,
		};
		shw(L2G_DATABASE.level_database);
	}
}

function __LDtkTrace(str) {
	if !is_string(str)
		str = string(str)
	
	for(var _i = 1; _i < argument_count; _i++) {
		if string_pos("%", str)
			str = string_replace( str, "%", string(argument[_i]) )
		else
			str += " " + string(argument[_i])
	}
	show_debug_message("[LDtk parser] " + str)
}

#region Format values
function __LDtkPreparePoint(point, tile_size) {
	if !is_struct(point) and point == pointer_null { // if the field is null
		//show_message(point)
		return undefined
	}
	
	if tile_size == undefined
		return { x: point.cx, y: point.cy }
	else
		return { x: point.cx * tile_size, y: point.cy * tile_size }
}

function __LDtkPrepareColor(color) {
	// cut the #
	color = string_copy(color, 2, string_length(color)-1)
	// extract the colors
	var red = hex_to_dec(string_copy(color, 1, 2))
	var green = hex_to_dec(string_copy(color, 3, 2))
	var blue = hex_to_dec(string_copy(color, 5, 2))
	
	return make_color_rgb(red, green, blue)
}

function __LDtkPrepareEnum(_enum_name, value) {
	if value == pointer_null
		return value
	
	var result = __LDtkMappingGetEnum(_enum_name)
	
	if result == undefined or result[$ (value)] == undefined
		return value // just return the string
	else
		return result[$ (value)]
}

// used for decoding colors' hex codes
function hex_to_dec(str) {
	if !is_string(str) str = string(str)
	str = string_upper(str)
	
	var ans = 0
	for(var _i = 1; _i <= string_length(str); ++_i) {
		var c = string_char_at(str, _i)
		
		if ord(c) >= ord("A")
			ans += ord(c) - ord("A") + 10
		else
			ans += ord(c) - ord("0")
		
		ans *= 16
	}	
	return ans
}
function dec_to_hex(dec, len = 1) 
{
    var hex = "";
 
    if (dec < 0) {
        len = max(len, ceil(logn(16, 2 * abs(dec))));
    }
 
    var dig = "0123456789ABCDEF";
    while (len-- || dec) {
        hex = string_char_at(dig, (dec & $F) + 1) + hex;
        dec = dec >> 4;
    }
 
    return hex;
}
///@function color_to_decimal(color as a string)
function color_to_decimal(c) {
	c = "FF" + string_copy(c,6,2) + string_copy(c,4,2) + string_copy(c,2,2);
	c = hex_to_dec(c);
	return c;
}


#endregion

#region Manage Mappings
function __LDtkDeepInheritVariables(src, dest) {
	var var_names = variable_struct_get_names(src)
	
	for(var _i = 0; _i < array_length(var_names); ++_i) {
		var var_name = var_names[_i]
		var var_value = variable_struct_get(src, var_name)
		
		if (is_struct(var_value) and is_struct(dest[$ (var_name)])) {
			__LDtkDeepInheritVariables(var_value, dest[$ (var_name)])
		}
		else {
			variable_struct_set(dest, var_name, var_value)
		}
	}
}

function __LDtkMappingGetLevel(_ldtk_name, _project_directory) 
{

	var _mapped_name = global.__ldtk_config.mappings.levels[$ _ldtk_name];
	if _mapped_name == undefined var _level_name    = _ldtk_name;
	else                         var _level_name    = _mapped_name;
	if _project_directory == undefined
	{
		if (asset_get_index(_level_name) == -1 and string_char_at(_level_name, 1) != L2G_LDTK_CONFIG.room_prefix) // Try to add the prefix
		{
			var _tested_name = L2G_LDTK_CONFIG.room_prefix + _level_name;
			if (asset_get_index(_tested_name) != -1) _level_name = _tested_name;
		}
		return _level_name;
	}
	else
	{
		if (!yy_room_exist(_project_directory, _level_name) and string_char_at(_level_name, 1)!= L2G_LDTK_CONFIG.object_prefix) // Try to add the prefix
		{
			var _tested_name = L2G_LDTK_CONFIG.room_prefix + _level_name;
			if (yy_room_exist(_project_directory, _tested_name)) _level_name = _tested_name;
			
		}
		return _level_name;		
	}
}

function __LDtkMappingGetLayer(_ldtk_name) 
{
	var _mapped_name = global.__ldtk_config.mappings.layers[$ _ldtk_name];
	if _mapped_name == undefined var _layer_name    = _ldtk_name;	
	else                         var _layer_name    = _mapped_name;
	return _layer_name;
}

function __LDtkMappingGetEnum(key) 
{
	return global.__ldtk_config.mappings.enums[$ key]
}

function __LDtkMappingGetEntity(_ldtk_name, _project_directory) 
{
	var _mapped_name = global.__ldtk_config.mappings.entities[$ _ldtk_name];
	if _mapped_name == undefined var _obj_name    = _ldtk_name;
	else                         var _obj_name    = _mapped_name;

	if _project_directory == undefined
	{
		if (asset_get_index(_obj_name) == -1 and string_char_at(_obj_name, 1)!= L2G_LDTK_CONFIG.object_prefix) // Try to add the prefix
		{
			var _tested_name = L2G_LDTK_CONFIG.object_prefix + _obj_name;
			if (asset_get_index(_tested_name) != -1) _obj_name = _tested_name;
		}
		return _obj_name;
	}
	else
	{
		if (!yy_object_exist(_project_directory, _obj_name) and string_char_at(_obj_name, 1)!= L2G_LDTK_CONFIG.object_prefix) // Try to add the prefix
		{
			var _tested_name = L2G_LDTK_CONFIG.object_prefix + _obj_name;
			if (yy_object_exist(_project_directory, _tested_name)) _obj_name = _tested_name;
		}
		return _obj_name;		
	}
}

function __LDtkMappingGetField(_entity, _ldtk_name) 
{
	var _fields = global.__ldtk_config.mappings.fields[$ _entity]
	var _mapped_name = (_fields != undefined) ? _fields[$ _ldtk_name] : undefined
	if _mapped_name == undefined var _field_name = _ldtk_name;
	else                         var _field_name = _mapped_name;	
	return _ldtk_name;
}

function __LDtkMappingGetTileset(_ldtk_name) 
{
	var _mapped_name = global.__ldtk_config.mappings.tilesets[$ _ldtk_name];
	if _mapped_name == undefined return  _ldtk_name;	
	else                         return  _mapped_name;
}
#endregion

///@function	LDtkLive(level_name*)
///@description	Similar to LDtkLoad(), but only reloads when changes are detected
///@param		{string} level_name*
function __LDtkLive(level_name) {
	
	var _ = argument[0]; _ = _
	
	
	//global.__live_update_timer -= 1
	
	//if (global.__live_update_timer <= 0) 
	{
		//global.__live_update_timer = L2G_LDTK_CONFIG.live_frequency // DEV NOTE: This my modification
		
		//var hash = sha1_file(_config.ldtk_file)
		var hash = md5_file(L2G_LDTK_CONFIG.ldtk_file)	
		if (hash != LDTK_FILE_HASH) 
		{
			__LDtkTrace("Updating...")
			__LDtkClear()		
			global.__live_update_update_pending = true
			LDTK_FILE_HASH = hash
		}
	}
}

function __LDtkClear() {
	// yes
	// room_restart()
	if ENGINE != noone and PLAYER != noone	ENGINE.transition_ldtk_run_to_room(L2G_DATABASE.current_level, undefined, PLAYER.x, PLAYER.y);
}

///@function	LDtkReloadFields()
///@description	Reloads fields from an isolated struct.
///				This works around the Variable Definitions tab
///				You don't need this in most cases
///				You would want to call this in the Create Event
///				Only works if __ldtk_config.escape_fields is set to `true`
function LDtkReloadFields() {
	if (!L2G_LDTK_CONFIG.escape_fields) {
		__LDtkTrace("Warning: LDtkReloadFields() is called, but the `escape fields` config is turned off.\Did you mean to enable the config or not call the function? (Variables are loaded automatically by default)")
		return -1
	}
	
	if (!variable_instance_exists(self, "__ldtk_fields"))
		return 0
	
	var field_names = variable_struct_get_names(self.__ldtk_fields)
	for(var _i = 0; _i < array_length(field_names); ++_i) {
		var field_name = field_names[_i]
		var field_value = variable_struct_get(self.__ldtk_fields, field_name)
		
		variable_instance_set(id, field_name, field_value)
	}
}