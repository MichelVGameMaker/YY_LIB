/*Welcome to YY!
# YY LIB - Game Maker Files Modifier
YY is a small collection of functions to adjust Game Maker room files and object files within your project directory. It is intended to pair with external level editor to facilitate import into Game Maker project.

It allows to modify rooms, in particular by creating layers and populating them with instances or tiles.  
It also allows to modify object, in particular by creating properties (=variables from [Variables Definitions] section of Objects Editor).  
I tried to keep the syntax close to what you would use in GML so that you can, for example, create an instance in your room file with instance_create().  

More details in the documentation >>YY_README_LINK()<< mouse middle-button link
*/

enum   YY_varType								// Game Maker variable varType (integer).
{
	Real       = 0,
	Integer    = 1,
	String     = 2,
	Boolean    = 3,
	Expression = 4,
	Asset      = 5,
	List       = 6,
	Colour     = 7
}

#region yy_room notes
/* 
yy_room constructor requires two arguments: the Game Maker project directory where the room is stored and the name of the room.
The resulting struct has two private variables: one storing the data from Game Maker .yy file and one storing the path to the Game Maker project directory.
It also comes with the following methods:
 // Data Management from / to .yy file:
  .set_from_file(gm_project_directory, room_name):                            Parse the Game Maker room .yy file targeted by the specified path and room name, and store its data in the __struct variable.
  .save_to_directory():							                              Save the data from the __struct variable to the associated Game Maker room .yy file, with proper formating.
  .get_project_directory():						                              Return the Game Maker directory defined for this yy_room, the one that will be used to save back data to the .yy file.
  .is_set():									                              Return true if this yy_struct has set its data... sort of.
 // Creating layers:
  .instance_layer_create(name, depth, grid_x, gridy):			              Create a layer for instances.
  .asset_layer_create(name, depth, grid_x, gridy):				              Create a layer for assets.
  .background_layer_create(name, depth, grid_x, gridy, coulour):              Create a layer for background.
  .tile_layer_layer_create(name, depth, grid_x, gridy, tileset):              Create a layer for tilemaps with no tile data. You also need to call layer_tiles_data_set() on this layer, to set its tile data. 
 // Creating instances and sprites:
  .instance_create(x, y, layer_struct, object_name, variables_struct, register): Create an instance on the targeted layer. You need to pass it the full layer_struct returned by instance_layer_create(), not the layer's name as a string.
  .instance_set_property(instance_struct, property_name, property_value):        Set a property (i.e. variable from variable definition) into an instance. The variable needs to be defined in the object: you can do it before or after calling this, but your room will not take properties into account if they do not exist in object files.
  .register_instance_creation
  .remove_instance_creation
  .asset_create()												WIP
 // Getters and setters for the room data:
  .get_width():                                                               Return room width.
  .set_width(width):                                                          Set room witdh.
  .get_height():                                                              Return room height.
  .set_height(height):                                                        Set room height.
  .get_name():                                                                Return the name of the room.
  .get_instance_creation_order():                                             Return the array with instances creation order.
  .set_instance_creation_order(_inst_creation_order_array):                   Set the instances creation order.
  .clear_instance_creation_order():                                           Clear the instances creation order.
  .get_layers():                                                              Return the array with all layers.
  .set_layers(_layers_array):                                                 Set the array with all layers.
  .clear_layers():                                                            Clear the array with all layers.
  .add_layer(_layer_struct, overridde):                                       Add a layer to the room.
  .get_layer(_layer_name):                                                    Return the layer_struct associated to the layer name.
 // Getters and setters for a layer_struct:
  .layer_visible_get(layer_struct):                                           Return the layer's visible flag.
  .layer_visible_set(layer_struct, visible):                                  Set the layer's visible flag.
  .layer_grid_x_set(layer_struct, grid_x):	                                  Set the layer's grid width/cell width.
  .layer_grid_y_set(layer_struct, grid_y):	                                  Set the layer's grid height/cell height.
  .layer_depth_get(layer_struct):                                             Return the layer's depth.
  .layer_depth_set(layer_struct, depth):						              Set the layer depth.
  .layer_instances_get(layer_struct):                                         Return the layer's instances array.
  .layer_instances_set(layer_struct, instances):                              Set the layer's instances array.
  .layer_instances_clear(layer_struct):                                       Clear the layer's instances array and remove those instances from the instance creation order.
  .layer_tiles_data_set(layer_struct, tiles_width, tiles_height, tiles_data): Define the layer's data, using serialized format.
  .layer_tileset_set(layer_struct, tilset_name):                              Define the layer's tile set.
 // Getters and setters for a sprite_struct	:
  .asset_image_xscale_set(asset_struct, scale):	                              Set the asset's x scale
  .asset_image_yscale_set(asset_struct, scale):	                              Set the asset's y scale
  .asset_image_blend_set(asset_struct, blend):	                              Set the asset's x image_blend
  .asset_image_angle_set(asset_struct, angle):	                              Set the asset's x image_angle
  .asset_image_speed_set(asset_struct, speed):	                              Set the asset's image_speed
  .asset_image_x_set(asset_struct, x):                                        Set the asset's x coordinate
  .asset_image_y_set(asset_struct, y):                                        Set the asset's y coordinate
  */
#endregion 

