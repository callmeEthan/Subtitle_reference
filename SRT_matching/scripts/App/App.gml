function reference_episode(file, _ep=undefined, _ss=undefined)
{
	var ext = filename_name(file);
	if string_length(string_digits(ext))>0
	{
		// Parse episode code (s01e01)
		var ext = file; ext=string_lower(ext)
		for(var i=0; i<10; i++)	
		ext = string_replace_all(ext, string(i), "#")
		
		if DebugMode log("[c_dkgray]String: "+string(ext));
		var _p = string_pos("s##e##", ext)
		if _p>0
		{
			ext = string_copy(file, _p, 6);
			return string_upper(ext);
		}
		
		// Parse text (Season 01 Episode 01)
		ext = string_replace_all(ext, " ", "");
		var num = string_replace_all(file, " ", "");
		var ss=undefined, ep=undefined, temp;
		var _p = string_pos("episode##", ext);
		if _p>0
		{
			temp = string_copy(num, _p, 9);
			if DebugMode log("[c_dkgray]Match string:[/] "+string(temp))
			ep=real(string_digits(temp)); ss=0;
		} else {
			var _p = string_pos("episode#", ext);
			if _p>0
			{
				temp = string_copy(num, _p, 8);
				if DebugMode log("[c_dkgray]Match string:[/] "+string(temp))
				ep=real(string_digits(temp)); ss=0;
			}
		}
		var _p = string_pos("ep ##", ext)
		if _p>0
		{
			temp = string_copy(num, _p, 5);
			if DebugMode log("[c_dkgray]Match string:[/] "+string(temp))
			ep=real(string_digits(temp)); ss=0;
		} else {
			var _p = string_pos("ep #", ext)
			if _p>0
			{
				temp = string_copy(num, _p, 4);
				if DebugMode log("[c_dkgray]Match string:[/] "+string(temp))
				ep=real(string_digits(temp)); ss=0;
			}
		}
		var _p = string_pos("ep##", ext)
		if _p>0
		{
			temp = string_copy(num, _p, 4);
			if DebugMode log("[c_dkgray]Match string:[/] "+string(temp))
			ep=real(string_digits(temp)); ss=0;
		} else {
			var _p = string_pos("ep#", ext)
			if _p>0
			{
				temp = string_copy(num, _p, 3);
				if DebugMode log("[c_dkgray]Match string:[/] "+string(temp))
				ep=real(string_digits(temp)); ss=0;
			}
		}
		var _p = string_pos("e##", ext)
		if _p>0
		{
			temp = string_copy(num, _p, 4);
			if DebugMode log("[c_dkgray]Match string:[/] "+string(temp))
			ep=real(string_digits(temp)); ss=0;
		} else {
			var _p = string_pos("e#", ext)
			if _p>0
			{
				temp = string_copy(num, _p, 3);
				if DebugMode log("[c_dkgray]Match string:[/] "+string(temp))
				ep=real(string_digits(temp)); ss=0;
			}
		}
		if ep==undefined 
		{
			var _p = string_pos("#", ext);
			if _p>0
			{
				var _c = 1;
				for(var i=_p+1; i<_p+10; i++)
				{
					if string_char_at(ext, i)=="#" _c++ else break
				}
				temp = string_copy(num, _p, _c);
				if DebugMode log("[c_dkgray]Match string:[/] "+string(temp))
				ep=real(string_digits(temp)); ss=0;
			}
			/*
			var _p = string_pos("##", ext);
			if _p>0
			{
				temp = string_copy(num, _p, 2);
				if DebugMode log("[c_dkgray]Match string:[/] "+string(temp))
				ep=real(string_digits(temp)); ss=0;
			} else {
				var _p = string_pos("#", ext);
				if _p>0
				{
					temp = string_copy(num, _p, 1);
					if DebugMode log("[c_dkgray]Match string:[/] "+string(temp))
					ep=real(string_digits(temp)); ss=0;
				}
			}*/
		}
		
		var _p = string_pos("season##", ext)
		if _p>0
		{
			temp = string_copy(num, _p, 8);
			if DebugMode log("[c_dkgray]Match string:[/] "+string(temp))
			ss=real(string_digits(temp)); if is_undefined(ep) ep=0;
		}
		if ep==0 && !is_undefined(_ep) {ep=_ep;}
		if ss==0 && !is_undefined(_ss) {ss=_ss;unknown_season=false}
		if !(is_undefined(ep) || is_undefined(ss))
		{
			if ss==0 {unknown_season=true; if DebugMode log("Unknown season")}
			ext = "s"+string_format(ss, 2, 0)+"e"+string_format(ep, ep>99?3:2, 0);
			ext = string_replace_all(ext, " ", "0");
			return string_upper(ext);
		}
	}
	if DebugMode log(filename_name(file) + " [c_orange]cant match episode")
	return undefined
}

