globalvar match_length, match_list,match_minimum, match_maximum, time_tolerance, fuzzy_match, dictionary, remove_colon;
remove_colon = 1; // If there's colon (:) then remove first part (speaker name)
match_length = 10;
match_list = ds_priority_create();
match_minimum = 2;
match_maximum = 7;
time_tolerance = 1; 
fuzzy_match = 0.5;
dictionary = ds_list_create();

function string_contraction(str)
{
	var s = ds_list_size(dictionary);
	for(var i=0; i<s; i++)
	{
		var entry = dictionary[| i];
		str = string_replace(str, entry[0], entry[1]);	
	}
	return str;	
}
function srt_parse_time(text)
{
	text = string_trim(text);
	text = string_replace_all(text, ",", ".")
	var val = string_split(text, ":");
	var time = real(val[2])+real(val[1])*60+real(val[0])*60*60;
	return max(time, 0);
}
function srt_time_stringify(value)
{
	var hour = floor(value/3600);
	var minute = floor((value - hour*3600) / 60);
	var second = value - (hour*3600 + minute*60);
		
	hour = string_format(hour, 2, 0);
	minute = string_format(minute, 2, 0);
	second = string_format(second, 2, 3);
	var text = hour+":"+minute+":"+second;
	text = string_replace_all(text, ".", ",");
	text = string_replace_all(text, " ", "0");
	return text;
}

function string_array(str)
{
	// Break string down into words
	str = string_replace(str, "\n", " ");
	var array = string_split(str, " ", true);
	return array;
}
function string_clear_format(str)
{
	static delim = function(str, open, close)
	{
		if string_pos(open, str)>0
		{
			var out = ""
			var array = string_split(str, open);
			var s = array_length(array);
			for(var i=0; i<s; i++)
			{
				var pos = string_pos(close, array[i]);
				if pos==0 out=out+array[i] else
				{
					out = out + string_delete(array[i], 1, pos)
				}
			}
			return out;
		} else {return str}
	}
	str = delim(str, "<", ">")
	str = delim(str, "(", ")")
	str = delim(str, "[", "]")
	return str
}
function string_remove_colon(str)
{
	var pos = string_pos(":", str);
	if pos>0 str = string_copy(str, pos+1, string_length(str)-pos)
	return str
}

