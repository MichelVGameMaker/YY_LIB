/*Welcome to L2G LDtk Fied Importer
Import yout LDtk congiguration into your Game Maker project.

L2G started as a demo for YY library but is becoming a proper LDtk importer.

This script allow to import all fields defined in LDtk into your Game Maker object configuration, creating all properties in the associated objects for you (properties = variables from the [Variables Definitions] section of Object Editor)
L2G entry point is the function  L2G_import_all_ld_entities_fields_defs_2_gm_yy_objects() that you pass the EntityDefinition data from LDtk and the targeted Game Maker project directory/
The two other methods are 'atomic' functions to make the whole things more readable. The last one is simple rwrapper in case you do not know how to extract EntityDefinition data from the LDtk json.
*/


/// @function					L2G_import_all_ld_entities_fields_defs_2_gm_yy_objects(entities_defs, clear_before_import, override_existing_field)
/// @description				Process the entities definitions passed from LDtk to update the matching GameMaker object .yy files so that they include fields as defined in LDtk. Object file needs to exist and will not be created.
/// @param {Array}				entities_defs			The full array entities definitions from ldtk file for all objects/entities.
/// @param {Array}				gm_project_directory	The Game Maker project directory.
/// @param {Bool}				clear_before_import		Start by clearing current .yy objects' properties, so that the objects will have exactly the fields defined in LDtk (not less, not more, and the latest version).
/// @param {Bool}				override_existing_field	For property that already exist in Game Maker, True will overridde from LDtk / False will preserve Game Maker configuration. This is useless if clear_before_import is true.
function L2G_import_all_ld_entities_fields_defs_2_gm_yy_objects(_entities_defs, _gm_project_directory, _clear_before_import = false, _override_existing_field = true)
{
	var _entities_defs_number = array_length(_entities_defs);
	var _i = 0;
	repeat(_entities_defs_number)
	{
		// Get the name of the Entity described in the current Definition (_i)
		var entity_name = _entities_defs[_i].identifier;
		// Translated LDtk Entity name to Game Maker Object name (if user has defined a mapping)
		var _obj_name = __LDtkMappingGetEntity(entity_name, _gm_project_directory);
		show_debug_message("[L2G] log: Importing fields to object " + string(_obj_name) + "...");	
		var _yy_obj_construct = new yy_object(_gm_project_directory, _obj_name);
		// Exception : object does not exist
		if _yy_obj_construct.is_set() == false 
		{
			show_debug_message("[L2G] warning: Object data cannot be loaded for " + + string(_obj_name) +  " object, this would come from a path error.");
			_i++
			continue
		}
		// Exception : object has duplicated property/ties
		if _yy_obj_construct.exists_duplicated_properties() 
		{
			show_debug_message("[L2G] error: The above duplicated properties exist in your " + _yy_obj_construct.get_name() + " object. YY library will not modify this object. \n" +
			" If you want more details, please search this string: DUPLICATE_PROPETRY in YY library code (for instance using 'ctrl+shft+F).");
			_i++;
			continue;
		}
		// Parse the Fields Definitions described in the current Definition (_i) and update the data for the associated Game Maker object. 
		var _fields_definitions = _entities_defs[_i].fieldDefs
		var _ok = L2G_import_ld_entity_fields_2_gm_yy_object_props( _yy_obj_construct, _fields_definitions, _clear_before_import, _override_existing_field, true)
		if _ok 
		{
			show_debug_message("[L2G] log: Some fields were imported.");	
			_yy_obj_construct.save_to_directory()
		}
		else
		{
			show_debug_message("[L2G] log: No fields were imported.");	
		}
		_i++;
	}
}