// TODO : addinf layer should check depth and name conflicts before adding the layer
function yy_room(_gm_project_directory, _room_name) constructor 
{
	__struct    = undefined;   // The struct holding all the data from the Game Maker room .yy file
	__directory = undefined    // The Game Maker project directory.
	__unique_inst_token  = 1;  // A unique ID token to generate inst_name
	__unique_asset_token = 1;  // A unique ID token to generate inst_name
	set_from_file(_gm_project_directory, _room_name);
	
	#region Data Management from / to room .yy file
	/// @function					get_from_file(gm_project_directory, room_name)
	/// @description				Parse the Game Maker room .yy file targeted by the specified path and room name, and store its data in the __struct variable.
	/// @param {String}				gm_project_directory	The Game Maker project directory.
	/// @param {String}				room_name				The name of the room to parse.
	/// @return {Bool}				True if the creation suceeded.	
	static set_from_file = function(_gm_project_directory, _room_name) {
		if !directory_exists(_gm_project_directory) 
		{
			show_debug_message("Error: yy_room() constructor did not complete the setting. Directory " + string(_gm_project_directory) + " is invalid or does not exist.")
			return false;
		}
		__directory = _gm_project_directory;
		var _room_path = _gm_project_directory+"/rooms/"+_room_name+"/"+_room_name+".yy"
		if !file_exists(_room_path)
		{
			show_debug_message("Error: yy_room() constructor did not complete the setting. File " + string(_room_path) + " is invalid or does not exist.")
			return false;	
		}
		__struct = SnapFromJSON(SnapStringFromFile(_room_path));
		return true;
	}
	/// @function					save_to_directory()
	/// @description				Save the data from the __struct variable to the associated Game Maker room .yy file, with proper formating.
	/// @param {Bool}				When set to true, it instructs SNAP to ormat the string to be human readable. Easier for debugging.
	static  save_to_directory = function(_pretty = true) {
		var _room_name = __struct.name;
		var _room_path = __directory+"/rooms/"+_room_name+"/"+_room_name+".yy";
		SnapStringToFile(SnapToJSON(__struct, _pretty), _room_path);
	}
	/// @description				Return the Game Maker directory defined for this yy_room, the one that will be used to save back data to the .yy file.
	static get_project_directory = function() {
		return __directory
	}
	/// @description				Return true if this yy_struct has set its data... sort of.
	static is_set = function() {
		return is_struct(__struct);
	}
	#endregion
	
	#region Creating Layers data into a struct formated as a Game Maker room .yy file file expects it
	// return a struct describing an empty layer in the format expected within a .yy room file, within the layers array
	static instance_layer_create = function(_name, _depth, _grid_x = 32, _grid_y = 32, _overridde = true) 
	{
		var _layer_sruct = 
		{
			resourceType: "GMRInstanceLayer",
			resourceVersion: 1.0,
			name: _name,
			visible: true,
			depth: _depth,
			userdefinedDepth: false, // or true... 
			inheritLayerDepth: false,
			inheritLayerSettings: false,
			gridX: _grid_x,
			gridY: _grid_y,
			layers: [],
			hierarchyFrozen: false,
			effectEnabled: true,
			effectType: undefined,
			properties: [],
			instances: [],
		};
		var _array = get_layers();
		var _i = array_length(_array);
		repeat(_i)
		{
			--_i;
			if (_array[_i].name == _name)
			{
				if (_overridde) _array[@ _i] = _layer_sruct; 
				return 	_layer_sruct;
			}
		}
		array_push(_array, _layer_sruct);
		return 	_layer_sruct;
	}	
	static asset_layer_create = function(_name, _depth, _grid_x = 32, _grid_y = 32, _overridde = true) 
	{
		var _layer_sruct = 
		{
			resourceType: "GMRAssetLayer",
			resourceVersion: 1.0,
			name: _name,
			visible: true,
			depth: _depth,
			userdefinedDepth: false, // or true... 
			inheritLayerDepth: false,
			inheritLayerSettings: false,
			gridX: _grid_x,
			gridY: _grid_y,
			layers: [],
			hierarchyFrozen: false,
			effectEnabled: true,
			effectType: undefined,
			properties: [],
			assets: [],
		};
		var _array = get_layers();
		var _i = array_length(_array);
		repeat(_i)
		{
			--_i;
			if (_array[_i].name == _name)
			{
				if (_overridde) _array[@ _i] = _layer_sruct; 
				return 	_layer_sruct;
			}
		}
		array_push(_array, _layer_sruct);
		return 	_layer_sruct;
	}
	static background_layer_create = function( _name, _depth, _grid_x = 32, _grid_y = 32, _colour = 4285228368, _overridde = true) 
	{
		var _layer_sruct = 
		{
			resourceType: "GMRBackgroundLayer",
			resourceVersion: 1.0,
			name: _name,
			visible: true,
			depth: _depth,
			userdefinedDepth: false, // or true... 
			inheritLayerDepth: false,
			inheritLayerSettings: false,
			gridX: _grid_x,
			gridY: _grid_y,
			layers: [],
			hierarchyFrozen: false,
			effectEnabled: true,
			effectType: undefined,
			properties: [],
			spriteId: undefined,
			colour: _colour,
			x: 0,
			y: 0,
			htiled: false,
			vtiled: false,
			hspeed: 0.0,
			vspeed: 0.0,
			stretch: false,
			animationFPS: 15.0,
			animationSpeedType: 0,
			userdefinedAnimFPS: false,
		};
		var _array = get_layers();
		var _i = array_length(_array);
		repeat(_i)
		{
			--_i;
			if (_array[_i].name == _name)
			{
				if (_overridde) _array[@ _i] = _layer_sruct; 
				return 	_layer_sruct;
			}
		}
		array_push(_array, _layer_sruct);
		return 	_layer_sruct;
	}
	static tile_layer_create = function(_name, _depth, _grid_x = 32, _grid_y = 32, _tileset = "", _overridde = true) 
	{
		var _layer_sruct = 
		{
			resourceType: "GMRTileLayer",
			resourceVersion: 1.1,
			name: _name,
			visible: true,
			depth: _depth,
			userdefinedDepth: false, // or true... 
			inheritLayerDepth: false,
			inheritLayerSettings: false,
			gridX: _grid_x,
			gridY: _grid_y,
			layers: [],
			hierarchyFrozen: false,
			effectEnabled: true,
			effectType: undefined,
			properties: [],
			x: 0,
			y: 0,
			tilesetId:
			{
				name: _tileset,
				path: "tilesets/" + _tileset + "/" + _tileset + ".yy",
			},
			tiles: 
			{
				//TileDataFormat: 1, // ??
				SerialiseWidth: 0,
				SerialiseHeight: 0,
				TileSerialiseData: [], // instead of the more complex TileCompressedData: [],
			}
		};
		var _array = get_layers();
		var _i = array_length(_array);
		repeat(_i)
		{
			--_i;
			if (_array[_i].name == _name)
			{
				if (_overridde) _array[@ _i] = _layer_sruct; 
				return 	_layer_sruct;
			}
		}
		array_push(_array, _layer_sruct);
		return 	_layer_sruct;
	}
	#endregion

	#region Creating Instances and Sprite data into a struct formated as a Game Maker room .yy file expects it
	// return a struct describing an instance's property in the format that is expected within a .yy room file, within an GMRInstance
	static __create_instance_property = function(_owner_name, _property_name, _property_value) {
		return 
		{
			resourceType: "GMOverriddenProperty",
			resourceVersion: 1.0,
			name: "",
			propertyId:
			{
				name: _property_name,
				path:"objects/" + _owner_name + "/" + _owner_name + ".yy",
			},
			objectId:
			{
				name: _owner_name,
				path: "objects/" + _owner_name + "/" + _owner_name + ".yy",
			},
			value: _property_value,
		};
	}

	static instance_set_property = function(_instance_struct, _property_name, _property_value, _ignore_obj_def = false) {	

		if _property_name      == "image_blend"  _instance_struct.coulour    = _property_value;
		else if _property_name == "image_angle"  _instance_struct.rotation   = _property_value;
		else if _property_name == "image_index"  _instance_struct.imageIndex = _property_value;
		else if _property_name == "image_speed"  _instance_struct.imageSpeed = _property_value;
		else if _property_name == "image_xscale" _instance_struct.scaleX     = _property_value;
		else if _property_name == "image_yscale" _instance_struct.scaleY     = _property_value;			
		else
		{
				var _obj_name = _instance_struct.objectId.name;
				if (_ignore_obj_def == false)
				{
					var _obj_struct = new yy_object(get_project_directory(), _obj_name);
					var _owner_name =_obj_struct.get_property_owner(_property_name);
					if _owner_name == undefined 
					{
						show_debug_message("[YY] warning: instance_set_property(), the property " + string(_property_name) + " is not defined for object " + string(_obj_name) + ". It will be ignored.");
						return undefined;
					}
				}
				else 
				{
					var _owner_name = _obj_name;
				}
				var _new_prop = __create_instance_property(_owner_name, _property_name, _property_value);
				var _properties_array = _instance_struct[$ "properties"];
				var _i = array_length(_properties_array);
				repeat(_i)
				{
					--_i;
					if _properties_array[_i].propertyId.name = _property_name  
					{
						_instance_struct[$ "properties"][_i] = _new_prop;
						exit;	
					}
				}
				array_push(_instance_struct[$ "properties"], _new_prop);	
		}
	}
	
	// return a struct describing an instance by using the format that is expected within a .yy room file, within an InstanceLayer
	static instance_create = function(_x, _y, _layer_struct, _object_name, _variables_struct, _register = true) {
		var _yy_instance_struct = {
			resourceType: "GMRInstance",
			resourceVersion: 1.0,
			name: _object_name+"_"+string(__unique_inst_token++),
			properties: [],
			isDnd: false,
			objectId:
			{
				name: _object_name,
				path: "objects/" + _object_name + "/" + _object_name + ".yy",
			},
			inheritCode: false,
			hasCreationCode: false,
			colour: 4294967295,
			rotation: 0.0,
			scaleX: 1.0,
			scaleY: 1.0,
			imageIndex: 0,
			imageSpeed: 1.0,
			inheritedItemId: undefined,
			frozen: false,
			ignore: false,
			inheritItemSettings: false,
			x: _x,
			y: _y,
		}

		if _variables_struct != undefined 
		{
			var _properties_array = [];
			var _variables_names = variable_struct_get_names(_variables_struct);
			var _i = 0;
			var _added_a_property = false;
			repeat(array_length(_variables_names))
			{
				var _variable_name_i  = _variables_names[ _i];
				var _variable_value_i = _variables_struct[$ _variable_name_i];
				{
					instance_set_property(_yy_instance_struct, _variable_name_i, _variable_value_i);
				}
				_i++;
			}
		}
		array_push(_layer_struct.instances, _yy_instance_struct);
		
		if _register 
		{
			register_instance_creation(_yy_instance_struct);
		}
		
		return _yy_instance_struct;
	}

	static register_instance_creation = function(_instance_struct)
	{
		var _name = _instance_struct.name
		var _creation_order_struct = 
		{
			name: _name,
			path: "rooms/"+__struct.name+"/"+__struct.name+".yy",
		};
		var _array = __struct.instanceCreationOrder;
		var _i = array_length(_array);
		repeat(_i)
		{
			--_i;
			if (_array[_i].name = _name)  
			{
				array_delete(_array, _i, 1);
			}
		}
		array_insert(__struct.instanceCreationOrder, 0, _creation_order_struct);
	}
	// Remove the specified instance from the instance creation order.
	static remove_instance_creation = function(_instance_struct)
	{
		/*debuging line shw("Removing ", _instance_struct.name); 		shw("Array before", __debug_creation_order());*/
		var _name = _instance_struct.name
		var _array = __struct.instanceCreationOrder;
		var _i = array_length(_array);
		repeat(_i)
		{
			--_i;
			if (_array[_i].name == _name)  
			{
				array_delete(_array, _i, 1);	
			}
		}
		/*debuging line sshw("Array after", __debug_creation_order());*/
	}

	/*debuging function static __debug_creation_order = function() {
		var _array = __struct.instanceCreationOrder;
		var _i = array_length(_array);
		var _st = "";
		repeat(_i)
		{
			--_i;
			_st += string(_array[_i].name) + ", ";
		}
		return _st;
	}*/
	
	
	static asset_create = function(_layer, _x, _y, _sprite_name) {
		return {
			resourceType: "GMRSpriteGraphic",
			resourceVersion: "1.0",
			name: _sprite_name+string(__unique_asset_token++),
			spriteId:
			{
				name: _sprite_name,
				path: "sprites/"+_sprite_name+"/"+_sprite_name+".yy"
			},
			headPosition: 0.0,
			rotation: 0.0,
			scaleX: 1.0, 
			scaleY: 1.0,
			animationSpeed: 1.0,
			colour:4294967295,
			inheritedItemId: null,
			frozen:	false,
			ignore: false,
			inheritItemSettings: false,
			x: _x,
			y: _y,
		};
	}
	#endregion

	#region Getters and Setters for the room data
	// Room dimensions
	static get_width = function() {
		return __struct.roomSettings.Width;
	}
	static set_width = function(_width) {
		if _width  != undefined __struct.roomSettings.Width = _width;
	}
	static get_height = function() {
		return  __struct.roomSettings.Height;
	}
	static set_height = function(_height) {
		if _height != undefined __struct.roomSettings.Height = _height;
	}
	// Room name
	static get_name = function() {
		return  string(__struct.name);
	}
	// Room instances creation order
	static get_instance_creation_order = function() {
		return  __struct.instanceCreationOrder;
	}
	static set_instance_creation_order = function(_inst_creation_order_array) 
	{
		if _inst_creation_order_array != undefined __struct.instanceCreationOrder = _inst_creation_order_array;
	}
	static clear_instance_creation_order = function() {
		__struct.instanceCreationOrder = [];
	}
	// Room layers
	static get_layers = function() {
		return  __struct.layers;
	}
	static set_layers = function(_layers_array) {
		if _layers_array != undefined __struct.layers = _layers_array;
	}
	static clear_layers = function() {
		__struct.layers = [];
	}
	static add_layer = function(_layer_struct, overridde = true) 	{
		var _array = __struct.layers;
		var _i = array_length(_array);
		repeat(_i)
		{
			--_i;
			if _array[_i].name = _layer_struct.name 
			{
				if (_overridde) __struct.layers[_i] = _layer_struct;
				exit;	
			}
		}
		array_push(__struct.layers, _layer_struct);
	}	
	static get_layer = function(_layer_name) {
		var _array = __struct.layers;
		var _i = array_length(_array);
		repeat(_i)
		{
			--_i;
			if _array[_i].name = _layer_name return _array[_i]
		}
		return undefined;
	}
	#endregion
	
	#region Getters and Setters for the room data
	static layer_visible_get      = function(_layer_struct)           {
		return _layer_struct.visible;
	}
	static layer_visible_set      = function(_layer_struct, _visible) {
		_layer_struct.visible = _visible;
		return true;
	}
	static layer_grid_x_set       = function(_layer_struct, _grid_x)  {
		_layer_struct.gridX= _grid_x;
		return true;
	}
	static layer_grid_y_set       = function(_layer_struct, _grid_y)  {
		_layer_struct.gridY= _grid_y;
		return true;
	}
	static layer_depth_get        = function(_layer_struct) {
		return  _layer_struct.depth;
	}
	static layer_depth_set        = function(_layer_struct, _depth) {
		_layer_struct.depth = _depth;
		return true;
	}
	static layer_instances_get    = function(_layer_struct, _instances_array) {
		if _layer_struct.resourceType != "GMRInstanceLayer"
		{
			show_debug_message("[YY: Warning, calling layer_instances_get() on a struct that is not a proper GM instance Layer");
			return [];
		}
		return _layer_struct.instances;
	}
	static layer_instances_set    = function(_layer_struct, _instances_array) {
		if _layer_struct.resourceType != "GMRInstanceLayer"
		{
			show_debug_message("[YY: Warning, calling layer_instances_set() on a struct that is not a proper GM instance Layer");
			return false;
		}
		_layer_struct.instances = _instances_array;
		return true;
	}
	// Clear the layer's instances array and remove those instances from the instance creation order.
	static layer_instances_clear  = function(_layer_struct) {
		if _layer_struct.resourceType != "GMRInstanceLayer"
		{
			show_debug_message("[YY: Warning, calling layer_instances_clear() on a struct that is not a proper GM instance Layer");
			return false;
		}
		// clear from instance creation order
		var _array = _layer_struct.instances;
		var _i = array_length(_array);
			shw("Removing from creation order ", _i, " instances.");
			repeat(_i)
			{
				--_i;
				shw("Remove step ", _i);
				remove_instance_creation(_array[_i]);
			}
		// clear instances array
		_layer_struct.instances = [];
		return true;
	}
	static layer_tiles_data_set   = function(_layer_struct, _tiles_width, _tiles_height, _tiles_data) {
		if _layer_struct.resourceType != "GMRTileLayer"
		{
			show_debug_message("[YY: Warning, calling layer_tiles_set() on a struct that is not a proper GM Tile Layer");
			return false;
		}
		_layer_struct.tiles = {
			//TileDataFormat: 1, // ??
			SerialiseWidth: _tiles_width,
			SerialiseHeight: _tiles_height,
			TileSerialiseData: _tiles_data, // instead of the more complex TileCompressedData: [],
		}
		return true;
	}
	static layer_tileset_set      = function(_layer_struct, _tileset_name) {
		if _layer_struct.resourceType != "GMRTileLayer"
		{
			show_debug_message("[YY: Warning, calling layer_tileset_set() on a struct that is not a proper GM Tile Layer");
			return false;
		}
		_layer_struct.tilesetId =
		{
			name: _tileset_name,
			path: "tilesets/"+_tileset_name+"/"+_tileset_name+".yy",
		};
		return true;
	}
	#endregion

	#region Getters and setters for a sprite_struct
	static asset_image_xscale_set = function(_asset_struct, _scale) {
		_asset_struct.scaleX = _scale;
	}
	static asset_image_yscale_set = function(_asset_struct, _scale) {
		_asset_struct.scaleY = _scale;
	}
	static asset_image_blend_set  = function(_asset_struct, _blend) {
		_asset_struct.colour = _blend;
	}
	static asset_image_angle_set  = function(_asset_struct, _angle) {
		_asset_struct.rotation = _angle;
	}
	static asset_image_speed_set  = function(_asset_struct, _speed) {
		_asset_struct.animationSpeed = _speed;
	}
	static asset_x_set            = function(_asset_struct, _x)     {
		_asset_struct.x = _x;
	}
	static asset_y_set            = function(_asset_struct, _y)     {
		_asset_struct.y = _y;
	}
	#endregion

}

