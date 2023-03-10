// harcoded types and names for assets
#macro L2G_asset_types    [asset_object, asset_sprite, asset_sound, asset_room, asset_tiles, asset_path , asset_script, asset_font, asset_timeline, asset_shader, asset_animationcurve, asset_sequence, asset_unknown]
#macro L2G_asset_names    ["object",     "sprite",     "sound",     "room",     "tileset",   "path",      "script" ,    "font" ,    "timeline" ,    "shader" ,    "animationcurve",     "sequence",     "layer"]
#macro L2G_SCAN_PER_STEP  1000    // this allow to span the scan on multiple steps to avoid any lag
#macro L2G_ITEMS_PER_PAGE 100     // imguigml_list_box has a memory limit (of course), sending hundreds of names might freeze so this allow to split the list in pages 

/// @function L2G_Asset_Selector(type, type_change)
/// @description Constructs a struct that can display the Asset Selector widget.
/// @param [type]			Constant	The type of asset to list in the Asset Selector. It uses Game Maker native constants asset_xx. Note: that you can use asset_unknown for the layer of the current room.
/// @param [type_change]	Boolean		If enabled, the widget will include a combo_list to change the type of asset.
function L2G_Asset_Selector(_type = asset_object, _type_change = false) constructor
{
	// everything is private
	static id_gen = 1;
	__id          = "##L2G_L15T" + string(id_gen++)			// id, to avoid collision in imguigml identifier, in case multiple selectors are created.
	// assets list
	assets        = {};										// struct storing for each asset_name a data set { id: [asset_index], display: [flag instructing to display this asset in the list] }.
	page_names    = [];										// array storing all asset_names in the current page.
	// asset type variable
	asset_type    = asset_object;							// the asset type the selector allows to browse and select. It uses Game Maker native constants.
	asset_code    = 0;										// the asset code, which is the index of the asset_type in the L2G_asset_names array. This is 'manualy' transcoded in set_type() based on asset_type.
	scan_room     = undefined;                              // the room to scan layer, current room if undefined
	type_change   = _type_change;							// boolean, if selector interface displays a combo_list to change the asset type.
	set_type(_type);										// initialize passed _type.
	// list variables
	list_sorting  = true;									// list sorting option currently defined by the user.
	list_filter   = "";										// list filtering criteria currently defined by the user.
	list_index    = 0;										// index of the selected item in the current page. Not in the full list.
	list_page     = 0;										// index of the current page, starting at 0.
	list_pages    = 0;										// total number of pages.
	// scan variables 
	scanned_id    = 0;										// keep track of the current asset_id while scanning. Scanning is "asynchronous" and spans over multiple steps. When >= 0 the scan is ongoing. When = -1 the scan is stopped.
	
	static __start_scan   = function()						// Sets all variables for a scan to be processed (scan = scanning existing assets in current project).
	{
		assets     = {};
		page_names = [];
		scan_start = current_time;
		scanned_id = 0;					// marks scan as ongoing
	}
	static __process_scan = function()						// Process current scan, if one is running (scan = scanning existing assets in current project).
	{
		if scanned_id = -1 exit;  
		switch(asset_type)
		{
			case asset_object :
				var _exists = function(_i) { return object_exists(_i);     };
				var _name   = function(_i) { return object_get_name(_i);   };
				break;
			case asset_sprite :
				var _exists = function(_i) { return sprite_exists(_i);     };
				var _name   = function(_i) { return sprite_get_name(_i);   };
				break;
			case asset_sound  :
				var _exists = function(_i) { return audio_exists(_i);      };
				var _name   = function(_i) { return audio_get_name(_i);    };
				break;
			case asset_room  :
				var _exists = function(_i) { return room_exists(_i);      };
				var _name   = function(_i) { return room_get_name(_i);    };
				break;
			case asset_tiles  : 
				var _exists = function(_i) { return tileset_get_name(_i) != tileset_get_name(-1);   };
				var _name   = function(_i) { return tileset_get_name(_i);  }
				break;
			case asset_path    :
				var _exists = function(_i) { return path_exists(_i);       };
				var _name   = function(_i) { return path_get_name(_i);     };
				break;
			case asset_script  :
				var _exists = function(_i) { return script_exists(_i);     };
				var _name   = function(_i) { return string_replace(script_get_name(_i), "@", "_@_");   };
				break;
			case asset_font	   :
				var _exists = function(_i) { return font_exists(_i);       };
				var _name   = function(_i) { return font_get_name(_i);     };
				break;
			case asset_timeline:
				var _exists = function(_i) { return timeline_exists(_i);   };
				var _name   = function(_i) { return timeline_get_name(_i); };
				break;
			case asset_shader  :
				var _exists = function(_i) { try return ( shader_get_name(_i) != undefined ) catch(_e) return false; };
				var _name   = function(_i) { return shader_get_name(_i);   };
				break;
			case asset_animationcurve:
				var _exists = function(_i) { return animcurve_exists(_i);  };
				var _name   = function(_i) { return animcurve_get(_i).name;};
				break;
			case asset_sequence:
				var _exists = function(_i) { return sequence_exists(_i);   };
				var _name   = function(_i) { return sequence_get(_i).name; };
				break;
			default            :
				var _exists = function(_i) { return false;                 };
				var _name   = function(_i) { return string(_i);            };
				break;
			case asset_unknown: // used for layers
				if scan_room != undefined
				layer_set_target_room(scan_room);
				var _layers = layer_get_all();
				var _i = 0, _len = array_length(_layers), _layer_i, _name_i;
				repeat (_len)
				{
					_layer_i = _layers[_i]
					{
						_name_i = layer_get_name(_layer_i);
						assets[$ _name_i] = { id: _i, display: true, };
					}
					++ _i;      
				}
				list_pages = ceil(_i/L2G_ITEMS_PER_PAGE);	// number of pages
				scanned_id = -1;							// scan is over	
				__update_page();
				layer_reset_target_room();
				exit;
				break;
		}	

		var _i = scanned_id;
		var _name_i; 
		repeat(L2G_SCAN_PER_STEP) 
		{
			if _exists( _i ) 
			{
				_name_i = _name(_i);
				assets[$ _name_i] = { id: _i, display: true, };	
				_i++;
			}
			else
			{
				list_pages = ceil(_i/L2G_ITEMS_PER_PAGE);	// number of pages
				scanned_id = -1;							// scan is over	
				__update_page();
				exit;				
			}
		}
		scanned_id = _i;
	}
	static __update_page   = function()                     // Updates the array storing all asset_names (to be used in imguigml widget), accoding to sorting and filtering rules.
	{
		page_names      = [];
		var _names = variable_struct_get_names(assets);
		array_sort(_names, list_sorting);
		if list_filter == "" 
		{
			array_copy(page_names, 0, _names, list_page * L2G_ITEMS_PER_PAGE, L2G_ITEMS_PER_PAGE);
		}
		else
		{
			var _i = 0, _len = array_length(_names), _name_i, _j = 0;
			repeat (_len)
			{
				_name_i = _names[_i];
				if string_pos(string_upper(list_filter), string_upper(_name_i)) 
				{
					_j++;
					array_push(page_names, _name_i);
					if _j >= L2G_ITEMS_PER_PAGE break
				}
				++_i;      
			}
		}
	}
	static asset_name_exists = function(_asset_name)        // Tests if an asset exists in the Selector, based on its name.
	{
		return assets[$ _asset_name] != undefined;
	}
	static asset_id_exists = function(_asset_id)          // Tests if an asset exists in the Selector, based on its name.
	{
		var _return = false;
		var _names  = variable_struct_get_names(assets);
		var _i = array_length(_names), _name_i;
		repeat(_i)
		{
			_i--;
			if assets[$ _names[ _i]].id == _asset_id return true;
		}
		return _return;
	}
	static set_type = function(_asset_type = asset_object)  // Sets the asset_type for the selector. Scan assets once it is done.
	{
		asset_type = _asset_type;	
		switch(asset_type)	// yes I know
		{
			default            :
			case asset_object  :       asset_code = 0;  break;
			case asset_sprite  :       asset_code = 1;  break;
			case asset_sound   :       asset_code = 2;  break;
			case asset_tiles   :       asset_code = 3;  break;
			case asset_path    :       asset_code = 4;  break;
			case asset_script  :       asset_code = 5;  break;
			case asset_font	   :       asset_code = 6;  break;
			case asset_timeline:       asset_code = 7;  break;
			case asset_shader  :       asset_code = 8;  break;
			case asset_animationcurve: asset_code = 9;  break;
			case asset_sequence:       asset_code = 10; break;
			case asset_unknown :       asset_code = 11; break;
		}
		list_sorting  = true;
		list_filter   = "";
		list_index    = 0;
		list_page     = 0;
		list_pages    = 0;
		__start_scan();
	}
	static set_scan_room = function(_room)  // Sets the scan room. Scan assets if the current asset_type is layer.
	{
		if _room != scan_room 
		{
			scan_room = _room;
			if asset_type =  asset_unknown
			{
				list_sorting  = true;
				list_filter   = "";
				list_index    = 0;
				list_page     = 0;
				list_pages    = 0;
				__start_scan();	
			}
		}
	}
	static set_page       = function(_page = 0)				// Sets the current page for the selector. Refresh the array storing all asset_names once it is done.
	{
		list_page = clamp(_page, 0, list_pages - 1);
		__update_page();
	}
	static set_sort       = function(_ascending = true)		// Sets the sorting option for the selector. Refresh the array storing all asset_names once it is done.
	{
		list_sorting = _ascending;
		__update_page();
	}
	static set_filter     = function(_string)				// Sets the filtering criteria for the selector. Refresh the array storing all asset_names once it is done.
	{
		list_filter = _string;
		__update_page();
	}
	static imguigml_step  = function(_nb_entries)			// Processes scan instructions and imguigml instructions for the widget to be displayed. Intended to be called within your imguigml isntructions like a call to imguigml_list_box().
	{
		var _input, _output; 

		// Process scan if it is not over
		__process_scan();
		// Selector filter and sort
		if imguigml_small_button("Az")                set_sort(true);
		imguigml_same_line();
		if imguigml_small_button("Za")                set_sort(false);
		imguigml_same_line();
		imguigml_push_item_width(imguigml_get_content_region_avail_width());
		_input = imguigml_input_text(__id+"FILTER", list_filter, 20);
		if _input[0]                                  set_filter(string_replace_all(_input[1], " ", ""));
		// Selector list
		var _width = imguigml_get_content_region_avail_width();
		imguigml_push_item_width(_width);
		_output = imguigml_list_box(__id+"BOX", list_index, page_names, _nb_entries);
		// Selector page
		if list_pages > 0
		{
			imguigml_push_item_width(_width / (list_pages + 1) )
			imguigml_text("page:");
			var _p = 0;
			repeat(list_pages)
			{
				imguigml_same_line();
				if  _p = list_page imguigml_text("[" + string(_p) + "]");
				else if imguigml_small_button(string(_p)) set_page(_p);
				_p++
			}
		}
		// Asset type change (option)
		if type_change
		{
			imguigml_push_item_width(0);
			imguigml_text("Asset Type");
			imguigml_same_line();
			_input = imguigml_combo(__id+"TYPE", asset_code, L2G_asset_names);
			if _input[0]
			{
				var _asset_types = L2G_asset_types; // due to the macro being in-line. I need this to access with [i]
				asset_code = _input[1];
				set_type(_asset_types[_input[1]]);
			}
		}
		// Process click
		if _output[0] 
		{
			list_index = _output[1];
			return  [_output[0], assets[$ page_names[list_index]].id, page_names[list_index]];
		}
		else
		{
			return [false, false];
		}
	}
}