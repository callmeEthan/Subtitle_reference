debug = ds_list_create();
width = window_get_width();
height = window_get_height();
room_speed=60;
gpu_set_texfilter(false);

source=-1;
reference=-1;
translate=-1;
loaded = 0;

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
	}
}
add_reference = function()
{
	if reference!=-1 and reference.alarm[0]>=0 return false;
	var filename;
	filename = get_open_filename("Reference subtitle|*.srt", "");
	if (filename == "") return false;
	if !file_exists(filename) return false;
	/*
	if reference!=-1
	{
		with(reference) instance_destroy();
		reference=-1
	};
	if (file != "")
	{
		log("Added reference subtitle: "+string(file))
		reference = instance_create_depth(width*0.5,0,0,subtitle,{filename: file})
		with(reference) {display = display_original;}
	}*/
	if reference=-1
	{
		reference = instance_create_depth(width*1/3,0,0,subtitle,{filename: filename})
	} else {
		reference.filename = filename;
		with(reference)
		{
			file = file_text_open_read(filename);
			format=-1;
			str="";	time_from=0; time_to=0;
			alarm[0]=1
		}
	}
	reference.file_count++;
	
	var offset = 0;
	switch(loaded)
	{
		case 2:
			if reference.duration>0 offset=floor(reference.duration+10);
			if translate!=-1 offset = max(offset, translate.offset);
			break
			
		case 3:
			
			break
	}
	ref_offset(reference, translate)
	log("reference offset="+string(reference.offset));
	loaded=2;
}
add_translate = function()
{
	if translate!=-1 and translate.alarm[0]>=0 return false;
	var filename;
	filename = get_open_filename("Translate subtitle|*.srt", "");
	if (filename == "") return false;
	if !file_exists(filename) return false;
	
	if translate=-1
	{
		translate = instance_create_depth(width*2/3,0,0,subtitle,{filename: filename})
		with(translate) {display = display_original;}
	} else {
		translate.filename = filename;
		with(translate)
		{
			file = file_text_open_read(filename);
			format=-1;
			str="";	time_from=0; time_to=0;
			alarm[0]=1
		}
	}
	translate.file_count++;
	
	ref_offset(translate, reference)
	log("translate offset="+string(translate.offset))
}
ref_offset = function(obj, ref)
{
	var offset = 0;
	if ref!=-1
	{
		if ref.file_count>obj.file_count
		{
			offset = max(offset, ref.offset);
			obj.file_count=ref.file_count-1;
		} else {
			if obj.duration>0 offset=floor(obj.duration+10);
		}
	} else {
		if obj.duration>0 offset=floor(obj.duration+10);
	}
	obj.offset = offset;
	obj.file_count++;
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
