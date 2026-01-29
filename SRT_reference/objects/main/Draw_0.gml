var s = ds_list_size(debug)
var _y = height*0.75
draw_line(0,_y,width,_y);
for(var i=0; i<s; i++) 
{
	var text = debug[| i];
	if text=="" continue
	draw_text_scribble(10,_y+i*20, text)
}
if progress!=-1 draw_text_scribble(10,_y+i*20, progress)