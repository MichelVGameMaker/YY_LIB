__yy_test = function(_string, _expected, _test, _pre_test) {
		var _log = "";
		if (_pre_test != undefined)
		{	
			try { _pre_test(); }
			catch( _exception)
			{
				show_debug_message("!!Test Issue!! for " + string(_string) + ": The pre-Test instructions caused an exception, the test is aborted. See message below:\n" +
				                   _exception.message);
				exit;
			}
		}
		try { var _result = _test(); }
		catch( _exception)
		{
			show_debug_message("!!Test Issue!! for " + string(_string) + ": The test instructions caused an exception, the test is aborted. See message below:\n" +
				                _exception.message);
			exit;
		}
		if (_result != _expected) 	
		{
			show_debug_message("!!Test Failed!!:" + string(_string) + ". expected " + string(_expected) + " gave " + string(_result));
		}
		else show_debug_message("Test Passed:" + string(_string));

	}


// yy_room_test_report();
// yy_object_test_report();

function yy_room_test_report(_gm_path = L2G_LDTK_CONFIG.directory) {
	if !directory_exists(_gm_path) 
	{
		_gm_path   = filename_dir(get_open_filename_ext("Project file|*.yyp", "", "", "Select the Game Maker .yy project file running this pro"));
		if (directory_exists(_gm_path))
		{
			
			show_debug_message("[YY] log: Test configuration. Game Maker project directory is set to [" + string(_gm_path) + "].");
		}	
		else if (_gm_path = "")
		{
			show_debug_message("[YY] Error: Test configuration. User aborted the selection of Game Maker project directory. Tests will not run.");
			exit;
		}
		else
		{
			show_debug_message("[YY] Error: Test configuration. Directory selected by used is invalid or does not exist. Please check You have 'Disable System Sandbox'.");
			exit;
		}
	}	

	// Parenting test Obj1 isparentto Obj2 isparento Obj3
	_room = new yy_room(_gm_path, "YY_TEST_room"); // lazy variable
	__yy_test("_room.get_width()",  400,  function() { return _room.get_width() },  function() {  _room.set_width(400) });
	__yy_test("_room.get_height()",  200,  function() { return _room.get_height() },  function() {  _room.set_height(200) });
	__yy_test("_room.set_width(800)",  800,  function() { return _room.get_width() },  function() {  _room.set_width(800) });
	__yy_test("_room.set_height(400)",  400,  function() { return _room.get_height() },  function() {  _room.set_height(400) });
	__yy_test("_room.instance_layer_create('layer_1', 050)", 1, function() { return is_struct(_room.get_layer("layer_1")) }, function() { _room.instance_layer_create("layer_1", 050); });
	__yy_test("_room.instance_layer_create('layer_2', 100)", 100, function() { return _room.get_layer("layer_2").depth }, function() { _room.instance_layer_create("layer_2", 100); });
	__yy_test("_room.instance_layer_create('layer_2', 200)", 200, function() { return _room.get_layer("layer_2").depth }, function() { _room.instance_layer_create("layer_2", 200); });
	__yy_test("_room.instance_layer_create('layer_2', 300,.., false)", 200, function() { return _room.get_layer("layer_2").depth }, function() { _room.instance_layer_create("layer_2", 300, undefined, undefined, false); });
	__yy_test("_room.asset_layer_create('layer_2', 225)", 225, function() { return _room.get_layer("layer_2").depth }, function() { _room.asset_layer_create("layer_2", 225); });
	__yy_test("_room.asset_layer_create('layer_2', 325,.., false)", 225, function() { return _room.get_layer("layer_2").depth }, function() { _room.asset_layer_create("layer_2", 325, undefined, undefined, false); });
	__yy_test("_room.background_layer_create('layer_2', 250)", 250, function() { return _room.get_layer("layer_2").depth }, function() { _room.background_layer_create("layer_2", 250); });
	__yy_test("_room.background_layer_create('layer_2', 350,.., false)", 250, function() { return _room.get_layer("layer_2").depth }, function() { _room.background_layer_create("layer_2", 350, undefined, undefined, undefined, false); });
	__yy_test("_room.tile_layer_create('layer_2', 275)", 275, function() { return _room.get_layer("layer_2").depth }, function() { _room.tile_layer_create("layer_2", 275); });
	__yy_test("_room.tile_layer_create('layer_2', 375,.., false)", 275, function() { return _room.get_layer("layer_2").depth }, function() { _room.tile_layer_create("layer_2", 375, undefined, undefined, undefined, false); });
	__yy_test("_room.asset_layer_create('layer_3', 050)", 050, function() { return _room.get_layer("layer_3").depth }, function() { _room.asset_layer_create("layer_3", 050); });


	var _inst = _room.instance_create(0, 0, _room.get_layer("layer_1"), "YY_TEST_object3");
	_room.instance_set_property(_inst, "variable_name1a", 10);
	_room.instance_set_property(_inst, "variable_name1b", 10);
	_room.instance_set_property(_inst, "variable_name1c", 10);
	_room.instance_set_property(_inst, "variable_name2b", 20);
	_room.instance_set_property(_inst, "variable_name2c", 20);
	_room.instance_set_property(_inst, "variable_name3",  30);
	_room.instance_set_property(_inst, "variable_wrong",  30);
	var _inst2 = _room.instance_create(50, 50, _room.get_layer("layer_1"), "YY_TEST_object3",
		{
			variable_name1a: 10,
			variable_name1b: 10,
			variable_name1c: 10,
			variable_name2b: 20,
			variable_name2c: 20,
			variable_name3:  30,
			variable_wrong:  30,
		});
	_room.save_to_directory();
 
}
function yy_object_test_report(_gm_path = L2G_LDTK_CONFIG.directory) {
	if !directory_exists(_gm_path) 
	{
		_gm_path   = filename_dir(get_open_filename_ext("Project file|*.yyp", "", "", "Select the Game Maker .yy project file running this pro"));
		if (directory_exists(_gm_path))
		{
			
			show_debug_message("[YY] log: Test configuration. Game Maker project directory is set to [" + string(_gm_path) + "].");
		}	
		else if (_gm_path = "")
		{
			show_debug_message("[YY] Error: Test configuration. User aborted the selection of Game Maker project directory. Tests will not run.");
			exit;
		}
		else
		{
			show_debug_message("[YY] Error: Test configuration. Directory selected by used is invalid or does not exist. Please check You have 'Disable System Sandbox'.");
			exit;
		}
	}		
	
	// Parenting test Obj1 isparentto Obj2 isparento Obj3
	_obj1 = new yy_object(_gm_path, "YY_TEST_object1"); // Those are lazy variables
	_obj2 = new yy_object(_gm_path, "YY_TEST_object2");
	_obj3 = new yy_object(_gm_path, "YY_TEST_object3");
	_obj4 = new yy_object(_gm_path, "YY_TEST_object4");

	
	// exists_duplicated_properties - Check for property duplicates
	__yy_test("_obj1.exists_duplicated_properties(): shld_be 0:", 0, function() { return _obj1.exists_duplicated_properties() });
	__yy_test("_obj4.exists_duplicated_properties(): shld_be 1:", 1, function() { return _obj4.exists_duplicated_properties() });
	// get_property() - Get property struct")
	show_debug_message(">>> get_property() - Get property struct");
	__yy_test("_obj3.get_property('variable_name1b'): shld_be undefined:",            undefined,              function() { return _obj3.get_property("variable_name1b") });
	__yy_test("_obj3.get_property('variable_name1c'): shld_be GMOverriddenProperty:", "GMOverriddenProperty", function() { return _obj3.get_property("variable_name1c").resourceType });
	__yy_test("_obj3.get_property('variable_name2c'): shld_be GMOverriddenProperty:", "GMOverriddenProperty",     function() { return _obj3.get_property("variable_name2c").resourceType });
	__yy_test("_obj3.get_property('variable_name3'):  shld_be GMObjectProperty:",     "GMObjectProperty",     function() { return _obj3.get_property("variable_name3").resourceType });
	__yy_test("_obj3.get_property('variable_name1c', false): shld_be undefined:",     undefined,              function() { return _obj3.get_property("variable_name1c", false) });
	__yy_test("_obj3.get_property('variable_name2c', false): shld_be undefined:",     undefined,              function() { return _obj3.get_property("variable_name2c", false) });
	__yy_test("_obj3.get_property('variable_name3'):  shld_be GMObjectProperty:",     "GMObjectProperty",     function() { return _obj3.get_property("variable_name3", false).resourceType });
	__yy_test("_obj3.get_property('variable_name3'):  shld_be 3:",                    3,              function() { return _obj3.get_property("variable_name3", false).value });
	__yy_test("_obj3.get_property('variable_name3', false).value = 33:  shld_be 33:",                    33,  function() { return _obj3.get_property("variable_name3", false).value }, function() { _obj3.get_property("variable_name3", false).value = 33 });
	__yy_test("_obj3.property_is_overriden(_obj3.get_property('variable_name1c')): shld_be 1:", 1,            function() { return _obj3.property_is_overriden(_obj3.get_property("variable_name1c")) });
	// exists_property() - Check property exists, in object AND PARENT
	show_debug_message(">>> exists_property() - Check property exists, in object AND PARENT");
	__yy_test("_obj1.exists_property('variable_name1a', true): shld_be 1:", 1, function() { return _obj1.exists_property("variable_name1a", true) });
	__yy_test("_obj1.exists_property('variable_name1b', true): shld_be 1:", 1, function() { return _obj1.exists_property("variable_name1b", true) });
	__yy_test("_obj1.exists_property('variable_name1c', true): shld_be 1:", 1, function() { return _obj2.exists_property("variable_name1c", true) });
	__yy_test("_obj2.exists_property('variable_name1a', true): shld_be 1:", 1, function() { return _obj2.exists_property("variable_name1a", true) });
	__yy_test("_obj2.exists_property('variable_name1b', true): shld_be 1:", 1, function() { return _obj2.exists_property("variable_name1b", true) });
	__yy_test("_obj2.exists_property('variable_name1c', true): shld_be 1:", 1, function() { return _obj2.exists_property("variable_name1c", true) });
	__yy_test("_obj2.exists_property('variable_name2b', true): shld_be 1:", 1, function() { return _obj2.exists_property("variable_name2b", true) });
	__yy_test("_obj2.exists_property('variable_name2c', true): shld_be 1:", 1, function() { return _obj2.exists_property("variable_name2c", true) });
	__yy_test("_obj3.exists_property('variable_name1a', true): shld_be 1:", 1, function() { return _obj3.exists_property("variable_name1a", true) });
	__yy_test("_obj3.exists_property('variable_name1b', true): shld_be 1:", 1, function() { return _obj3.exists_property("variable_name1b", true) });
	__yy_test("_obj3.exists_property('variable_name1c', true): shld_be 1:", 1, function() { return _obj3.exists_property("variable_name1c", true) });
	__yy_test("_obj3.exists_property('variable_name2b', true): shld_be 1:", 1, function() { return _obj3.exists_property("variable_name2b", true) });
	__yy_test("_obj3.exists_property('variable_name2c', true): shld_be 1:", 1, function() { return _obj3.exists_property("variable_name2c", true) });
	__yy_test("_obj3.exists_property('variable_name3',  true): shld_be 1:", 1, function() { return _obj3.exists_property("variable_name3",  true) });
	// exists_property() - Check property exists, in object BUT NOT IN PARENT
	show_debug_message(">>> exists_property() - Check property exists, in object BUT NOT IN PARENT");
	__yy_test("_obj1.exists_property('variable_name1a', false): shld_be 1:", 1, function() { return _obj1.exists_property("variable_name1a", false) });
	__yy_test("_obj1.exists_property('variable_name1b', false): shld_be 1:", 1, function() { return _obj1.exists_property("variable_name1b", false) });
	__yy_test("_obj1.exists_property('variable_name1c', false): shld_be 1:", 1, function() { return _obj1.exists_property("variable_name1c", false) });
	__yy_test("_obj2.exists_property('variable_name1a', false): shld_be 0:", 0, function() { return _obj2.exists_property("variable_name1a", false) });
	__yy_test("_obj2.exists_property('variable_name1b', false): shld_be 0:", 0, function() { return _obj2.exists_property("variable_name1b", false) });
	__yy_test("_obj2.exists_property('variable_name1c', false): shld_be 0:", 0, function() { return _obj2.exists_property("variable_name1c", false) });
	__yy_test("_obj2.exists_property('variable_name2b', false): shld_be 1:", 1, function() { return _obj2.exists_property("variable_name2b", false) });
	__yy_test("_obj2.exists_property('variable_name2c', false): shld_be 1:", 1, function() { return _obj2.exists_property("variable_name2c", false) });
	__yy_test("_obj3.exists_property('variable_name1a', false): shld_be 0:", 0, function() { return _obj3.exists_property("variable_name1a", false) });
	__yy_test("_obj3.exists_property('variable_name1b', false): shld_be 0:", 0, function() { return _obj3.exists_property("variable_name1b", false) });
	__yy_test("_obj3.exists_property('variable_name1c', false): shld_be 0:", 0, function() { return _obj3.exists_property("variable_name1c", false) });
	__yy_test("_obj3.exists_property('variable_name2b', false): shld_be 0:", 0, function() { return _obj3.exists_property("variable_name2b", false) });
	__yy_test("_obj3.exists_property('variable_name2c', false): shld_be 0:", 0, function() { return _obj3.exists_property("variable_name2c", false) });
	__yy_test("_obj3.exists_property('variable_name3',  false): shld_be 1:", 1, function() { return _obj3.exists_property("variable_name3",  false) });
	// get_property_owner() - Get where property was defined
	show_debug_message(">>> get_property_owner() - Get where property was defined");
	__yy_test("_obj1.get_property_owner('variable_name1a'): shld_be YY_TEST_object1:", "YY_TEST_object1", function() { return _obj1.get_property_owner("variable_name1a") });
	__yy_test("_obj1.get_property_owner('variable_name1b'): shld_be YY_TEST_object1:", "YY_TEST_object1", function() { return _obj1.get_property_owner("variable_name1b") });
	__yy_test("_obj1.get_property_owner('variable_name1c'): shld_be YY_TEST_object1:", "YY_TEST_object1", function() { return _obj1.get_property_owner("variable_name1c") });
	__yy_test("_obj2.get_property_owner('variable_name1a'): shld_be YY_TEST_object1:", "YY_TEST_object1", function() { return _obj2.get_property_owner("variable_name1a") });
	__yy_test("_obj2.get_property_owner('variable_name1b'): shld_be YY_TEST_object1:", "YY_TEST_object1", function() { return _obj2.get_property_owner("variable_name1b") });
	__yy_test("_obj2.get_property_owner('variable_name1c'): shld_be YY_TEST_object1:", "YY_TEST_object1", function() { return _obj2.get_property_owner("variable_name1c") });
	__yy_test("_obj2.get_property_owner('variable_name2b'): shld_be YY_TEST_object2:", "YY_TEST_object2", function() { return _obj2.get_property_owner("variable_name2b") });
	__yy_test("_obj2.get_property_owner('variable_name2c'): shld_be YY_TEST_object2:", "YY_TEST_object2", function() { return _obj2.get_property_owner("variable_name2c") });
	__yy_test("_obj3.get_property_owner('variable_name1a'): shld_be YY_TEST_object1:", "YY_TEST_object1", function() { return _obj3.get_property_owner("variable_name1a") });
	__yy_test("_obj3.get_property_owner('variable_name1b'): shld_be YY_TEST_object1:", "YY_TEST_object1", function() { return _obj3.get_property_owner("variable_name1b") });
	__yy_test("_obj3.get_property_owner('variable_name1c'): shld_be YY_TEST_object1:", "YY_TEST_object1", function() { return _obj3.get_property_owner("variable_name1c") });
	__yy_test("_obj3.get_property_owner('variable_name2b'): shld_be YY_TEST_object2:", "YY_TEST_object2", function() { return _obj3.get_property_owner("variable_name2b") });
	__yy_test("_obj3.get_property_owner('variable_name2c'): shld_be yy_overriden_property:", "YY_TEST_object2", function() { return _obj3.get_property_owner("variable_name2c") });
	__yy_test("_obj3.get_property_owner('variable_name3',): shld_be YY_TEST_object3:", "YY_TEST_object3", function() { return _obj3.get_property_owner("variable_name3",) });
	// get_x() - various getters
	show_debug_message(">>> get_x() - various getters");
	__yy_test("_obj2.get_name(): shld_be 'YY_TEST_object2':", "YY_TEST_object2", function() { return _obj2.get_name() });
	__yy_test("_obj2.get_parent_name(): shld_be 'YY_TEST_object1':", "YY_TEST_object1", function() { return _obj2.get_parent_name() });
	__yy_test("_obj2.get_parent_struct(): shld_be struct:", "YY_TEST_object1", function() { return _obj2.get_parent_struct().get_name() });
	__yy_test("_obj3.get_properties(): shld_be 1 :", 1, function() { return array_length(_obj3.get_properties()) });
	__yy_test("_obj3.get_overridden_properties(): shld_be 2 :", 2, function() { return array_length(_obj3.get_overridden_properties()) });
	// internal add_property: __add_classic_property() and __add_inherited_property()
	show_debug_message(">>> internal add_property: __add_classic_property() and __add_inherited_property()");
	__yy_test("_obj3._add_classic_property('variable_name3'): shld_be 1 :", 1, function() { return array_length(_obj3.get_properties())}, function() {_obj3.__add_classic_property(yy_property("variable_name3", 4, 4), false) });
	__yy_test("_obj3._add_classic_property('variable_name3b'): shld_be 2 :", 2, function() { return array_length(_obj3.get_properties())}, function() {_obj3.__add_classic_property(yy_property("variable_name3b", 4, 4)) });
	__yy_test("_obj3.__add_inherited_property('variable_name1c'): shld_be 2 :", 2, function() { return array_length(_obj3.get_overridden_properties())}, function() {_obj3.__add_inherited_property(yy_overriden_property("variable_name1c", 4, "YY_TEST_object1"), false) });
	__yy_test("_obj3.__add_inherited_property('variable_name2c'): shld_be 2 :", 2, function() { return array_length(_obj3.get_overridden_properties())}, function() {_obj3.__add_inherited_property(yy_overriden_property("variable_name2c", 4, "YY_TEST_object2")) });
	__yy_test("_obj3.__add_inherited_property('variable_name2b'): shld_be 3 :", 3, function() { return array_length(_obj3.get_overridden_properties())}, function() {_obj3.__add_inherited_property(yy_overriden_property("variable_name2b", 4, "YY_TEST_object2")) });
	// internal add_property: __add_classic_property() and __add_inherited_property()
	show_debug_message(">>> add_property() ");
	__yy_test("_obj3.add_property('variable_name1a'): shld_be 4 :", 4, function() { return array_length(_obj3.get_overridden_properties())}, function() {_obj3.add_property(yy_property("variable_name1a", 5, 5)) });
	__yy_test("_obj3.add_property('variable_name1a'): shld_be 4 :", 4, function() { return array_length(_obj3.get_overridden_properties())}, function() {_obj3.add_property(yy_property("variable_name1a", 6, 6), false) });
	__yy_test("_obj3.add_property('variable_name1b'): shld_be 5 :", 5, function() { return array_length(_obj3.get_overridden_properties())}, function() {_obj3.add_property(yy_property("variable_name1b", 5, 5)) });
	__yy_test("_obj3.add_property('variable_name1c'): shld_be 5 :", 5, function() { return array_length(_obj3.get_overridden_properties())}, function() {_obj3.add_property(yy_property("variable_name1c", 5, 5)) });
	__yy_test("_obj3.add_property('variable_name3b'): shld_be 2 :", 2, function() { return array_length(_obj3.get_properties())},           function() {_obj3.add_property(yy_property("variable_name3b", 5, 5)) });
	__yy_test("_obj3.add_property('variable_name3c'): shld_be 3 :", 3, function() { return array_length(_obj3.get_properties())},           function() {_obj3.add_property(yy_property("variable_name3c", 5, 5)) });
	// set_properties and clear_properties()
	show_debug_message(">>> set_properties and clear_properties()");
	__yy_test("_obj3.clear_properties(): shld_be []:", 0, function() { return array_length(_obj3.get_properties()) }, function() { _obj3.clear_properties(); });
	__yy_test("_obj3.set_properties(): shld_be ['test']:", "test", function() { return  _obj3.get_properties()[0] }, function() { _obj3.set_properties(["test"]); });
	__yy_test("_obj3.clear_overridden_properties(): shld_be []:", 0, function() { return  array_length(_obj3.get_overridden_properties()) }, function() { _obj3.clear_overridden_properties();  });
	__yy_test("_obj3.set_overridden_properties(): shld_be ['test']:", "test", function() { return  _obj3.get_properties()[0] }, function() { _obj3.set_overridden_properties(["test"]); });
	
}