function matching_begin(source, reference)
{
	log("Initiate matching data...")
	var struct = 
	{
		source: source,
		reference: reference,
		
		line: 0,
		stage: 0,
		size: array_length(source.lines),
		index1: 0,
		index2: 0,
	}
	return struct;
}
function match_seek(struct)
{
	var source = struct.source;
	var reference = struct.reference;
		
	switch(struct.stage)
	{
		case 0:			
			struct.stage = 1;
			struct.match = 0;
			struct.evaluate = 0;	struct.highest=0; struct.highest_match=0
			struct.index2=0;
			struct.size1=0;	struct.size2=0;
			//reference.visual_reset();
			
		case 1:
			struct.seek1 = struct.index1;
			struct.seek2 = struct.index2;
			struct.line1 = "";	struct.length1=0
			struct.stage=2
			break
			
		case 2:	// first fuzzy match
			struct.line1 = source.get_line(struct.seek1); source.visual_set_line(struct.seek1, c_blue);source.scroll = clamp(source.scroll, struct.seek1-20, struct.seek1-10);
			struct.length1 = string_length(struct.line1);
			while(struct.length1<match_length)
			{
				struct.seek1++
				struct.line1 += source.get_line(struct.seek1); source.visual_set_line(struct.seek1, c_blue);source.scroll = clamp(source.scroll, struct.seek1-20, struct.seek1-10);
				struct.length1 = string_length(struct.line1);
			}
			
			struct.line2 = "";
			for(var i=struct.seek2; i<reference.size; i++)
			{
				struct.line2 += reference.get_line(i);
				if string_length(struct.line2)>=struct.length1 {break}
			}
			struct.seek2=i;
			var _match = string_compare(struct.line1, struct.line2);
			
			if _match<fuzzy_match 
			{
				struct.stage = 4;
				break;
			}
			reference.visual_set_line(struct.seek2, merge_colour(c_red, c_blue, _match));
			reference.scroll = clamp(reference.scroll, struct.seek2-20, struct.seek2-10);
			struct.match = [struct.index1, struct.index2, struct.seek1, struct.seek2]
			struct.evaluate=_match;
			struct.stage=3;
			main.show_progress("Matching line "+string(struct.index1)+" of "+string(source.size)+" [c_orange]("+string(round(struct.line/struct.size*100))+"%)[/], referencing "+string(round(struct.index2/reference.size*100))+"%")
			break;
			
		case 3: // match subsequence lines
			struct.size1 = string_length(struct.line1);
			struct.size2 = string_length(struct.line2);
			struct.seek1++;
			struct.line1 += source.get_line(struct.seek1); source.visual_set_line(struct.seek1, c_green); source.scroll = clamp(source.scroll, struct.seek1-20, struct.seek1-10);
			struct.length1 = string_length(struct.line1);
			for(var i=struct.seek2; i<reference.size; i++)
			{
				struct.line2 += reference.get_line(i);
				if string_length(struct.line2)>=struct.length1 {break}
			}
			struct.seek2=i;
			var pos = min(struct.size1, struct.size2);
			var str1 = string_copy(struct.line1, pos+1, string_length(struct.line1)-pos);
			var str2 = string_copy(struct.line2, pos+1, string_length(struct.line2)-pos);
			//log("additional compare "+string(struct.line1)+"="+string(struct.line2)+" pos: "+string(pos)+" ("+str1+"="+str2+")")
			var _match = string_compare(str1, str2);
			if _match<fuzzy_match 
			{
				struct.stage = 4;
				break;
			}
			reference.visual_set_line(struct.seek2, merge_colour(c_red, c_lime, _match));
			reference.scroll = clamp(reference.scroll, struct.seek2-20, struct.seek2-10);
			struct.match[@2] = struct.seek1;
			struct.match[@3] = struct.seek2;
			struct.evaluate += _match;
			break;
			
		case 4: // evaluate
			if true //struct.evaluate>match_minimum
			{
				if struct.evaluate>struct.highest
				{
					struct.highest=struct.evaluate;
					struct.highest_match=struct.match;
				}
			}
			if struct.evaluate>match_maximum {struct.stage=5; break}	// high score, finish matching
			if struct.index2>=reference.size {struct.stage=5; break}	// end of reference, go to next line
			struct.index2+=1;
			struct.stage=1;	// seek again, reference different line
			break
		case 5:	// finish match line
			log("Line "+string(struct.index1)+" Finish matching, score="+string(struct.highest))
			if struct.highest_match==0
			{
				source.visual_set_line(struct.index1, c_red);
				struct.index1++;
			} else {
				for(var i=struct.index1; i<=struct.highest_match[2]; i++)
				{
					source.visual_set_line(i, c_black)
				}
				struct.index1 = struct.highest_match[2]+1;
				var _match = string(struct.highest_match);
			}
			struct.stage=0
			break
			
		case 6: // end
			main.progress = -1;
			log("[c_lime]Match completed[/]! "+string(ds_list_size(main.task))+" task added.")
			log("Press [c_lime]Ctrl + S[/] to save generated subtitle.");
			return false;
			break
	}
	return true
}

function add_timeline(struct)
{
	ds_list_add(main.task, [struct.index1, struct.index2, struct.seek1, struct.seek2])
}

