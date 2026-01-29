/// @description Insert description here
// You can write your code in this editor
var size = array_length(lines)
var _h = fontscale*fontsize;
var _space = string_width(" ")*fontsize;
var _y = 0;
scroll = scroll_clamp(size, scroll);
var _n = string_width("9999")*fontsize;

draw_line(x+_n+_space, y, x+_n+_space, height-_h)

var s = min(scroll+ceil(height/_h)-2, size);
for(var i=scroll; i<s; i++)
{
	draw_text_transformed(x, _h*_y, i, fontsize, fontsize, 0);	// index
	var _x = x+ _n+_space*2
	var l = lines[i]
	
	var d = array_length(l);	// words
	var ind = l[0];
	for(var j=1; j<d; j++)
	{
		var _w = string_width(l[j]);
		if _x+_w>x+width break;
		var col = buffer_peek(visual, ind+j-1, buffer_u8);
		switch(col)
		{
			default: break
			
			case 1:
				draw_set_color(c_lime)
				draw_rectangle(_x-_space/2, _h*_y, _x+_w+_space/2, _h*(_y+1), false);
				draw_set_color(c_white)
				break
			case 2:
				draw_set_color(c_orange)
				draw_rectangle(_x-_space/2, _h*_y, _x+_w+_space/2, _h*(_y+1), false);
				draw_set_color(c_white)
				break
			case 3:
				draw_set_color(c_blue)
				draw_rectangle(_x-_space/2, _h*_y, _x+_w+_space/2, _h*(_y+1), false);
				draw_set_color(c_white)
				break
			case 4:
				draw_set_color(c_red)
				draw_rectangle(_x-_space/2, _h*_y, _x+_w+_space/2, _h*(_y+1), false);
				draw_set_color(c_white)
				break
			case 5:
				draw_set_color(c_green)
				draw_rectangle(_x-_space/2, _h*_y, _x+_w+_space/2, _h*(_y+1), false);
				draw_set_color(c_white)
				break
		}
		draw_text_transformed(_x, _h*_y, l[j], fontsize, fontsize, 0);
		_x += _space+_w;
	}
	_y++;
}

draw_text(x, height-_h, "lines: "+string(size)+", words: "+string(ds_map_size(words))+", total words: "+string(word_index))