draw_set_font(Font1)

var _radius = width*(1/3)/4
draw_set_halign(fa_center)
if source==-1
{
	if render_button(width*0.16, height*0.4, _radius, 0, 0.3) && mouse_check_button_pressed(mb_left) add_source()
	draw_text_transformed(width*0.16, height*0.4+_radius, "Add source\n(Subtitle provided by the author)", 1, 1, 0)
} else {
	if render_button(width*0.16, height*0.4, _radius, 0, 0.) && mouse_check_button_pressed(mb_left) add_source()
}

if reference==-1
{
	if render_button(width/2, height*0.4, _radius, 0, 0.3) && mouse_check_button_pressed(mb_left) add_reference()
	draw_text_transformed(width/2, height*0.4+_radius, "Add reference\n(Subtitle for the original media\nin the same language)", 1, 1, 0)
} else {
	if render_button(width/2, height*0.4, _radius, 0, 0.1) && mouse_check_button_pressed(mb_left) add_reference()
}

if translate==-1
{
	if render_button(width*0.84, height*0.4, _radius, 0, 0.3) && mouse_check_button_pressed(mb_left) add_translate()
	draw_text_transformed(width*0.84, height*0.4+_radius, "Add translated\n(Subtitle for the original media\nIn the desired language\nSync to reference subtitle)", 1, 1, 0)
} else {
	if render_button(width*0.84, height*0.4, _radius, 0, 0.1) && mouse_check_button_pressed(mb_left) add_translate()
}

if matching==-1 && generating==-1
{
	if ds_list_size(task)>0
	{
		if render_button(width*0.9, height*0.875, height*0.1, 2, 0.5) && mouse_check_button_pressed(mb_left) {main.generating = srt_generate_begin(source, translate)}
		draw_text_transformed(width*0.9, height*(0.875+0.06), "Save subtitle", 1, 1, 0)
	} else if source!=-1 && reference!=-1 && translate!=-1
	{
		if render_button(width*0.9, height*0.875, height*0.1, 1, 0.5) && mouse_check_button_pressed(mb_left) match_begin();
		draw_text_transformed(width*0.9, height*(0.875+.06), "Cross-reference", 1, 1, 0)
	}
} else {
	draw_sprite_ext(spr_UI, 3, width*0.9, height*0.875, (height*0.1)/256, (height*0.1)/256, -spinning*360, c_white, 0.8)
	draw_text_transformed(width*0.9, height*(0.875+.06), "Please wait...", 1, 1, 0)
}
draw_set_halign(fa_left)

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
