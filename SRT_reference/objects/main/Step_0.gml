if keyboard_check_pressed(vk_f1) add_source()
if keyboard_check_pressed(vk_f2) add_reference()
if keyboard_check_pressed(vk_f3) add_translate()

if keyboard_check(vk_control)
{
	if keyboard_check_pressed(ord("S")) {debugging=false; main.generating = srt_generate_begin(source, translate)}
	if keyboard_check_pressed(ord("D")) {debugging=true; main.generating = srt_generate_begin(source, translate)}
}

if keyboard_check_pressed(vk_f5)
{
	matching = matching_begin(source, reference, 0);
}

if is_struct(matching) 
{
	repeat(100) {if match_seek(matching)==false {matching=-1; exit}}
}
if is_struct(generating) 
{
	srt_generate(generating);
}
if keyboard_check_pressed(vk_f6) log("test")