#region yy_object notes
/*
yy_object constructor requires two arguments: the Game Maker project directory where the object is stored and the name of the object.
The resulting struct has two private variables: one storing the data from Game Maker .yy file and one storing the path to the Game Maker project directory.
It also comes with the following methods:
 // Data Management from / to .yy file:
  .set_from_file(gm_project_directory, object_name): Parse the Game Maker object .yy file targeted by the specified path and object name, and store its data in the __struct variable.
  .save_to_directory():                              Save the data from the __struct variable to the associated Game Maker object .yy file, with proper formating.
  .get_project_directory():                          Return the Game Maker directory defined for this yy_object, the one that will be used to save back data to the .yy file.
  .is_set():                                         Return true if this yy_struct has set its data... sort of.
 // Getters and setters for name and parent:
  .get_name():			                             Return the name of the object.
  .get_parent_name():	                             Return the name of the parent object or undefined.
  .get_parent_struct():	                             Return object_struct with all file data of the parent object or undefined.
 // Getters and setters for the properties array:
  .get_properties():                                 Return the array of 'Classic' Properties with all their data.
  .set_properties(properties_array):                 Set the array of 'Classic' Properties.
  .clear_properties():                               Clear the array of 'Classic' Properties.
  .get_overridden_properties():                      Return the array of 'Overriden' Properties with all their data.
  .set_overridden_properties(properties_array):      Set the array of 'Overriden' Properties. 
  .clear_overridden_properties():                    Clear the array of 'Overriden' Properties.
 // Getters and setters for property:
  .add_property(property_struct, overridde, respect_ownership): Add the property definition to the object, after evaluating if the property is inherited from a parent object.
  .get_property_owner()  
  .get_property(): 
  .exists_property
  .exists_property:		                             Return true if a property with the associated name exists in this object (or its ancestors).
  .property_is_overriden
   ... Work in progress
*/
#endregion