/// function					L2G_import_ld_entity_fields_2_gm_yy_object_props(yy_obj_struct, fields_definitions)
/// @description				Update update the data for the associated Game Maker object by importing all fields parsed from LDtk fields definitions. 
/// @param {Struct}				yy_obj_struct			The full struct, parsed from the GameMaker object using yy_object constructor.
/// @param {Array}				fields_definitions		The struct with fields definitions, retrieved from LDtk file, for the targeted object/entity.
/// @param {Bool}				clear_before_import		Start by clearing current .yy object's properties, so that the object will have exactly the fields defined in LDtk (not less, not more, and the latest version).
/// @param {Bool}				override_existing_field	For property that already exist in Game Maker, True will overridde from LDtk / False will preserve Game Maker configuration. This is useless if clear_before_import is true.
/// @param {Bool}				verbose					True will log properties names to Game Maker console with show_debug_message().
/// @return {Bool}	if the function added at least one property to the object .yy GameMaker data.
L2G_import_ld_entity_fields_2_gm_yy_object_props = function (_yy_obj_struct, _fields_definitions, _clear_before_import = false, _override_existing_field = true, _verbose = false)
{
	var _fields_defs_number = array_length(_fields_definitions);
	if _fields_defs_number == 0 return false
	if _clear_before_import _yy_obj_struct.clear_properties();
	var _i = 0, _added_one_prop = false, _log = "";
	repeat(_fields_defs_number)
	{
		var _new_property = L2G_convert_ld_field_2_gm_yy_prop(_fields_definitions[_i]);
		_yy_obj_struct.add_property(_new_property, _override_existing_field);
		_log += _fields_definitions[_i].identifier + ", ";
		_added_one_prop = true;
		_i++;
	}
	if _verbose and _added_one_prop show_debug_message("[L2G] log: adding the following property/ties to " + _yy_obj_struct.get_name() + " object: " + _log);
	return _added_one_prop;
}

/// function					L2G_convert_ld_field_2_gm_yy_prop(field_struct)
/// @description				Create and return a property struct translated from the passed LDtk field into the proper Game Maker syntax.
/// @param {Struct}				field_struct			The struct for a specific LDtk field.
/// @return {Struct}			The property struct in Game Maker syntax.
L2G_convert_ld_field_2_gm_yy_prop = function(_field_struct)
{
	with(_field_struct)
	{
		var _name     = string(identifier);
		var _rangeMin = variable_struct_get(self, "min");
		var _rangeMax = variable_struct_get(self, "max"); // min and max are GM function
		if ( _rangeMin == undefined or _rangeMin == pointer_null or _rangeMax == undefined or _rangeMax == pointer_null ) 
		{
			var _rangeEnabled = false;
			_rangeMin = 0;
			_rangeMax = 0;		
		}
		else   	var _rangeEnabled = true;
		if defaultOverride != undefined and defaultOverride != pointer_null
		{
			var _value = defaultOverride.params[0]; 	
		}
		else var _value = undefined;						
		if  ( isArray )
		{
		     var _varType = YY_varType.Expression;
		}
		else
		{
			switch(__type)
			{
				case "Float" :
					var _varType = YY_varType.Real;
					if _value == undefined _value = 0;
					break;
				case "Int":
					var _varType = YY_varType.Integer;
					if _value == undefined _value = 0;
					break;
				case "Multilines":
				case "String":
					var _varType = YY_varType.String;
					if _value == undefined _value = "";
					break;
				case "Bool":
					var _varType = YY_varType.Boolean;
					if _value == undefined _value = 0;
					break;
				case "Color":
					var _varType = YY_varType.Colour;
					if _value == undefined _value = 0;
					break;
				case "EntityRef":
					var _varType = YY_varType.Expression
					if _value == undefined _value = "";
					break;
				case "Point":
					var _varType = YY_varType.Expression;
					if _value == undefined _value = "";
					break;
				default:
					if ( string_pos("LocalEnum", __type) )	var _varType = YY_varType.Integer;
					else                                    var _varType = YY_varType.String;
					if _value == undefined _value = "";
					break;
			}
		}
	}
	return {
		resourceType:    "GMObjectProperty",
		resourceVersion: "1.0",
		name:            _name,
		varType:         _varType,
		value:           _value,
		rangeEnabled:    _rangeEnabled,
		rangeMin:        _rangeMin,
		rangeMax:        _rangeMax,
		listItems:       [],
		multiselect:     false,
		filters:         [],
	};
}

/// @description				Simple wrapper in case you do not know how to extract EntityDefinition data from the LDtk json.
/// @return {Array}				The full array entities definitions from ldtk file for all objects/entities.
function L2G_get_ld_entities_fields(_ldtk_file)
{
	var _data = SnapFromJSON(SnapStringFromFile(_ldtk_file));
	return _data.defs.entities;
}