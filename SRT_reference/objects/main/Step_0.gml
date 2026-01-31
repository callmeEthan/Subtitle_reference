if spinning<1 spinning+=1/100 else spinning=0

if keyboard_check_pressed(vk_f1) add_source()
if keyboard_check_pressed(vk_f2) add_reference()
if keyboard_check_pressed(vk_f3) add_translate()

if keyboard_check_pressed(vk_f5) {game_restart()}
if keyboard_check_pressed(vk_f12) {show_config()}

if is_struct(matching) 
{
	repeat(match_speed) {if match_seek(matching)==false {matching=-1; exit}}
} else if keyboard_check_pressed(vk_enter)
{
	match_begin()
}

if is_struct(generating) 
{
	srt_generate(generating);
} else {
	if keyboard_check(vk_control)
	{
		if keyboard_check_pressed(ord("S")) {main.generating = srt_generate_begin(source, translate)}
		if keyboard_check_pressed(ord("C")) {save_config()}
	}
}
