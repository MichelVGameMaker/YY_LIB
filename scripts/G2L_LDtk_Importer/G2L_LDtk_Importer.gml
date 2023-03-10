// Sources & Credit
// A huge thank you to Evoleo, Ailwuful and Juju, my code is just some reuse of theirs
// https://github.com/Ailwuful/LDtk-Room_builder
// https://github.com/evolutionleo/LDtkParser
// https://github.com/JujuAdams/SNAP

///@function	LDtk_import(ldtk_path, gm_project_directory, level_name_array)
///@description	Import targeted levels from LDtk file into existing .yy room files
/// @param {Array}				_ldtk_path				The path to the LDtk file.
/// @param {Array}				_gm_project_directory	The Game Maker project directory.
/// @param {Array}				level_name_array		The array of all rooms' names to import. A matching Game Maker room needs to exist in the Game Maker project directory.
function LDtk_import(_ldtk_path = L2G_LDTK_CONFIG.ldtk_file, _gm_project_directory = L2G_GM_PROJECT_DIR, _level_name_array) {

	// Exception : no LDtk file
	if (!file_exists(_ldtk_path)) 
	{
		__LDtkTrace("Error! LDtk project file <%> is not specified or file does not exist!", string(_ldtk_path));
		return false;
	}	
	else
	__LDtkTrace("Log: Starting to load from LDtk project file <%>...",string(_ldtk_path))
	// Load data from file
	L2G_ld_file_to_ld_struct();
	data = L2G_LDTK_STRUCT;
	//var data = SnapFromJSON(SnapStringFromFile(_ldtk_path))
	// Cache Entities properties from DEFinitions section
	var _entities_properties = {};
	var _defs = data.defs.entities;
	for (var _ent = 0; _ent < array_length(_defs); ++_ent) 
	{
		var _entity_i = _defs[_ent];
		_entities_properties[$ _entity_i.identifier] = { pivot_x: _entity_i.pivotX, pivot_y: _entity_i.pivotY, width: _entity_i.width, height: _entity_i.height, fields: {}  };
	}	
	for (var _ent = 0; _ent < array_length(_defs); ++_ent) 
	{
		var _entity_i = _defs[_ent];
		var _entity_name = _entity_i.identifier;
		// Fetch Object index
		var _obj_name = __LDtkMappingGetEntity(_entity_name, _gm_project_directory);
		if !yy_object_exist(_gm_project_directory, _obj_name)
		{
			var _yy_object_path = _gm_project_directory + "/objects/" + _obj_name + "/" + _obj_name + ".yy";
			show_debug_message("Object file: " + _yy_object_path + " does not exist, it will be ignored.");
		}
		else
		{		
			show_debug_message("Checking fields in object " + string(_obj_name) + ".");
			var _yy_obj_construct   = new yy_object(_gm_project_directory, _obj_name)
			var _fields_definitions = _entity_i.fieldDefs
			for (var _fld = 0; _fld < array_length(_fields_definitions); ++_fld) 
			{
				var _field_name    = _fields_definitions[_fld].identifier
				var _gm_field_name = __LDtkMappingGetField(_entity_name, _field_name);
				if _yy_obj_construct.exists_property(_gm_field_name)
				{
					_entities_properties[$ _entity_i.identifier].fields[$ _field_name] = true;
				}
				else __LDtkTrace("Game Maker property <%> matching <%> LDtk field was not found in object <%>",  _gm_field_name, _field_name, _obj_name);
			}
		}
	}

	// Cache Tileset properties from DEFinitions section
	var _tileset_properties = {};
	var _defs = data.defs.tilesets
	for (var _til = 0; _til < array_length(_defs); ++_til) 
	{
		var _tileset_i = _defs[_til];
			_tileset_properties[$ _tileset_i.uid] = { tileset: _tileset_i.identifier, width: _tileset_i.__cWid, height: _tileset_i.__cHei, };
	}	
	var _defs = undefined;
	// Main loop, to cover all targeted levels

	for (var _lvl = 0; _lvl < array_length(_level_name_array); _lvl++ )
	{
		var _level_name    = _level_name_array[_lvl];
		// Array find LDtk level data
		var _level_data = undefined
		for (var _ldt = 0; _ldt < array_length(data.levels); ++_ldt) 
		{
			var _level_i      = data.levels[_ldt];
			var _level_name_i = _level_i.identifier;
			if (_level_name_i == _level_name) 
			{
				_level_data = _level_i;
				break
			}
		}
		// Exception : no matching level
		if (is_undefined(_level_data))
		{
			__LDtkTrace("Error! Cannot find the matching Game Maker room for level <%> in LDtk file <%>.", _level_name, string(_ldtk_path), );
			return false;
		}	
		// Set the name of the targeted room	
		var gm_level_name = __LDtkMappingGetLevel(_level_name, _gm_project_directory);
		// Parse the .yy file
		var _room_struct = new yy_room(_gm_project_directory, gm_level_name);
		// Prepare temporary variables
		_ldtk_room_entities = {};
		var _depth_i        = - 5000;	// in case we need to create our own layer
		// Clean the room
		if LDTK_IMPORT_LAYERS_CLEAR _room_struct.clear_layers();
		_room_struct.clear_instance_creation_order();	
		// Resize the room
		var _room_width  = _level_data.pxWid;
		var _room_height = _level_data.pxHei;
		_room_struct.set_width(_room_width);
		_room_struct.set_height(_room_height);
		// Load each layer in the level

		for (var _lay = 0; _lay < array_length(_level_data.layerInstances); _lay++) 
		{
			var _layer_i      = _level_data.layerInstances[_lay];
			var _layer_name   = _layer_i.__identifier;
			var gm_layer_name = __LDtkMappingGetLayer(_layer_name);
			var _layer_struct = _room_struct.get_layer(gm_layer_name);
			__LDtkTrace("Log: Loading a % Layer. LDtk layer <%> associated to Game Maker layer <%> in room <%>.", _layer_i.__type, _layer_name, gm_layer_name, gm_level_name);

			switch(_layer_i.__type) 
			{
				case "Entities" : { // instances
					// Make sure layer exist
					if (_layer_struct   == undefined) 
					{
						if LDTK_LAYER_CREATE
						{
							_depth_i++;
							_layer_struct = _room_struct.instance_layer_create(gm_layer_name, _depth_i); 
							__LDtkTrace("Log: Layer named <%> does not exist in room <%>, it will be created at depth.", gm_layer_name, gm_level_name, _depth_i);			
						}
						else 
						{
							__LDtkTrace("Error! Layer named <%> does not exist in room <%>, it will be ignored. Note that you can also layer_create instead setting LDTK_LAYER_CREATE macro to TRUE.", gm_layer_name, gm_level_name);
							continue;
						}
					}
					else 
					{
						_depth_i = _room_struct.layer_depth_get(_layer_struct);
						if LDTK_IMPORT_INSTANCES_CLEAR _room_struct.layer_instances_clear(_layer_struct);
					}
					var tile_size = _layer_i.__gridSize; // for scaling
					var entity_ref_fetch_list = [];
				
					// Load every entity / instance in this layer
					for (var e = 0; e < array_length(_layer_i.entityInstances); ++e) 
					{
						var entity_e    = _layer_i.entityInstances[e];
						var entity_name = entity_e.__identifier;
						// Fetch Object index
						var obj_name = __LDtkMappingGetEntity(entity_name, _room_struct.get_project_directory());
						var _entity_object_index   = asset_get_index(obj_name); // Used for sprite for now
						// Fetch coordinates
						var _x = entity_e.px[0] + _layer_i.__pxTotalOffsetX;
						var _y = entity_e.px[1] + _layer_i.__pxTotalOffsetY;
						// Build field struct
						var _entityRefFieldPromise = [];
						var _field_struct          = {};
						for (var _f = 0; _f < array_length(entity_e.fieldInstances); ++_f) 
						{
							var _field_i     = entity_e.fieldInstances[_f];
							var _field_value = _field_i.__value;
							var _field_name  = _field_i.__identifier;
							var _field_type  = _field_i.__type;					
							if LDTK_FIELD_SKIP_UNDEFINED and (_field_value == undefined or _field_value == pointer_null)  
							{
								continue;
							}
							if (LDTK_OBJECT_INDEX_OVERRIDE and _field_name == "object_index" and asset_get_index(_field_value) != -1)
							{
								obj_name = _field_value;
								continue	
							}
							/*if _entities_properties[$ entity_name].fields[$ _field_name] != true 
							{
								__LDtkTrace("Field <%> is not set in the associated game maker <%> object", _field_name, obj_name)
								continue
							}*/
							var gm_field_name = __LDtkMappingGetField(entity_name, _field_name);
							// some types require additional work
							switch(_field_type) 
							{
								case "Multilines":
								case "String":
									_field_value = string_replace_all(_field_value, "\n", "\\n"); // For multi-lines type
									break;
								case "Array<String>":
								case "Array<Bool>":
								case "Array<Int>":
								case "Array<Float>":
								case "Array<Point>":
								var _len_fields = array_length(_field_value)
									if LDTK_FIELD_SKIP_EMPTY_ARRAY and _len_fields == 0 continue
									var _field_concat = "[";
									for(var j = 0; j < _len_fields - 1; j++)
									{
										_field_concat += string(_field_value[@ j]) + ",";
									}
									_field_value = _field_concat + string(_field_value[@ j]) + "]";
									break
								case "Point":
									_field_value = string(_field_value);
									break
								case "EntityRef":
									// add to _entityRefFieldPromise so we can add the proper reference later
									array_push(_entityRefFieldPromise, {"gm_var_name": gm_field_name, "entity_ref": _field_value.entityIid});
									_field_value = undefined; // it is not defined upon creation but after creating all entities
									break
								case "Array<EntityRef>":
									var _len_fields = array_length(_field_value)
									if LDTK_FIELD_SKIP_EMPTY_ARRAY and _len_fields == 0 continue;
									var _promised_value = array_create(_len_fields);
									for(var j = 0; j < _len_fields; j++)
									{
										_promised_value[j] = _field_value[j].entityIid;
									}
									shw(">>>>>>>>>>>>Pushed ref", _promised_value);
									array_push(_entityRefFieldPromise, {"gm_var_name": gm_field_name, "entity_ref": _promised_value});
									_field_value = undefined; // it is not defined upon creation but after creating all entities
									break
								default: break;
							}
							variable_struct_set(_field_struct, gm_field_name, _field_value);
						}
						// Exception : no object with that name
						if (!yy_object_exist(_room_struct.get_project_directory(), obj_name))
						{
							__LDtkTrace("Error! Object named <%> does not exist in the current Game Maker project, it will be ignored.", obj_name);
							continue
						}	
						// Build image scales and adjust position
						var object_id = asset_get_index(obj_name);		
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
						// Instance creation - Note that I floor my coordinates for uneven sizes, because LDtk only give integers for coordinates 
						var inst = _room_struct.instance_create(floor(_x), floor(_y), _layer_struct, obj_name, _field_struct);
						if array_length(_entityRefFieldPromise) >0 shw("_entityRefFieldPromise", _entityRefFieldPromise);
						for (var j = 0; j < array_length(_entityRefFieldPromise); ++j) 
						{
							array_push(entity_ref_fetch_list, 
							{
								"gm_instance": inst,
								"gm_var_name": _entityRefFieldPromise[j].gm_var_name,
								"entity_ref" : _entityRefFieldPromise[j].entity_ref,
							})
						}
						// Instance registering
						_ldtk_room_entities[$ entity_e.iid] = inst.name;
						shw("Adding entities to map id: ", entity_e.iid, "= name: ", inst.name);
						__LDtkTrace("Log: <%> Layer loaded entity: Game Maker instance of object <%> with instance_id <%>. It was fed with this field struct <%>", _layer_name, obj_name, inst.name, _field_struct);
					}
					// Add proper instance references to entity reference fields
					shw("entity_ref_fetch_list", entity_ref_fetch_list);
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
								_entity_ref[@ j] = _ldtk_room_entities[$ _entity_ref[j]];
							}	
						}
						else
						{
							_entity_ref =  _ldtk_room_entities[$ _entity_ref]
						}
					
						_entity_ref = string_replace_all(string(_entity_ref),"\"","");
						_room_struct.instance_set_property(_gm_inst, _gm_var_name, _entity_ref)
						__LDtkTrace("Verbose:  Instance <%> added reference <%> in var <%>",_gm_inst.name,  _entity_ref, _gm_var_name);	
					}
					__LDtkTrace("Log: Completed loading of a % Layer. LDtk layer <%> associated to Game Maker layer <%> in room <%>.", _layer_i.__type, _layer_name, gm_layer_name, gm_level_name);				
				}	break
				case "IntGrid"  :
					__LDtkTrace("Warning: IntGrid layers are ignored. Ignoring LDtk layer <%> in current room <%>.", _layer_name, room_get_name(room));
					__LDtkTrace("Dev Note: We could also store that in a ds_grid or an invisible layer if needed.");
					break
				case "AutoLayer":
				case "Tiles"    : {
					// Make sure layer exist
					if (_layer_struct   == undefined) 
					{
						if LDTK_LAYER_CREATE
						{
							_depth_i++;
							_layer_struct = _room_struct.tile_layer_create(gm_layer_name, _depth_i); 
							__LDtkTrace("Log: Tile/Auto layer named <%> does not exist in room <%>, it will be created at depth.", gm_layer_name, gm_level_name, _depth_i);			
						}
						else 
						{
							__LDtkTrace("Error! Layer named <%> does not exist in room <%>, it will be ignored. Note that you can also layer_create instead setting LDTK_LAYER_CREATE macro to TRUE.", gm_layer_name, gm_level_name);
							continue;
						}
					}
					else 
					{
						_depth_i = _room_struct.layer_depth_get(_layer_struct);
						if LDTK_IMPORT_TILES_CLEAR _room_struct.layer_tiles_data_set(_layer_struct, 0, 0, []);
					}
					// Configure Layer
					var _tileset_name    = _tileset_properties[$ _layer_i.__tilesetDefUid].tileset;
					var gm_level_name    = __LDtkMappingGetTileset(_tileset_name, _gm_project_directory);
					var _grid_size       = _layer_i.__gridSize;
					var _width_in_tiles  = _layer_i.__cWid
					var _height_in_tiles = _layer_i.__cHei
					_room_struct.layer_tileset_set(_layer_struct, gm_level_name);	
					shw("YOU COULD ADD A TEST ON tileset_name exists ",yy_tileset_exist(_gm_project_directory, gm_level_name));
					_room_struct.layer_grid_x_set(_layer_struct, _grid_size);	
					_room_struct.layer_grid_y_set(_layer_struct, _grid_size);	
					// Tiles data
					if      (_layer_i.__type == "Tiles")      var _tiles_data = _layer_i.gridTiles;
					else if (_layer_i.__type == "AutoLayer")  var _tiles_data = _layer_i.autoLayerTiles;	
					var _tile_stack = 1;
					var _tilemaps   = {};
					_tilemaps[$ _tile_stack] = array_create(_width_in_tiles*_height_in_tiles);
					for (var _idx = 0; _idx < array_length(_tiles_data); _idx++) 
					{
						_gm_tile_index = (_tiles_data[_idx].px[0]/_grid_size) + (_tiles_data[_idx].px[1]/_grid_size * _width_in_tiles);
						while (_tilemaps[$ _tile_stack][_gm_tile_index] != 0)
						{
							_tile_stack++;
							if (!variable_struct_exists(_tilemaps, _tile_stack)) 
							{
								_tilemaps[$ _tile_stack] = array_create(_width_in_tiles*_height_in_tiles);
							}
						}
						var _tile = _tiles_data[_idx];
						var _t = _tile.t;
						var _f = _tile.f;
						if _f > 0
						{
							_f = string(_f * 10000000);
							_t = dec_to_hex(_t);
							_t = string_copy(_f, 1, string_length(_f) - string_length(_t)) + _t;
							_t = ptr(_t);
						}
						_tilemaps[$ _tile_stack][_gm_tile_index] = int64(_t);
					}
					_room_struct.layer_tiles_data_set(_layer_struct, _width_in_tiles, _height_in_tiles, _tilemaps[$ _tile_stack]);
					__LDtkTrace("Log: Completed loading of a % Layer. LDtk layer <%> associated to Game Maker layer <%> in room <%>.", _layer_i.__type, _layer_name, gm_layer_name, gm_level_name);				
					__LDtkTrace("Warning: Please, if the room % is opened in Game Maker, close it for the changes made to tiles to be taken into account !", gm_layer_name);				
					// layer_set
					break; }
				default: break;
			}
		}
		// Background
		if LDTK_BACKGROUND_CREATE _room_struct.background_layer_create("Background", _depth_i + 10, 32, 32, color_to_decimal(_level_data.__bgColor));
		// Save_to_directory
		_room_struct.save_to_directory();
		__LDtkTrace("Log: <%> loaded.");
	}
	return true
}

function shw() {
    var _string = "";
    var _i = 0;
    repeat(argument_count)
    {
        var _str = string(argument[_i])
		_string += string(argument[_i]);
        ++_i;
    }
	show_debug_message(_string)
}