function srt_generate_begin(source, translate)
{
	log("Initiate subtitle generate...")
	var filename;
	filename = get_save_filename("Subtitle file|*.srt", "");
	if (filename != "")
	{
		var file = file_text_open_write(filename);
	} else return undefined;
	
	var path = filename_path(filename);
	if file_exists( path+"\\Debugging.txt") file_delete(path+"Debugging.txt");
	var _debug = file_text_open_write(path+"Debugging.txt")
	var struct = 
	{
		source: source,
		reference: translate,
		file: file,
		filename: filename,
		line: 1,
		task: 0,
		size: ds_list_size(main.task),
		debug: _debug
	}
	return struct;
}
function srt_generate(struct)
{
	static _prev=""
	if struct.task>=struct.size
	{
		if file_text_close(struct.file) {log("Saved to [c_yellow]"+string(struct.filename))} else {log("[c_red]Failed to write to "+string(struct.filename))}
		if file_text_close(struct.debug) {log("Debug file saved to [c_yellow]Debugging.txt[/], read this file to check the lines failed to match.")} else {log("[c_red]Failed to write to Debugging.txt")}
		main.generating=-1;
		main.progress=-1;
		return false;
	}
	
	//main.progress="Generating subtitle, task "+string(struct.task)+" of "+string(struct.size)+" [c_orange]("+string(round(struct.task/struct.size*100))+"%)"
	main.show_progress("Generating subtitle, task "+string(struct.task)+" of "+string(struct.size)+" [c_orange]("+string(round(struct.task/struct.size*100))+"%)", struct.task/struct.size)
	var task = main.task[| struct.task];
	struct.task++;
	
	var source = struct.source;
	var reference = struct.reference;
	switch(task[0])
	{
		case subtitle_task.retain:
			var line = task[1];
			source.scroll = clamp(source.scroll, line-20, line-10);
			var time1 = source.get_timestamp(line, true);
			var time2 = source.get_timestamp(line, false);
			
			file_text_write_string(struct.file, struct.line);
			file_text_writeln(struct.file);
			file_text_write_string(struct.file, srt_time_stringify(time1)+" --> "+srt_time_stringify(time2))
			file_text_writeln(struct.file);
			file_text_write_string(struct.file, source.original[line]);
			file_text_writeln(struct.file);
			file_text_writeln(struct.file);
			
			file_text_write_string(struct.debug, struct.line);
			file_text_writeln(struct.debug);
			file_text_write_string(struct.debug, srt_time_stringify(time1)+" --> "+srt_time_stringify(time2))
			file_text_writeln(struct.debug);
			file_text_write_string(struct.debug, source.original[line]);
			file_text_writeln(struct.debug);
			file_text_writeln(struct.debug);
			struct.line+=1;
			break;
			
		case subtitle_task.offset:
			//if main.debugging=true break
			var line = -1;
			
			var t = infinity, _t;
			var s = array_length(reference.lines);
			buffer_seek(reference.timestamp_seek, buffer_seek_start, 0);
			for(var i=0; i<s; i++)
			{
				var time = buffer_read(reference.timestamp_seek, buffer_f32);
				if ((task[3]+time_tolerance)-time)<0 break;
				if ((task[3]+time_tolerance)-time)<t {t=(task[3]+time_tolerance)-time; line=i; _t = time;}
			}
			if line==-1 log("Can't find line for timestamp "+srt_time_stringify(task[3]))
			//show_debug_message("At "+srt_time_stringify(task[1])+": Seek timestamp "+srt_time_stringify(task[3])+" found: "+srt_time_stringify(_t)+", line "+string(line)+": "+string(reference.original[line]));
			
			//var offset = (task[3]+task[4])/2-(task[1]+task[2])/2;
			var offset;
			offset = task[7];
			if is_undefined(offset) offset = estimate_start_time(source, reference, task[5], task[6], line, task[3]+(task[2]-task[1]));
			if is_undefined(offset) offset = (task[3]+task[4])/2-(task[1]+task[2])/2;
			for(var i=line; i<s; i++)
			{
				reference.scroll = clamp(reference.scroll, i-20, i-10);
				reference.visual_set_line(i, word_color.blue);
				var _from = reference.get_timestamp(i, true)-offset;
				var _to = reference.get_timestamp(i, false)-offset;
				if _from>task[2]-time_tolerance break;
				
				var str = reference.original[i];
				if str!=_prev
				{
					file_text_write_string(struct.file, struct.line);
					file_text_writeln(struct.file);
					file_text_write_string(struct.file, srt_time_stringify(_from)+" --> "+srt_time_stringify(_to))
					file_text_writeln(struct.file);
					file_text_write_string(struct.file, str);
					file_text_writeln(struct.file);
					file_text_writeln(struct.file);
					struct.line++;
				}
				_prev = ""
				
				if _to>task[2]-time_tolerance break;
			}
			_prev = reference.original[min(i,s-1)];
			break
	}
	return true;
}
function estimate_start_time(source, reference, linestart, lineend, lineref, timeend)
{
	if linestart==lineend return undefined;
	// Get timestamp start
	var time1 = [];
	var time2 = [];
	for(var i=linestart; i<lineend; i++) {array_push(time1, source.get_timestamp(i, true));}
	var s = array_length(reference.lines);
	for(var i=lineref; i<s; i++)
	{
		var _from = reference.get_timestamp(i, true);
		var _to = reference.get_timestamp(i, false);
		if _from>timeend-time_tolerance break;
		array_push(time2, _from);
		if _to>timeend-time_tolerance break;
	}
	
	// Comparing matches
	var _score = 0;
	var _output = 0, priority = 0, _test=0
	var s1 = array_length(time1);
	var s2 = array_length(time2);
	if min(s1,s2)<3 return undefined;
	//show_debug_message("Comparing "+string(s1)+" and "+string(s2)+" timestamps")
	for(var i=0; i<s1; i++)
	for(var j=0; j<s2; j++)
	{
		var offset = time2[j]-time1[i]
		_score=0;
		_test=0
		for(var k=0; k<s1; k++)
		for(var l=0; l<s2; l++)
		{
			if _test-_score<match_minimum break;
			var diff = abs((time2[l]-offset)-time1[k]);
			diff = max(time_tolerance - diff, 0)/time_tolerance;
			_score += diff;
			_test+=1
			//if abs((time2[l]-offset)-time1[k])<time_tolerance/2 {_score++}
		}
		
		if _score>min(s1, s2)*(0.5) && (_score>priority) {priority=_score; _output=offset}
		/*if priority>=min(s1, s2)*0.85
		{
			return _output;
		}*/
	}
	if _output==0 return undefined;
	return _output;
}