function yy_object(_gm_project_directory, _object_name) constructor 
{
	__stuct    = undefined;   // The struct holding all the data from the Game Maker room .yy file
	__directory = undefined    // The Game Maker project directory.
	set_from_file(_gm_project_directory, _object_name);
	
	#region Data Management from / to object .yy file
	/// @function					get_from_file(gm_project_directory, object_name)
	/// @description				Parse the Game Maker room .yy file targeted by the specified path and room name, and store its data in the __struct variable.
	/// @param {String}				gm_project_directory	The Game Maker project directory.
	/// @param {String}				room_name				The name of the room to parse.
	/// @return {Bool}				True if the creation suceeded.		
	static set_from_file = function(_gm_project_directory, _object_name) {
		if !directory_exists(_gm_project_directory) 
		{
			show_debug_message("Error: yy_object() constructor did not complete the setting. Directory " + string(_gm_project_directory) + " is invalid or does not exist.")
			return false;
		}
		__directory = _gm_project_directory;
		var _obj_path = _gm_project_directory+"/objects/"+_object_name+"/"+_object_name+".yy"
		if !file_exists(_obj_path)
		{
			show_debug_message("Error: yy_object() constructor did not complete the setting. File " + string(_obj_path) + " is invalid or does not exist.")
			return false;	
		}
		__struct = SnapFromJSON(SnapStringFromFile(_obj_path));	
		return true;
	}
	/// @function					save_to_directory()
	/// @description				Save the data from the __struct variable to the associated Game Maker room .yy file, with proper formating.
	/// @param {Bool}				pretty When set to true, it instructs SNAP to ormat the string to be human readable. Easier for debugging.
	static  save_to_directory = function(_pretty = true) {
		var _object_name = __struct.name;
		var _obj_path = __directory+"/objects/"+_object_name+"/"+_object_name+".yy"
		SnapStringToFile(SnapToJSON(__struct, _pretty), _obj_path);
	}
	// Directory method
	static get_project_directory = function() {
		return __directory
	}
	static is_set = function() {
		return is_struct(__struct);
	}
	#endregion
	
	#region  Atomic functions to get, set, clear data in the Object struct
	// Object name
	static get_name = function() {
		return  string(__struct.name);
	}
	// Object parent
	static get_parent_name   = function() {
		if (__struct.parentObjectId == undefined or __struct.parentObjectId == pointer_null) return undefined;
		return __struct.parentObjectId.name;
	}
	static get_parent_struct = function() {
		var _parent_name = get_parent_name();
		if (_parent_name == undefined or _parent_name == pointer_null) return undefined;
		var _parent_struct = new yy_object(__directory, _parent_name);
		return _parent_struct;
	}
	// Object properties, classic Properties and OverridenProperties
	static get_properties    = function() {
		return  __struct.properties;
	}
	static set_properties    = function(_properties_array) {
		if _properties_array != undefined __struct.properties = _properties_array;
	}
	static clear_properties  = function() {
		__struct.properties = [];
	}
	static get_overridden_properties   = function() {
		return  __struct.overriddenProperties;
	}
	static set_overridden_properties   = function(_properties_array) {
		if _properties_array != undefined __struct.overriddenProperties = _properties_array;
	}
	static clear_overridden_properties = function() {
		__struct.overriddenProperties = [];
	}	
	/// @function					add_property(property_struct, overridde, check_parents)
	/// @description				Add the property definition to the object, after evaluating if the property is inherited from a parent object.
	/// @param {Struct}				property_struct		The struct holding all property data, formated as Game MAker likesd it.
	/// @param {Bool}				overridde			When true, the property definition will overridde the existing one with the same name.
	/// @param {Bool}				respect_ownership	When true, the property name will be searched in parents/anecestors to defined as an inherited properties if it exists. If you don't understand leave that to true.
	static add_property = function(_property_struct, _overridde = true, respect_ownership = true) 	{
		if (respect_ownership)
		{
			var _property_name  = _property_struct.name;
			var _property_onwer = get_property_owner(_property_name);
			if (_property_onwer == undefined or _property_onwer == get_name())
			{
				if (property_is_overriden(_property_struct) == true) show_debug_message("[YY] Error: add_property() called with Overriden Property but there is no owner in parents/ancestors.");
				__add_classic_property(_property_struct, _overridde);			
			}
			else 
			{
				if (property_is_overriden(_property_struct) == false) _property_struct = yy_convert_property_to_overriden(_property_struct, _property_onwer);
				__add_inherited_property(_property_struct, _overridde);	
			}
			/*
			if exists_property(_property_struct.name, false)
			{
				__add_classic_property(_property_struct, _overridde);
				exit;	
			}
			var _parent_name = get_property_parent(_property_struct.name);
			if (_parent_name != undefined)
			{
				_property_struct = yy_convert_property_to_overriden(_property_struct, _parent_name);
				__add_inherited_property(_property_struct, _overridde);	
				exit;
			}
			else
			{
				__add_classic_property(_property_struct, _overridde);		
				exit;
			}*/
		}
		else
		{
			__add_classic_property(_property_struct, _overridde);	
		}
	}	
	
	static get_property_owner = function(_property_name) 	{
		var _array = get_properties();
		var _i     = array_length(_array);
		repeat(_i)
		{
			--_i;
			if (_array[_i].name == _property_name) 
			{
				return get_name();
				exit;
			}
		}
		var _parent_struct = get_parent_struct();
		if (_parent_struct == undefined) return undefined;	
		return _parent_struct.get_property_owner(_property_name);
	}

	/// @description				Internal method to create and add an 'Classic' Property. It does no consistency check, so it is advice not to use this method.
	static __add_classic_property = function(_property_struct, _overridde = true) 	{
		var _property_name = _property_struct.name;
		var _array = get_properties();
		var _i = array_length(_array);
		repeat(_i)
		{
			--_i;
			if (_array[_i].name == _property_name)
			{
				if (_overridde) __struct.properties[@ _i] =  _property_struct; 
				exit;
			}
		}
		array_push(__struct.properties, _property_struct);
	}	
	/// @description				Internal method to create and add an OverridenProperty. It does no consistency check, so it is advice not to use this method.
	static __add_inherited_property = function(_property_struct, _overridde = true) 	{
		var _property_name = _property_struct.propertyId.name;
		var _array = get_overridden_properties();
		var _i = array_length(_array);
		repeat(_i)
		{
			--_i;
			if (_array[_i].propertyId.name == _property_name)
			{
				if (_overridde) __struct.overriddenProperties[@ _i] =  _property_struct;
				exit;
			}
		}
		array_push(__struct.overriddenProperties, _property_struct);
	}
	/// @function					get_property(property_name)
	/// @description				Return the struct holding data for the property with the associated name. undefined if there is no such property.
	/// @param {String}				property_name		The name of the property to look for.
	/// @param {Bool}				overriden_too		When true, Overriden Property will also be got. False will only search 'Classic' Properties.
	static get_property = function(_property_name, overriden_too = true) {
		if !is_set() { show_debug_message("[YY] Error: exists_property() aborted. It was called on a yy_struct without data."); return false; }
		var _array = get_properties();
		var _i = array_length(_array);
		repeat(_i)
		{
			--_i;
			if (_array[_i].name = _property_name) return _array[@ _i];
		}
		if (overriden_too)
		{
			_array = get_overridden_properties();
			_i = array_length(_array);
			repeat(_i)
			{
				--_i;
				if (_array[_i].propertyId.name  = _property_name) return _array[@ _i];
			}
		}
		return undefined;
	}
	/// @function					exists_property(property_name, check_parents)
	/// @description				Return true if a property with the associated name exists in this object (or its ancestors).
	/// @param {String}				property_name		The name of the property to look for.
	/// @param {Bool}				check_parents		When true, the property will be searched in parents/anecestors. If you don't understand leave that to true.
	static exists_property = function(_property_name, _check_parents = true) {
		if !is_set() { show_debug_message("[YY] Error: exists_property() aborted. It was called on a yy_struct without data."); return false; }
		var _array = get_properties();
		var _i = array_length(_array);
		repeat(_i)
		{
			--_i;
			if (_array[_i].name = _property_name) return true;
		}
		if (_check_parents)
		{
			var _parent_struct = get_parent_struct();
			if (_parent_struct == undefined) return false;
			else                             return _parent_struct.exists_property(_property_name, true);
		}
		else 
		{
			return false;
		}
	}
	/// @function					exists_duplicated_properties()
	/// @description				Checks if any property is duplicated as a property and inherited property.
	static exists_duplicated_properties = function(_verbose = true) {
		var _parent_struct = get_parent_struct();
		if (_parent_struct == undefined) return false;
		var _return = false;
		var _log    = "";
		var _array  = get_properties();
		var _i = array_length(_array);
		repeat(_i)
		{
			--_i;
			var _parent_name = _parent_struct.get_property_owner(_array[_i].name);
			if (_parent_name != undefined)
			{
				_log += _array[_i].name + ", "
				_return = true;
			}
		}
		if _return and _verbose show_debug_message("[YY] log: exists_duplicated_properties(). There are a duplicated properties: " + _log);
		return _return;
	}
	/// @function					property_is_overriden(property_struct)
	/// @description				Return true if the passed struct (not name) is an Overridden Property. Otherwise it is a 'Classic' Properties.
	static property_is_overriden = function(_property_struct) {
		return (_property_struct.resourceType == "GMOverriddenProperty");
	}
	
	#endregion
		/*Warning: if you search for this line, this is beacause YY ask you to... If you are just reading this out of curiosity, don't bother...
		DUPLICATE_PROPETRY ERROR_DETAILS
		There is a duplicated property in your object. (a property = a variable from the [Variable Definitions] panel of an object).
		When there is a duplicate, .YY library will not modify this object file as it will likely delete the values you have already defined for this property in Game Maker room editor (in the [variable] panel of an instance).
		If you want to proceed, please clean your Game Maker project before, by deleting property duplicates in the targetded object. 
		It is likely you have one version for the object and one version for a parent/ancestor. Delete the one for the object.
		What did you do wrong?
		Nothing, this is due to Game Maker IDE missing one of your move.
		An object properly defined in Game Maker, cannot have two properties with the same name.  (again a property = a variable from the [Variable Definitions] panel of an object)
		This means a property defined at its level cannot share the name of a property defined at parents/ancestor level. You will notice that if in the [Variable Definitions], you try to add a varialble using a name already existing at parent/ancestor level, Game Maker IDE will change it to prevent the duplicate.
		But... in rare case, Game Maker IDE is not vigilant enough. It can be the case if you define a property for an object and then set this object as a children of an object with the same property. Two variables with the same name will exist.
		Game Maker IDE is able to manage that without issue, and you likely have set values for this duplicated property in Game Maker room editor (in the [variable] panel of an instance). But if you update the data for this property, Game Maker will de
		The best course is to get rid of the duplicates and redefine your values in Game Maker room editor.
		To get rid of duplicates you can just delete the property defined at children level. You can click the pen button if you want to give the property a specific value at children level.
		*/
}

