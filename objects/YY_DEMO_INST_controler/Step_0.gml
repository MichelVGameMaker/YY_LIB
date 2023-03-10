/// @description Arrows, Space, Return to modify selected instance
if (selection == noone) exit;
if keyboard_check_pressed(vk_left)   selection.image_xscale -= 0.5;
if keyboard_check_pressed(vk_right)  selection.image_xscale += 0.5;
if keyboard_check_pressed(vk_up)     selection.image_yscale -= 0.5;
if keyboard_check_pressed(vk_down)   selection.image_yscale += 0.5;
if keyboard_check_pressed(vk_return) selection.image_angle  += 90;
if keyboard_check_pressed(vk_space)  selection.my_var_def   ++;
