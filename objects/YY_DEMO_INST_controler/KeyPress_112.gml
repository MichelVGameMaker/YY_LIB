/// @description Clear layer in the room
if (!initialized) exit;
show_debug_message("[YY] Demo log: [F1] clears the layer called 'Instances'");

// clear the layer at runtime
layer_destroy_instances("Instances")