#region yy_sprite notes
/*
yy_sprite constructor requires two arguments: the Game Maker project directory where the sprite is stored and the name of the sprite.
The resulting struct has two private variables: one storing the data from Game Maker .yy file and one storing the path to the Game Maker project directory.
It also comes with the following methods:
 // Data Management from / to .yy file:
  .set_from_file(gm_project_directory, sprite_name): Parse the Game Maker sprite .yy file targeted by the specified path and sprite name, and store its data in the __struct variable.
  .save_to_directory():                              Save the data from the __struct variable to the associated Game Maker sprite .yy file, with proper formating.
  .get_project_directory():                          Return the Game Maker directory defined for this yy_sprite, the one that will be used to save back data to the .yy file.
  .is_set():                                         Return true if this yy_struct has set its data... sort of.
 // Getters for the sprite data:
  .get_name():    Return the name of the sprite.
  .get_width():   Return the width of the sprite.
  .get_height():  Return the height of the sprite.
  .get_xorigin(): Return the x coordinate of the origin of the sprite.
  .get_yorigin(): Return the y coordinate of the origin of the sprite.
*/
#endregion
function yy_sprite(_gm_project_directory, _sprite_name) constructor 
{
	__struct    = undefined;	// The struct holding all the data from the Game Maker sprite .yy file
	__directory = undefined		// The Game Maker project directory.
	set_from_file(_gm_project_directory, _sprite_name);
	
	#region Load / Save Game Maker sprite .yy file
	/// @function					get_from_file(gm_project_directory, room_name)
	/// @description				Parse the Game Maker room .yy file targeted by the specified path and room name, and store its data in the __struct variable.
	/// @param {String}				gm_project_directory	The Game Maker project directory.
	/// @param {String}				room_name				The name of the room to parse.
	/// @return {Bool}				True if the creation suceeded.
	static set_from_file = function(_gm_project_directory, _sprite_name) {
		if !directory_exists(_gm_project_directory) 
		{
			show_debug_message("Error: yy_sprite() constructor did not complete the setting. Directory " + string(_gm_project_directory) + " is invalid or does not exist.")
			return false;
		}
		__directory = _gm_project_directory;
		var _spr_path = _gm_project_directory+"/sprites/"+_sprite_name+"/"+_sprite_name+".yy"
		if !file_exists(_spr_path)
		{
			show_debug_message("Error: yy_sprite() constructor did not complete the setting. File " + string(_spr_path) + " is invalid or does not exist.")
			return false;	
		}
		__struct = SnapFromJSON(SnapStringFromFile(_spr_path));	
		return true;
	}
	static is_set = function() {
		return is_struct(__struct);
	}
	/// @function					save_to_directory()
	/// @description				Save the data from the __struct variable to the associated Game Maker room .yy file, with proper formating.
	/// @param {Bool}				pretty When set to true, it instructs SNAP to format the string to be human readable. Easier for debugging.
	static  save_to_directory = function(_pretty = true) {
		var _sprite_name = __struct.name;
		var _spr_path = __directory+"/sprites/"+_sprite_name+"/"+_sprite_name+".yy"
		SnapStringToFile(SnapToJSON(__struct, _pretty), _spr_path);
	}
	#endregion
	
	#region  Getters and setters for the sprite data
	// Directory
	static get_project_directory = function() {
		return __directory
	}
	static get_name = function() {
		return  string(__struct.name);
	}
	static get_width = function() {
		return  __struct.width;
	}
	static get_height = function() {
		return  __struct.height;
	}
	static get_xorigin = function() {
		return  __struct.xorigin;
	}
	static get_yorigin = function() {
		return  __struct.xorigin;
	}
	#endregion
}