function generate_nfo(file, episode, output)
{
	var ss = string_copy(episode, 2, 2);
	var ep = string_copy(episode, 5, string_length(episode)-4);
	//log("Episode: "+string(ep)+", Season: "+string(ss)+", [c_lime]Filename: "+string(file));
	ss = string(real(ss));
	ep = string(real(ep));
	var write = "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>\n<episodedetails>\n<plot />\n<lockdata>false</lockdata>\n<title>Episode "+ep+"</title>\n<episode>"+ep+"</episode>\n<season>"+ss+"</season>\n</episodedetails>"
	
	
	var out = file_text_open_write(output);
	file_text_write_string(out, write)
	if file_text_close(out) {
		log("Output to [c_yellow]"+string(output))
	} else {log("[c_red]Failed to write to "+string(output))}
	
/*
<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<episodedetails>
  <plot />
  <lockdata>false</lockdata>
  <title>Gintama S02E02 (BDRip 1920x1080 x264 10bit FLAC)</title>
  <showtitle>Gintama</showtitle>
  <season>1</season>
</episodedetails>
*/
}

globalvar match_speed, import_speed;
match_speed = 100;
import_speed = 100;

function save_config(filename = "\\Config.ini")
{
	var path = working_directory
	filename = path+filename
	ini_open(filename)
	ini_write_real("Setting", "remove_colon", remove_colon)
	ini_write_real("Setting", "match_tolerance", match_tolerance)
	ini_write_real("Setting", "match_minimum", match_minimum)
	ini_write_real("Setting", "match_maximum", match_maximum)
	ini_write_real("Setting", "time_tolerance", time_tolerance)
	ini_write_real("Setting", "fuzzy_match", fuzzy_match)
	ini_write_real("Performance", "match_speed", match_speed)
	ini_write_real("Performance", "import_speed", import_speed)
	ini_close()
}
function load_config(filename = "\\Config.ini")
{
	var path = working_directory
	filename = path+filename
	if !file_exists(filename) {log("[c_red]Failed to load setting[/], file not found ("+string(filename)+")"); return}
	ini_open(filename)
	remove_colon=ini_read_real("Setting", "remove_colon", remove_colon)
	match_tolerance = ini_read_real("Setting", "match_tolerance", match_tolerance)
	match_minimum = ini_read_real("Setting", "match_minimum", match_minimum)
	match_maximum = ini_read_real("Setting", "match_maximum", match_maximum)
	time_tolerance = ini_read_real("Setting", "time_tolerance", time_tolerance)
	fuzzy_match = ini_read_real("Setting", "fuzzy_match", fuzzy_match)
	match_speed = ini_read_real("Performance", "match_speed", match_speed)
	import_speed = ini_read_real("Performance", "import_speed", import_speed)
	ini_close()
	log("[c_lime]Config file loaded![/]")
}
function show_config()
{
	log("[c_yellow]Current setting:")
	log("match_tolerance: "+string(match_tolerance))
	log("match_minimum: "+string(match_minimum))
	log("match_maximum: "+string(match_maximum))
	log("time_tolerance: "+string(time_tolerance))
	log("fuzzy_match: "+string(fuzzy_match))
	log("match_speed: "+string(match_speed))
	log("import_speed: "+string(import_speed))
}

function load_dictionary(filename = "\\Dictionary.txt")
{
	var path = working_directory
	filename = path+filename
	if !file_exists(filename) {log("[c_red]Failed to load dictionary[/], file not found ("+string(filename)+")"); return}
	
	var file = file_text_open_read(filename);
	while(!file_text_eof(file))
	{
		var text = file_text_read_string(file);
		if string_pos(":", text)==0 {file_text_readln(file);	continue}
		
		var words = string_split(text, ":");
		var entry = [string_replace_all(words[0], "\"", ""), string_replace_all(words[1], "\"", "")]
		ds_list_add(dictionary, entry)
		file_text_readln(file)
	}
	file_text_close(file);
	log("Dictionary added, "+string(ds_list_size(dictionary))+" words found");
}