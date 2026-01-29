scroll = 0;
fontsize = 1; fontscale = string_height("1");

width = main.width*(1/3);
height = main.height*0.75;
duration = 0;
offset = 0;

string_process = function(str)
{
	// Remove all special character from string, keep only letter and number
	// Add an array of word to lines[index] = [word_index, word1, word2, word3,...]
	// Add word to ds_map for fast seeking;
	// Add empty value to visualizer buffer
	// Add line position to word_reference
	
	str = string_clear_format(string_lower(str));
	str = string_contraction(str)
	str = string_trim(str);
	
	var array = string_array(str);
	array_insert(array, 0, word_index)
	var s = array_length(array);
	for(var i=1; i<s; i++)
	{
		var _w = array[i]
		_w = string_lettersdigits(_w);
		if _w==""
		{
			array_delete(array, i, 1);
			s--;	i--
			continue;
		}
		array[@i] = _w;
		
		var _m = words[? _w];
		if is_undefined(_m) {words[? _w]=[word_index]} else {array_push(_m, word_index)}
		buffer_write(visual, buffer_u8, 0);
		buffer_write(words_pos, buffer_u16, line_index)
		word_index++
	}
	array_push(lines, array);
}
scroll_clamp = function(lines, pos)
{
	var _h = floor(height/(fontscale*fontsize));
	pos = max(0, min(pos, lines-_h+2));
	return pos
}
get_word = function(index)
{
	var _l = buffer_peek(words_pos, index*buffer_sizeof(buffer_u16), buffer_u16);
	if _l>=array_length(lines) return undefined;
	var line = lines[_l];
	var _i = line[0];
	if (index-_i+1)>=array_length(line) return undefined;
	return line[index-_i+1];
}
word_get_line = function(index)
{
	return buffer_peek(words_pos, index*buffer_sizeof(buffer_u16), buffer_u16);
}
get_timestamp = function(index, start=true)
{
	if start return buffer_peek(timestamp, (index*2)*buffer_sizeof(buffer_f32), buffer_f32);
	else return buffer_peek(timestamp, (index*2+1)*buffer_sizeof(buffer_f32), buffer_f32);
}

enum word_color
{
	null,
	lime,
	orange,
	blue,
	red,
	green
}
visual_set_word = function(index, value, number=1)
{
	//buffer_poke(visual, index, buffer_u8, value)
	buffer_fill(visual, index, buffer_u8, value, number)
}
visual_set_line = function(line, value)
{
	var l = lines[line];
	var s = array_length(l);
	var ind = l[0];
	//for(var i=0; i<s-1; i++) buffer_poke(visual, ind+i, buffer_u8, value)
	buffer_fill(visual, ind, buffer_u8, value, s-1);
}
visual_reset = function()
{
	buffer_fill(visual, 0, buffer_u8, 0, buffer_get_size(visual))
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