/// @function					yy_property(name, default_value, varType, rangeMin, _rangeMax, _rangeEnabled)
/// @description				Return a stuct (with just data and no methods) for a property fommated as Game Maker expects in object files. It can then be written to object files.
function yy_property(_name, _default_value, _varType = YY_varType.Integer, _rangeMin = 0, _rangeMax = 0, _rangeEnabled = false)
{
	return {
		resourceType:    "GMObjectProperty",
		resourceVersion: "1.0",
		name:            _name,
		varType:         _varType,
		value:           _default_value,
		rangeEnabled:    _rangeEnabled,
		rangeMin:        _rangeMin,
		rangeMax:        _rangeMax,
		listItems:       [],
		multiselect:     false,
		filters:         [],
	};
}
/// @function					yy_property(name, default_value, varType, rangeMin, _rangeMax, _rangeEnabled)
/// @description				Return a stuct (with just data and no methods) for an overriden property (property defined in anecestor object and modified at this level) fommated as Game Maker expects in object files. It can then be written to object files.
function yy_overriden_property(_name, _default_value, _owner_name) // parent holding the property
{
	return {
		resourceType:    "GMOverriddenProperty",
		resourceVersion: "1.0",
		name:            "",
		value:           _default_value,
		propertyId:
		{
			name: _name,
			path: "objects/" +  _owner_name + "/" +  _owner_name + ".yy",
		},
		objectId:
		{
			name: _owner_name,
			path: "objects/" +  _owner_name + "/" +  _owner_name + ".yy",
		}
	};
}
/// @function					yy_property(name, default_value, varType, rangeMin, _rangeMax, _rangeEnabled)
/// @description				Converts a struct for a property to an overriden property (property defined in anecestor object and modified at this level) fommated as Game Maker expects in object files.
function yy_convert_property_to_overriden(_property_struct, _owner_name) {
	return {
		resourceType:    "GMOverriddenProperty",
		resourceVersion: "1.0",
		name:            "",
		value:           _property_struct.value,
		propertyId:
		{
			name: _property_struct.name,
			path: "objects/" +  _owner_name + "/" +  _owner_name + ".yy",
		},
		objectId:
		{
			name: _owner_name,
			path: "objects/" +  _owner_name + "/" +  _owner_name + ".yy",
		}
	};
}
/// @function					yy_sprite_exist(gm_project_directory, sprite_name)
/// @description				Return true if a sprite .yy file with the associated name exists in the targeted Game Maker project directory. False otherwise.
function yy_sprite_exist(_gm_project_directory, _spr_name) {
	return file_exists(_gm_project_directory + "/sprites/" + string(_spr_name) + "/" + string(_spr_name) + ".yy");
}
/// @function					yy_object_exist(gm_project_directory, object_name)
/// @description				Return true if an object .yy file with the associated name exists in the targeted Game Maker project directory. False otherwise.
function yy_object_exist(_gm_project_directory, _obj_name) {
	return file_exists(_gm_project_directory + "/objects/" + string(_obj_name) + "/" + string(_obj_name) + ".yy");
}
/// @function					yy_room_exist(gm_project_directory, room_name)
/// @description				Return true if a room .yy file with the associated name exists in the targeted Game Maker project directory. False otherwise.
function yy_room_exist(_gm_project_directory, _room_name) {
	return file_exists(_gm_project_directory + "/rooms/" + string(_room_name) + "/" + string(_room_name) + ".yy");
}
/// @function					yy_tileset_exist(gm_project_directory, tileset_name)
/// @description				Return true if a tileset .yy file with the associated name exists in the targeted Game Maker project directory. False otherwise.
function yy_tileset_exist(_gm_project_directory, _tileset_name) {
	return file_exists(_gm_project_directory + "/tilesets/" + string(_tileset_name) + "/" + string(_tileset_name) + ".yy");
}


