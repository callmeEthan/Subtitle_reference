debug = ds_list_create();
width = window_get_width();
height = window_get_height();
room_speed=60;

source=-1;
reference=-1;
translate=-1;

matching = -1; generating = -1;
task = ds_list_create();
enum subtitle_task
{
	retain,
	offset
}
alarm[0]=10
progress = -1;

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
		log("Added source subtitle: "+string(file))
		source = instance_create_depth(0,0,0,subtitle,{filename: file})
	}
}
add_reference = function()
{
	if reference!=-1 and reference.alarm[0]>=0 return false;
	if translate!=-1 and translate.alarm[0]>=0 return false;
	var file;
	file = get_open_filename("Reference subtitle|*.srt", "");
	if (file != "") {pending_reference[@0]=file; log("Added reference subtitle: "+string(file))}
	add_pending()
}
add_translate = function()
{
	if reference!=-1 and reference.alarm[0]>=0 return false;
	if translate!=-1 and translate.alarm[0]>=0 return false;
	var file;
	file = get_open_filename("Translated subtitle|*.srt", "");
	if (file != "") {pending_reference[@1]=file; log("Added translated subtitle: "+string(file))}
	add_pending()
}

add_pending = function()
{
	if pending_reference[0]==-1 log("[c_orange]Add a reference subtitle to begin import!")
	if pending_reference[1]==-1 log("[c_orange]Add a translated subtitle to begin import!")
	if pending_reference[0]==-1 || pending_reference[1]==-1 return false;
	
	var offset = 0;
	if reference!=-1 offset=max(offset, floor(reference.duration*10))
	if translate!=-1 offset=max(offset, floor(translate.duration*10))
	
	// Add reference data
	if reference=-1
	{
		reference = instance_create_depth(width*1/3,0,0,subtitle,{filename: pending_reference[0]})
	} else {
		reference.filename = pending_reference[0];
		with(reference)
		{
			file = file_text_open_read(filename);
			format=-1;
			str="";	time_from=0; time_to=0;
			alarm[0]=1
		}
	}
	
	// Add translate data
	if translate=-1
	{
		translate = instance_create_depth(width*2/3,0,0,subtitle,{filename: pending_reference[1]})
	} else {
		translate.filename = pending_reference[1];
		with(translate)
		{
			file = file_text_open_read(filename);
			format=-1;
			str="";	time_from=0; time_to=0;
			alarm[0]=1
		}
	}
	
	reference.offset = offset;
	translate.offset = offset;
	pending_reference = [-1,-1];
}

pending_reference = [-1,-1];
debugging=false;
log("Press [c_lime]<F1>[/] to add [c_yellow]Source[/] subtitle");
log("Press [c_lime]<F2>[/] to add [c_yellow]Reference[/] subtitle");
log("Press [c_lime]<F3>[/] to add [c_yellow]Translated[/] subtitle");
log("Press [c_lime]<F5>[/] to begin generate subtitle");