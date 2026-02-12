scroll = 0;
fontsize = 1; fontscale = string_height("1");
file_count = 0;

width = main.width*(1/3);
height = main.height*0.75;
duration = 0;
offset = 0;
size=0;
phonics=0;

string_process = function(str)
{
	// Remove all special character from string, keep only letter and number
	// Add an array of word to lines[index] = [word_index, word1, word2, word3,...]
	// Add word to ds_map for fast seeking;
	// Add empty value to visualizer buffer
	// Add line position to word_reference
	
	if remove_colon==true str=string_remove_colon(str);
	str = string_clear_format(string_lower(str));
	str = string_contraction(str)
	str = string_trim(str);
	
	if display==display_phonic
	{
		var array = string_array(str);
		var phonic = "";
		var s = array_length(array);
		for(var i=0; i<s; i++)
		{
			var _w = array[i]
			_w = string_lettersdigits(_w);
			if _w=="" continue
			phonic += metaphone(_w)
		}
		phonics += string_length(phonic);
		array_push(lines, phonic);
	} else {
		array_push(lines, 0);
	}
	buffer_write(visual, buffer_u32, 0);
}
scroll_clamp = function(lines, pos)
{
	var _h = floor(height/(fontscale*fontsize));
	pos = max(0, min(pos, lines-_h+2));
	return pos
}
get_line = function(index)
{
	if index>=size || index<0 return undefined;
	return lines[index]
}
get_timestamp = function(index, start=true)
{
	if start return buffer_peek(timestamp, (index*2)*buffer_sizeof(buffer_f32), buffer_f32);
	else return buffer_peek(timestamp, (index*2+1)*buffer_sizeof(buffer_f32), buffer_f32);
}

display_phonic = function()
{
	var size = array_length(lines)
	var _h = fontscale*fontsize;
	var _space = string_width(" ")*fontsize;
	var _y = 0;
	scroll = scroll_clamp(size, scroll);
	var _n = string_width("9999")*fontsize;

	if pending==-1
	{
		draw_set_color(c_dkgray);
		draw_rectangle(x, height-_h, x+width, height,false);
		draw_rectangle(x, y, x+_n+_space, height-_h,false);
		draw_set_color(c_white);
		draw_text(x, height-_h, "lines: "+string(size)+", phonics: "+string(phonics))
		draw_line(x+_n+_space, y, x+_n+_space, height-_h);
	} else {
		draw_set_color(c_orange);
		draw_rectangle(x, height-_h, x+width, height,false);
		draw_set_color(c_dkgray);
		draw_rectangle(x, y, x+_n+_space, height-_h,false);
		draw_set_color(c_black);
		draw_text(x, height-_h, pending);
		draw_set_color(c_white);
		draw_line(x+_n+_space, y, x+_n+_space, height-_h);
	}

	var s = min(scroll+ceil(height/_h)-2, size);
	for(var i=scroll; i<s; i++)
	{
		draw_text_transformed(x, _h*_y, i, fontsize, fontsize, 0);	// index
		var _x = x+ _n+_space*2
		var l = lines[i]
		var ind = i;
		var col = buffer_peek(visual, ind*buffer_sizeof(buffer_u32), buffer_u32);
	
		var str = lines[i];
		var _w = string_width(str);
		draw_set_color(col)
		draw_rectangle(_x-_space/2, _h*_y, _x+_w+_space/2, _h*(_y+1), false);
		draw_set_color(c_white)
		draw_text_transformed(_x, _h*_y, str, fontsize, fontsize, 0);
		_y++;
	}
	
}
display_original = function()
{
	var size = array_length(lines)
	var _h = fontscale*fontsize;
	var _space = string_width(" ")*fontsize;
	var _y = 0;
	scroll = scroll_clamp(size, scroll);
	var _n = string_width("9999")*fontsize;

	if pending==-1
	{
		draw_set_color(c_dkgray);
		draw_rectangle(x, height-_h, x+width, height,false);
		draw_rectangle(x, y, x+_n+_space, height-_h,false);
		draw_set_color(c_white);
		draw_text(x, height-_h, "lines: "+string(size))
		draw_line(x+_n+_space, y, x+_n+_space, height-_h);
	} else {
		draw_set_color(c_orange);
		draw_rectangle(x, height-_h, x+width, height,false);
		draw_set_color(c_dkgray);
		draw_rectangle(x, y, x+_n+_space, height-_h,false);
		draw_set_color(c_black);
		draw_text(x, height-_h, pending);
		draw_set_color(c_white);
		draw_line(x+_n+_space, y, x+_n+_space, height-_h);
	}

	var s = min(scroll+ceil(height/_h)-2, size);
	for(var i=scroll; i<s; i++)
	{
		draw_text_transformed(x, _h*_y, i, fontsize, fontsize, 0);	// index
		var _x = x+ _n+_space*2
		var l = lines[i]
		var ind = i;
		var col = buffer_peek(visual, ind*buffer_sizeof(buffer_u32), buffer_u32);
	
		var str = string_replace(original[i], "\n", " ");
		var _w = string_width(str);
		draw_set_color(col)
		draw_rectangle(_x-_space/2, _h*_y, _x+_w+_space/2, _h*(_y+1), false);
		draw_set_color(c_white)
		draw_text_transformed(_x, _h*_y, str, fontsize, fontsize, 0);
		_y++;
	}
	
}
pending = -1

visual_set_line = function(line, value)
{
	buffer_poke(visual, line*buffer_sizeof(buffer_u32), buffer_u32, value);
}
visual_reset = function()
{
	buffer_fill(visual, 0, buffer_u32, 0, buffer_get_size(visual))
}

if !file_exists(filename) {log("[c_red]File not found: "+string(filename)); instance_destroy()}
file = file_text_open_read(filename);
line_index=-1; word_index=0;
format=-1;
str="";	time_from=0; time_to=0;

lines = [];	// each value contain an array of every word in the line
timestamp = buffer_create(16, buffer_grow, 1);	// timestamp of each line
visual = buffer_create(16, buffer_grow, 1);	// visual color of each word
words = ds_map_create();	// all position of each word for fast indexing
words_pos = buffer_create(16, buffer_grow, 1);	// line index of each words
original = [];
timestamp_seek = buffer_create(16, buffer_grow, 1);

alarm[0]=1
display = display_phonic;