#region Minimalist Documentation
function YY_README_LINK() {}  // Fake anchor so that double-clicking will bring you here.
/* 
# YY LIB - Game Maker Files Modifier
YY is a small collection of functions to adjust Game Maker room files and object files within your project directory. It is intended to pair with external level editor to facilitate import into Game Maker project.

## About L2G

### Use case
YY allows to modify Game Maker room files and object files. It is intended to help people work on level editor features. For example to import room data from an external level editor or to replicate in room data modifications done at runtime. 

### Features
It allows to modify rooms, in particular by creating layers and populating them with instances or tiles.  
It also allows to modify object, in particular by creating properties (=variables from [Variables Definitions] section of Objects Editor).  
I tried to keep the syntax close to what you would use in GML so that you can, for example, create an instance in your room file with instance_create().  
There is a basic demo with two example of how to parse a room at runtime in room .yy file. The first showcases serializing instances created at runtime. The second showcases serializing tiles that you have created at runtime.  
I have another example allowing to import the full configuration for entities from a LDtk file, but it is not documented.

### License
YY is fully free. Do whatever you want with it.

### Version and Platform
YY is tested on Game Maker LTS and on windows platform.


## Installation

### Importing YY in your project
YY needs to be imported as a local package in your Game Maker project.
-	Download the .yymp file from GITHUB.
-	Import it inside your project. You can do this by dragging the *. yymp file from an explorer window onto the GameMaker IDE or by clicking "Import Local Package" within the Tools Menu. In both case, a window will pop up to define import parameters. Click “add all” and “OK”.  
This will create a two folders in your Asset Browser labeled “YY - GM Files Modifier” and "SNAP". The code is ready to be used.

### Make sure sandboxing is de-activated
There is likely one last step to use YY. Indeed, if the Game Maker files you want to update are located out of Game Maker sandbox repository, which will surely be the case, you need to de-activate sandboxing. You can do so, on the Desktop targets (Windows, macOS, and Ubuntu (Linux)), by checking the “Disable file system sandbox” option in the Game Options for the target platform.


## How to use

### Overall process
YY is not capable of creating files (to avoid having too much impact in your project structure), you will need to recycle existing files already created within Game Maker. 
The typical process runs in three steps: 
-	1.create a yy_class from an existing Game Maker file, this will hold all data from the targeted Game Maker file, 
-	2.update the data accordingly to your need, 
-	3.write back the data to the file.

Example:<br>
> // 1.create a yy_room for the current room<br>
> var _room = new yy_room(filename_dir(GM_project_filename), room_get_name(room)); <br>
> // 2.update the data<br>
> _room.set_width(400); // change room size<br>
> _room.instance_layer_create("layer_1", 100) // create a layer in the room at depth 100<br>
> var _inst _room.instance_create(0, 0, _room.get_layer("layer_1"), "YY_TEST_object3") // create an instance onto the layer<br>
> _room.instance_set_property(_inst, "health", 10) // set a property for the instance (=variables value from the [Variable] section for the instance in the Room Editor).<br>
// 3.write back the data to the file<br>
_room_struct.save_to_directory();<br>

### Effects within Game Maker IDE
Once a Game Maker .yy file updated with save_to_directory(), changes will be reflected within Game Maker IDE. Updating a project which is currently opened is fine. Indeed, Game Maker IDE is smart enough to detect these changes 'live' and ask you what to do in a warning window. If you click 'Save', YY changes will be deleted and the resource will be kept unchanged, if you click 'Reload', YY changes will be taken into account.  

Please note that, some updates are not imediately visible in Game Maker IDE, notably:
- when modifying object variables from the [Variables Definitions] section of the Object Editor, you will need to close the section and reopen it.
- when modifying tiles for a tile layer, you will need to close the associated room and reopen it.

### Features overview
Layer :
- create layers (instances layer, assets layer, tiles layer and background layer).
- modify layers' attribute (depth, visible, grid).
- populating layers with instances, tiles and sprites depending on their type.
- clear all layers or clear a specific layer. 

Instances : 
- setting instances' attributes (x/y position, scales, image_angle, image_speed, image_blend)
- setting properties values for instances (=variables value from the [Variable] section for the instance in the Room Editor). 

Object:
- modify objects configuration, in particular properties (=variables from [Variables Definitions] section of Objects Editor).


### Classes and functions documentation
[See the wiki for more details](https://github.com/MichelVGameMaker/YY_LIB/wiki) 
Documentation is a limited so far.

### YY respects Game Maker formating
YY manages data accordingly to what Game Maker expects. In particular:
- creating an instance into a room will also add it to the instances_creation_order.
- deleting an instance will also delete it from the instances_creation_order.
- creating a property into an object will set the proper type and the proper object (potentialy a parent/ancestor).
- setting a property value into an instance will make sure the property exists and points to the proper object (looping in parent/ancestor).


## Behind the hood

YY mainly relies on Juju's SNAP to preserve the json format expected by Game Maker. SNAP offers advanced data parsing features. If you do not know about it, or worse about Juju’s library, you can check them out here: https://github.com/JujuAdams.  
Other than that, YY is just there to modify data structure accordingly to what Game Maker expects. For instance, it will scan object's ancestors for property definition to avoid conflict, it will delete instances from the 'creation order' list when deleting instances from a layer.... It does a lot of data processes and is not fast.
*/
#endregion

