globalvar match_tolerance, match_list,match_minimum, match_maximum, time_tolerance, fuzzy_match;
match_tolerance = 3;
match_list = ds_priority_create();
match_minimum = 4;	// If only match N words or less, then not considered as matched
match_maximum = 10; // If match more than 10 word, then consider as matched and stop seeking
time_tolerance = 1; 
fuzzy_match = 0.8; // Acceptable letters mismatch (typo tolerance)

function string_contraction(str)
{
	str = string_replace(str, "i am", "i'm");
	str = string_replace(str, "it is", "it's");
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
	}
	return struct;
}
function match_seek(struct)
{
	static _match = 0;
	var source = struct.source;
	var reference = struct.reference;
		
	switch(struct.stage)
	{
		case 0:
			struct.word_index=0;
			struct.stage=1.5
			break;
			
		case 1.5:
			struct.word_index++;
			if struct.line>=array_length(source.lines) {struct.stage=4; break}
			var line = source.lines[struct.line];
			var s = array_length(line);
			if struct.word_index>=s	// End of Line has no matching word, next line
			{
				ds_list_add(main.task, [subtitle_task.retain, struct.line]);
				source.visual_set_line(struct.line, word_color.red);
				struct.line+=1;
				struct.stage=0;
				break
			}
			var word = line[struct.word_index];
			
			var match = reference.words[? word];
			if is_undefined(match)
			{
				source.visual_set_word(line[0]+struct.word_index-1, word_color.red);
				break;
			}
			
			struct.index0 = line[0]+struct.word_index-1;
			struct.word = word;
			struct.match = match;
			struct.match_index = -1;
			struct.stage = 1;
			//main.progress="Matching line "+string(struct.line)+" of "+string(struct.size)+" [c_orange]("+string(round(struct.line/struct.size*100))+"%)"
			main.show_progress("Matching line "+string(struct.line)+" of "+string(struct.size)+" [c_orange]("+string(round(struct.line/struct.size*100))+"%)", struct.line/struct.size)
			break;
			
		case 1: // Seek matching lines
			struct.match_index += 1;
			if (struct.match_index>=array_length(struct.match)) {struct.stage=3; break}
			struct.index1 = struct.index0;
			struct.index2 = struct.match[struct.match_index];
			struct.matched = [struct.index0, struct.index0, struct.index2, struct.index2];
			struct.stage = 2;
			struct.tolerance = 0; struct.unmatch=0;
			_match = 0;
			break
			
		case 2:
			var pos;
			pos = source.word_get_line(struct.index1);
			source.scroll = clamp(source.scroll, pos-20, pos-10);
			pos = reference.word_get_line(struct.index2);
			reference.scroll = clamp(reference.scroll, pos-20, pos-10);
			main.translate.scroll = reference.scroll;
			
			if time_check(struct)
			{
				if word_matching(struct)==true {struct.tolerance=max(struct.tolerance-1, 0); _match++; break}
				if struct.tolerance<1 {struct.tolerance+=1; struct.index1++; struct.index2++; break}
			}
			source.visual_set_word(struct.index0, word_color.green, struct.index1-struct.index0)
			struct.stage=1;
			
			if _match>=match_minimum
			{
				check_min_word(struct);
				ds_priority_add(match_list, variable_clone(struct.matched), struct.matched[1]-struct.matched[0])
			}
			if _match>match_maximum {stage=3}	// reach max, skip seeking and evaluate
			break
		
		case 3:	// evaluation
			if ds_priority_size(match_list)==0
			{
				struct.stage = 1.5;
			} else {
				var temp = ds_priority_find_max(match_list);
				ds_priority_clear(match_list);
				check_min_word(struct, temp)
			
				source.visual_set_word(temp[0], word_color.blue, temp[1]-temp[0]+1);
				add_timestamp(source, reference, temp);
				reference.visual_reset();
			
				pos = source.word_get_line(temp[1])
				struct.line = pos+1;
				struct.stage = 0;
			}
		
			if struct.line<array_length(source.lines) break;
			struct.stage=4
			break
			
		case 4: // end
			main.progress = -1;
			log("[c_lime]Match completed[/]! "+string(ds_list_size(main.task))+" task added.")
			log("Press [c_lime]Ctrl + S[/] to save generated subtitle.");
			//log("Press [c_lime]Ctrl + D[/] to save [b]lines failed to match only[/], useful for manual fixing.");
			return false;
			break
	}
	return true
}
function check_min_word(struct)
{
	var source = struct.source;
	var reference = struct.reference;
	
	var index = struct.matched[3];
	var line = reference.word_get_line(index);
	var array = reference.lines[line]
	var ind = array[0];
	
	if array_length(array)-1>match_tolerance
	{
		if index-ind<ceil(match_tolerance)
		{
			struct.matched[1]-=match_tolerance;
			struct.matched[3]-=match_tolerance;
		}
	}
	return true;
}
function word_matching(struct)
{
	var source = struct.source;
	var reference = struct.reference;
	
	var word1 = source.get_word(struct.index1);
	var word2 = reference.get_word(struct.index2);
	
	if string_compare(word1, word2)>fuzzy_match //word1 = word2
	{
		struct.matched[@1] = struct.index1;
		struct.matched[@3] = struct.index2;
		source.visual_set_word(struct.index1, word_color.lime);
		reference.visual_set_word(struct.index2, word_color.lime);
		struct.index1++;
		struct.index2++;
		return true;
	}
	
	for(var i=1; i<=match_tolerance; i++)
	{
		var _w = reference.get_word(struct.index2+i);
		if string_compare(word1, _w )>fuzzy_match
		{
			struct.index2 += i;
			struct.matched[@1] = struct.index1
			struct.matched[@3] = struct.index2;
			source.visual_set_word(struct.index1, word_color.lime);
			reference.visual_set_word(struct.index2, word_color.lime);
			struct.index1++;
			struct.index2++;
			return true;
		}
	}
	
	for(var i=1; i<=match_tolerance; i++)
	{
		var _w = source.get_word(struct.index1+i);
		if string_compare(_w, word2)>fuzzy_match
		{
			struct.index1 += i;
			struct.matched[@1] = struct.index1;
			struct.matched[@3] = struct.index2;
			source.visual_set_word(struct.index1, word_color.lime);
			reference.visual_set_word(struct.index2, word_color.lime);
			struct.index1++;
			struct.index2++;
			return true;
		}
	}
	return false
}
function time_check(struct)
{
	var source = struct.source;
	var reference = struct.reference;
	
	var line1 = source.word_get_line(struct.index0);
	var line2 = reference.word_get_line(struct.matched[2]);
	
	var time1 = source.get_timestamp(line1, true);
	var time2 = reference.get_timestamp(line2, true);
	var offset = time2 - time1;
	
	var line = source.word_get_line(struct.index1);
	var time1 = source.get_timestamp(line, true);
	var time2 = source.get_timestamp(line, false);
	
	line = reference.word_get_line(struct.index2);
	var time3 = reference.get_timestamp(line, true) - offset;
	var time4 = reference.get_timestamp(line, false) - offset;
	
	if time4<time1-time_tolerance || time3>time2+time_tolerance return false;
	/*
	var line1 = source.word_get_line(struct.index0);
	var line2 = source.word_get_line(struct.index1);
	var time1 = source.get_timestamp(line1, true);
	var time2 = source.get_timestamp(line2, false);
	
	line1 = reference.word_get_line(struct.matched[2]);
	line2 = reference.word_get_line(struct.index2);
	var time3 = reference.get_timestamp(line1, true);
	var time4 = reference.get_timestamp(line2, true);
	
	if (time4-time3)>(time2-time1)+time_tolerance return false;
	*/
	return true;
}
function add_timestamp(source, reference, match)
{
	var time = array_create(7);
	var line1 = source.word_get_line(match[0]);
	var line2 = source.word_get_line(match[1]);
	time[@1] = source.get_timestamp(line1, true);
	time[@2] = source.get_timestamp(line2, false);
	time[@5] = line1;
	time[@6] = line2;
	
	line1 = reference.word_get_line(match[2]);
	line2 = reference.word_get_line(match[3]);
	time[@3] = reference.get_timestamp(line1, true);
	time[@4] = reference.get_timestamp(line2, false);
	
	
	time[@0] = subtitle_task.offset;
	ds_list_add(main.task, time);
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
			var offset = estimate_start_time(source, reference, task[5], task[6], line, task[3]+(task[2]-task[1]));
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
	var _output = 0, priority = 0
	var s1 = array_length(time1);
	var s2 = array_length(time2);
	//show_debug_message("Comparing "+string(s1)+" and "+string(s2)+" timestamps")
	for(var i=0; i<s1; i++)
	for(var j=0; j<s2; j++)
	{
		var offset = time2[j]-time1[i]
		_score=0;
		for(var k=0; k<s1; k++)
		for(var l=0; l<s2; l++)
		{
			var diff = abs((time2[l]-offset)-time1[k]);
			diff = max(time_tolerance - diff, 0)/time_tolerance;
			_score += diff;
			//if abs((time2[l]-offset)-time1[k])<time_tolerance/2 {_score++}
		}
		
		if (_score>match_minimum) && (_score>priority) {priority=_score; _output=offset}
		if priority>=match_maximum
		{
			return _output;
		}
	}
	if _output==0 return undefined;
	return _output;
}