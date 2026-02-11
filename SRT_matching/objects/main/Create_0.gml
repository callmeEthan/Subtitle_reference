debug = ds_list_create();
width = window_get_width();
height = window_get_height();
room_speed=60;
gpu_set_texfilter(false);

source=-1;
reference=-1;
translate=-1;

matching = -1; generating = -1;
task = ds_list_create();
enum subtitle_task
{
	retain,
	match,
	offset
}
alarm[0]=10
progress = -1; progress_bar=-1

add_source = function()
{
	if source!=-1
	{
		with(source) instance_destroy();
		source=-1
	};
	var file;
	file = get_open_filename("Source subtitle|*.srt", "");
	if (file != "")
	{
		log("Added transcribed subtitle: "+string(file))
		source = instance_create_depth(0,0,0,subtitle,{filename: file})
		with(source) {display = display_original;}
	}
}
add_reference = function()
{
	if reference!=-1
	{
		with(reference) instance_destroy();
		reference=-1
	};
	var file;
	file = get_open_filename("Reference subtitle|*.srt", "");
	if (file != "")
	{
		log("Added reference subtitle: "+string(file))
		reference = instance_create_depth(width*0.5,0,0,subtitle,{filename: file})
		with(reference) {display = display_original;}
	}
}
match_begin = function()
{
	if source==-1 {log("Missing source subtitle, press [c_lime]<F1>[/] to add [c_yellow]Source[/] subtitle");exit}
	if reference==-1 {log("Missing reference subtitle, press [c_lime]<F2>[/] to add [c_yellow]Reference[/] subtitle");exit}
	if source.alarm[0]>=0 || reference.alarm[0]>=0 {log("[c_orange]Subtitle import is in progress![/] Please wait");exit}
	
	matching = matching_begin(source, reference, 0);
}

show_progress = function(text, progress=-1)
{
	self.progress = text
	progress_bar = progress;
}

//load_config();
load_dictionary();
pending_reference = [-1,-1];
debugging=false;
log("Press [c_lime]<F1>[/] to add [c_yellow]Source[/] subtitle");
log("Press [c_lime]<F2>[/] to add [c_yellow]Reference[/] subtitle");
log("Press [c_orange]<F5>[/] to restart and remove all subtitle");

render_button = function(x, y, radius, ind, alpha=0.1)
{
	if point_in_rectangle(mouse_x, mouse_y, x-radius/2, y-radius/2, x+radius/2, y+radius/2)
	{
		draw_sprite_stretched_ext(spr_UI, ind, x-radius/2, y-radius/2, radius, radius, c_white, 0.9)
		return true
	} else {
		draw_sprite_stretched_ext(spr_UI, ind, x-radius/2, y-radius/2, radius, radius, c_white, alpha)
		return false
	}
}
spinning = 0;