#region Game Maker .yy file specication
/*
This section is NOT Game Maker specification but the results from my very limited retro-engineering
## Romm .yy file / json
The room file is a BIG json. For YY library, the most important part of this json is the layers array.

  |Attribute                  |Type         | Value (= or example)	         | Definition/Note
  |---                        |---          | ---                            | ---
  |resourceType:              |{string},    = "GMObject",                    |the type that you will find in all Game Maker resources.
  |resourceVersion:           |{float},     = "1.0",                         |the formating version. 1.0 seems to always work even if I saw some resources with 1.1.
  |name:                      |{string},    Ex: "ROOM1",                     |the name of the resource as it appears in your Game Maker project.
  |isDnd:                     |             |false,                          |
  |volume:                    |             |1.0,                            |
  |parentRoom:                |             |null,                           |
  |views:                     |{array}      |                                |array holding the 8 views, , YY does not modify views that will be inherited from the parsed file
  |layers:                    |{array}      |                                |this the heart of a room content. Each layer is a struct has defined below in the layer section
  |inheritLayers:             |false,       |,                               |
  |creationCodeFile:          |"",          |,                               |
  |inheritCode":              |{}           |false,                          |
  |instanceCreationOrder      |{array},     |{see below},                    |lists all the instances in the room in the order that they will be created.  (each instances is a struct with two attribute : the instance ID and the path to the room)
  |  >name:                   |{string},    |                                |the name of the instance (ex: inst_442BED1)
  |  >path:                   |{path},      |                                |rooms/ROOM1/ROOM1.yy
  |inheritCreationOrder:      |{}           |false,		                     |
  |sequenceId:                |{}           |null,		                     |
  |roomSettings:              |{struct}     |{see below},                    |struct with the four  room settings: inherit settings, width, height, persistent. YY does not modify those
  |  >inheritRoomSettings:    |{bool},      |false,                          | I will document later.
  |  >Width:                  |{int},       |1280,                           |width for the room, 
  |  >Height:                 |{int},       |1280,                           |height for the room,
  |  >persistent:             |{bool}       |false,                          |I will document later.
  |viewSettings:              |{struct}     |{see below},                    |struct with the four view settings: inherit settings, enable, clear background, clear display buffer. YY does not modify those
  |  >inheritViewSettings:    |{bool},      |false,                          |enable the inheritance of this Views settings independently of the rest of the room settings.
  |  >enableViews:            |{bool},      |false,                          |enable camera views in the room.
  |  >clearViewBackground:    |{bool},      |false,	                         |I will document later.
  |  >clearDisplayBuffer:     |{bool},      |true,                           |enable pre-filling of the display buffer before drawing anything else.
  |physicsSettings:           |{struct}     |{see below},                    |struct with the five physics settings: inherit settings, physics, GravityX, GravityY, PixToMetres
  |  >inheritPhysicsSettings: |{bool},      |false,                          |enable the inheritance of this Physics settings independently of the rest of the room settings.
  |  >PhysicsWorld:           |{bool},      |false,                          |enable Physics for the room.
  |  >PhysicsWorldGravityX:   |{real},      |0.0,                            |the x component of the gravity vector for the room.
  |  >PhysicsWorldGravityY:   |{real},      |10.0,                           |the y component of the gravity vector for the room.
  |  >PhysicsWorldPixToMetres:|{real},      |0.1,                            |the ratio of pixels on screen to metres in the real world for the room. A ratio of 32:1 will be specified as 1/32 (or 0.03125)
  |parent:                    |{struct},    |{see below},                    |a struct with two attributes (name, path) pointing to the folder resource (Group from Game MAker IDE)? I do not use this.	
  |  >name:                   |{string},    |Ex: "MyGroup",                  |name of the folder resource as it appears in your Game Maker project.
  |  >path:                   |{file path}, |Ex: folders/MyGroup/MyGroup.yy",|path to the folder resource. Path is relative to the Game Maker project directory.
  |tags:                      |{array},     |Ex: []                          |I think this is the list of tags defined for the object. YY does not modify this.


## Layer json
I haven't documented the layer's json.  
A layer json is stored within the layers array of the room json.  
Layer json have variations depending on their type.  
The most important part of the layer json is the instances array for instance layer, the tiles array fot the tile layer, the assets array for assets layer. Those arrays hold the data for all assets populating the layer


## Instance json
I haven't documented the instance's json.  
An instance json is stored within the instances array of the layer json.  
A key part of the instance json deals with property stored in both Properties array (using [Property json format](#prop)) and the OverriddenProperties array (using [Overriden Property json format](#over)).

## Tiles data
Tiles data is stored within the Tiles array of the room json.  
YY uses the serialized format for tiles data. This is just the list of all tiles data one after another (considering tile index and mirroring).  
Game Maker 2.3 introduced a new format which is the compressed format which is more complex to encode. Game Maker will automaticaly translates tiles data frop the serialized format to the compressed format so that we can just lazily parse data using the serialized formating.  
Please note that if you change a tile layer in a project currently opened in Game Mzker IDE, you will need to close and reopen the room for your changes to be reflected in the room editor.


## Object .yy file / json
properties array and overriddenProperties arrays are the most important attributes for YY library.

  |Attribute             |Type         |Value (= or example)	        |Definition/Note
  |---                   |---          |---                             |---
  |resourceType:         |{string},    |= "GMObject",                   |the type that you will find in all Game Maker resources.
  |resourceVersion:      |{float},     |= "1.0",                        |the formating version. 1.0 seems to always work even if I saw some resources with 1.1.
  |name:                 |{string},    |Ex: "oBackground",              |the name of the resource as it appears in your Game Maker project.
  |spriteId:             |{struct},    |{see below},                    |a struct with two attributes (name, path) pointing to the sprite resource associated to this object.	
  |  >name:              |{string},    |Ex: "sSPR",                     |the name of the sprite resource as it appears in your Game Maker project.
  |  >path:              |{file path}, |Ex: sprites/sSPR/sSPR.yy",      |the path to the sprite resource. Path is relative to the Game Maker project directory.
  |solid:                |{bool},      |Ex: false                       |is the object solid, as defined by Game Maker Object Editor. YY does not modify this
  |visible:              |{bool},      |Ex: false                       |is the object visible, as defined by Game Maker Object Editor. YY does not modify this
  |persistent:           |{bool},      |Ex: true                        |is the object persistent, as defined by Game Maker Object Editor. YY does not modify this
  |managed:              |{bool},      |Ex: false                       |I don't know what this is. YY does not modify this.
  |spriteMaskId:         |{int?}       |Ex: null                        |I guess it has to do with collision masj. YY does not modify this.
  |physicsObject:        |{bool},      |Ex: false                       |value of the associated physic attribute, YY does not modify this.
  |physicsSensor:        |{bool},      |Ex: false                       |value of the associated physic attribute, YY does not modify this.
  |physicsShape:         |{int?},      |Ex: 1                           |value of the associated physic attribute, YY does not modify this.
  |physicsGroup:         |{int?},      |Ex: 0                           |value of the associated physic attribute, YY does not modify this.
  |physicsDensity:       |{real},      |Ex: 0.5                         |value of the associated physic attribute, YY does not modify this.
  |physicsRestitution:   |{real},      |Ex: 0.1                         |value of the associated physic attribute, YY does not modify this.
  |physicsLinearDamping: |{real},      |Ex: 0.1                         |value of the associated physic attribute, YY does not modify this.
  |physicsAngularDamping:|{real},      |Ex: 0.1                         |value of the associated physic attribute, YY does not modify this.
  |physicsFriction:      |{real},      |Ex: 0.2                         |value of the associated physic attribute, YY does not modify this.
  |physicsStartAwake:    |{bool},      |Ex: true                        |value of the associated physic attribute, YY does not modify this.
  |physicsKinematic:     |{bool},      |Ex: false                       |value of the associated physic attribute, YY does not modify this.
  |physicsShapePoints:   |{array},     |Ex: []                          |value of the associated physic attribute, YY does not modify this.
  |eventList:            |{array},     |Ex: []                          |list of events defined in Game Maker. Each defined as a struct. YY does not modify this.
  |properties:           |{array}      |Ex: []                          |array of overriden properties (see format below // Property json)
  |overriddenProperties: |{array}      |Ex: []                          |array of  properties (see format below // Overridden properties json)
  |parent:               |{struct},    |{see below},                    |a struct with two attributes (name, path) pointing to the folder resource (Group from Game MAker IDE)? I do not use this.	
  |  >name:              |{string},    |Ex: "MyGroup",                  |name of the folder resource as it appears in your Game Maker project.
  |  >path:              |{file path}, |Ex: folders/MyGroup/MyGroup.yy",|path to the folder resource. Path is relative to the Game Maker project directory.
  |tags:                 |{array},     |Ex: []                          |I think this is the list of tags defined for the object. YY does not modify this.

## <a name="prop">Property json</a>
A property is a variable from the [Variables Definitions] section of the Object Editor. 
Property json appear in object files and within instances data in room files.
Properties need to use the proper category in object files (Property or overriddenProperty) and to reference the proper object (where it is defined)
'classic' Properties are those just defined in the current object and not in its parents/ancestors. They appear in the object file using the Property type and reference the current object.

The struct is mainly flat with two nested structs
  |Attribute             |Type         | Value (= or example)	        | Definition/Note
  |---                   |---          | ---                            | ---
  |name                  |             |                                | name of the property
  |value                 |             |                                | default value of the property
  |type                  |{int}        |                                | value defining the type o variable
  |rangeMin		 |             |                                | 
  |rangeMax		 |	       |                                | 
  |rangeEnabled          |{bool},      |                                | 
  |propertyId		 |	       |                                | 
  |objectId		 |	       |                                | 

## <a name="over">Overriden Property json</a>
A property is a variable from the [Variables Definitions] section of the Object Editor.   
Property json appear in object files and within instances data in room files.  
Properties need to use the proper category in object files (Property or overriddenProperty) and to reference the proper object (where it is defined). 
Overridden properties are those inherited from parents/ancestors but modified for the current object. They appear in the object file using the overriddenProperty type and reference the ??? and in instance.
  The struct is mainly flat with two nested structs
  |Attribute             |Type         | Value (= or example)	        | Definition/Note
  |---                   |---          | ---                            | ---
  name 			         |			   | empty (name is ins propertyId) | 
  value			         |			   |                                | 
  propertyId			 |			   |                                | 
  objectId			     |			   |                                | 

Please note, fully inherited properties (= those not modified in the object and are fully inherited from parents/ancestors) do not appear in the object file. When defined in an instance they reference the exact parent where they come from.


// Views
_____
inherit: false,
visible: false,
xview: 0, x coordinate for the view.
yview: 0, y coordinate for the view.
wview: 320, width for the view.
hview: 160, height for the view.
xport: 0, x coordinate for the view port.
yport: 0, y coordinate for the view port.
wport: 1280, width for the view port.
hport: 640, height for the view port.
hborder: 0, Horizontal Border of the "buffer" zone for Object Following feature.
vborder: 0, Vertical Border of the "buffer" zone for Object Following feature.
hspeed: -1, horizontal speed of the camera for Object Following feature.
vspeed: -1, vertical speed of the camera for Object Following feature.  
objectId: null, follower object for the camera Object Following feature.

*/
#endregion

/*old stuff
	static get_property_parent = function(_property_name) 	{
		var _parent_struct = get_parent_struct();
		if (_parent_struct == undefined) return undefined;
		// check parent's property
		var _array = _parent_struct.get_properties();
		var _i = array_length(_array);
		repeat(_i)
		{
			--_i;
			if _array[_i].name = _property_name 
			{
				return _parent_struct.get_name();
				exit;
			}
		}
		// check parent's parent
		return _parent_struct.get_property_parent(_property_name);		
	}