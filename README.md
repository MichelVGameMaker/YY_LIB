# YY LIB - Game Maker Files Modifier
YY is a small collection of functions to adjust Game Maker room files and object files within your project directory. It is intended to pair with external level editor to facilitate import into Game Maker project.

## About L2G
### Use case
YY allows to modify Game Maker room files and object files. It is intended to help people work on level editor features for instance to import room data from an external level editor or to replicate in room data modifications done at runtime. 
I tried to keep the syntax close to what you would use in GML so that you can, for example, create an instance in your room file with instance_create().
There is a basic demo with two example of how to parse a room at runtime in room .yy file. The first showcases serializing instances created at runtime. The second showcases serializing tiles that you have created at runtime.
I have another example allowing to import the full configuration for entities from a LDtk file, but it is not documented.

### Features:
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

### License
YY is fully free. Do whatever you want with it.

### Version and Platform
YY is tested on Game Maker LTS and on windows platform.

## Installation
### Importing YY in your project
YY needs to be imported as a local package in your Game Maker project.
-	Download the .yymp file from GITHUB.
-	Import it inside your project. You can do this by dragging the *. yymp file from an explorer window onto the GameMaker IDE or by clicking "Import Local Package" within the Tools Menu. In both case, a window will pop up to define import parameters. Click “add all” and “OK”. 

### Make sure sandboxing is de-activated
This will create a two folders in your Asset Browser labeled “YY - GM Files Modifier” and "SNAP". The code is ready to be used.
Still, if the Game Maker file you want to update is out of Game Maker sandbox repository, which will surely be the case, you need to de-activate sandboxing. You can do so, on the Desktop targets (Windows, macOS, and Ubuntu (Linux)), by checking the “Disable file system sandbox” option in the Game Options for the target platform.

## How to use

### Overall process
YY is not capable of creating files (to avoid having too much impact in your project structure), you will need to recycle existing files already created within Game Maker. 
The typical process runs in three steps: 
-	1.create a yy_class from an existing Game Maker file, this will hold all data from the targeted Game Maker file, 
-	2.update the data accordingly to your need, 
-	3.write back the data to the file.

Example:
// 1.create a yy_room for the current room
var _room = new yy_room(filename_dir(GM_project_filename), room_get_name(room)); 
// 2.update the data
_room.set_width(400); // change room size
_room.instance_layer_create("layer_1", 100) // create a layer in the room at depth 100
var _inst _room.instance_create(0, 0, _room.get_layer("layer_1"), "YY_TEST_object3") // create an instance onto the layer
_room.instance_set_property(_inst, "health", 10) // set a property for the instance (=variables value from the [Variable] section for the instance in the Room Editor).
// 3.write back the data to the file
_room_struct.save_to_directory(); 

## What happens when a Game Maker file is updated
With YY you can update a currently opened project. Indeed, Game Maker IDE is smart enough to detect this change in live and ask you what to do in a warning window. If you click 'Save', YY changes will be deleted, if you click 'Reload', YY changes will be taken into account. 
Please note that, some updates are not imediately visible in Game Maker IDE, notably:
- when modifying object variables from the [Variables Definitions] section of the Object Editor, you will need to close the section and reopen it.
- when modifying tiles for a tile layer, you will need to close the associated room and reopen it.

Documentation is a limited so far. You will have to browse through the methods available in the two classes.

## Behind the hood
YY mainly relies on Juju's SNAP to preserve the json format expected by Game Maker. SNAP offers advanced data parsing features. If you do not know about it, or worse about Juju’s library, you can check them out here: https://github.com/JujuAdams
Other than that, YY is just there to modify data structure accordingly to what Game Maker expects. For instance, it will scan object's ancestors for property definition to avoid conflict, it will delete instances from the 'creation order' list when deleting instances from a layer.... It does a lot of data processes and is not fast.
