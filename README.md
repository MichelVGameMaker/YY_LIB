# YY LIB - Game Maker Files Modifier
 Adjust Game Maker room files and object files within your project directory.

YY is a small collection of functions to adjust Game Maker room files and object files. It is intended to pair with external level editor to facilitate import into Game Maker project.

## About L2G
### Use case
YY is intended to help people working on importers to import data from external room editor or live room editor. I tried to keep the syntax close to what you would use in GML so that you can for instance create an instance in your room file with instance_create().
There is a basic demo. that allows to parse instances created in YY_DEMO room at runtime into the associated YY_DEMO.yy file.
I am working on another example: a function allowing to import the full configuration for entities from a LDtk file.

### Features:
YY focuses on the use cases I needed. 
- create layer for 4 layer types: instances layer, assets layer, tiles layer and background layer.
- modify key properties in existing layers: depth, visible, grid and of course populating layers with instances, tiles and sprites depending on their type.
- clear all layers or clear a specific layer.
- setting instances key attributes: its x/y position, scales, image_angle, image_speed, image_blend)
- setting propert values for instances ( [Variables] of instances in the room editor).
- modify object configuration, in particular properties (=variables from [Variables Definitions] section of Objects Editor).

### Functions:
YY is only three classes; one for room, one for object and one 'light' for sprite:
-	The room class allows to create and modify layers, and to create and modify instances (including their properties).
-	The object class allows to create properties (=variables from [Variables Definitions] section of Objects Editor).
-	The sprite class only allow to get sprite dimensions, and not to modify the file itself.

NB: To avoid having too much impact in your project structure, YY is not capable of creating files, so it needs to recycle existing objects and rooms. 

### License
YY is fully free. Do whatever you want with it.

### Version and Platform
YY is tested on Game Maker LTS and on windows platform.

## Installation
YY needs to be imported as a local package in your Game Maker project.
-	Download the .yymp file from GITHUB.
-	Import it inside your project. You can do this by dragging the *. yymp file from an explorer window onto the GameMaker IDE or by clicking "Import Local Package" within the Tools Menu. In both case, a window will pop up to define import parameters. Click “add all” and “OK”. 

This will create a new folders in your Asset Browser labeled “L2G”. You are all set. If your source file is out of Game Maker sandbox repository, which will surely be the case, you need to de-activate sandboxing. You can do so, on the Desktop targets (Windows, macOS, and Ubuntu (Linux)), by checking the “Disable file system sandbox” option in the Game Options for the target platform.

## How to use
A yy_room or yy_object class is created by calling the constructor with a Game Maker project directory and an asset name.
As YY is not capable of creating files, you will need to recycle existing files already created within Game Maker. 
The typical process runs in three steps: 
-	create a class from an existing Game Maker file, 
-	update the data accordingly to your need, 
-	write back the data to the file.

Each yy_ class simply returns a struct (with the asset's json) and methods to get and set key attributes.
I decided not to create classes for the instances and the layers created by YY to keep the yy_room struct clean from methods. So structs returned by instance_create(), asset_create() or any layer_XX_create() will have no method.

To modify instances, assets and layers please use the methodes from the yy_room class. For instance .layer_visible_get() takes one argument which is the struct return by layer_XX_create() (not the layer name as a string).

Please note that instance_create() method returns the struct describing the instance placed in the room and not the name (identifier) of the instance. 
If you need to store the reference of this instance, you can use its .name value (the INST_A2B8 that you see in the room editor).

With YY you can update a currently opened project. Indeed, Game Maker IDE is smart enough to detect this change in live and ask you what to do in a warning window. If you click 'Save', YY changes will be deleted, if you click 'Reload', YY changes will be taken into account. 
Please note that, some updates are not imediately visible in Game Maker IDE, notably:
- when modifying object variables from the [Variables Definitions] section of the Object Editor, you will need to close the section and reopen it.
- when modifying tiles for a tile layer, you will need to close the associated room and reopen it.
Documentation is a limited so far. You will have to browse through the methods available in the two classes.

## Behind the hood
YY mainly relies on Juju's SNAP to preserve the json format expected by Game Maker. SNAP offers advanced data parsing features. If you do not know about it, or worse about Juju’s library, you can check them out here: https://github.com/JujuAdams
YY does a lot of files and data processes to ensure every formating matches Game Maker standard. It is not fast.

## Using YY

### Game Maker main requirements
YY manages data accordingly to what Game Maker expects. In particular:
- adding an instance to the instances_creation_order when creating it into a room.
- referencing the proper type and object when defining a property into an object
- referencing the proper object when setting a property value into an instance and making sure the property exists before doing so.

### Properties
A property is a variable from the [Variables Definitions] section of the Object Editor.
Properties need to use the proper category in object files (Property or overriddenProperty) and to reference the proper object (where it is defined), in object files and for instances data in room files.
The rules are as follow:
- Classic Properties are those just defined in the current object and not in its parents/ancestors. They appear in the object file using the Property type and reference the current object.
- Inherited properties are those not modified in the object and are fully inherited from parents/ancestors. They do not appear in the object file. When defined in an instance they reference the exact parent where they come from.
- Overridden properties are those inherited from parents/ancestors but modified for the current object. They appear in the object file using the overriddenProperty type and reference the ??? and in insyance.

YY uses the serialized format for tiles data. This is just the list of all tiles data one after another (considering tile index and mirroring). Game Maker 2.3 introduced a new format which is the compressed format which is more complex to encode. Game Maker will automaticaly translates tiles data frop the serialized format to the compressed format so that we can just lazily parse data using the serialized formating. Please note that if you change a tile layer in a project cureently opened in Game Mzker IDE, you will need to close and reopen the room for your changes to be reflected in the room editor.
