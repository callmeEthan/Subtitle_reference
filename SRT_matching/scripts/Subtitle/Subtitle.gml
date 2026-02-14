globalvar match_length,match_minimum, match_maximum, time_tolerance, fuzzy_match, dictionary, remove_colon;
remove_colon = 1; // If there's colon (:) then remove first part (speaker name)
match_length = 5; // Minimum number of character for fuzzy matching, include multiple line if necessary
match_minimum = 0.4; // Minimum score to consider as matched, otherwise retain original line
match_maximum = 10; // Maximum score for matching, skip checking other line.
time_tolerance = 0.5;
fuzzy_match = 0.2; // mininum match per line
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
		failed: 0,
	}
	buffer_fill(source.match_score, 0, buffer_f16, 0, array_length(source.lines))
	buffer_fill(reference.match_score, 0, buffer_f16, 0, array_length(reference.lines))
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
			
		case 1:
			struct.seek1 = struct.index1;
			struct.seek2 = struct.index2;
			struct.line1 = "";	struct.length1=0
			struct.stage=2;
			struct.offset=undefined;
			struct.offset_skip=0;
			break
			
		case 2:	// first fuzzy match
			main.show_progress("Matching line "+string(struct.index1)+" of "+string(source.size)+" [c_orange]("+string(floor(struct.index1/struct.size*100))+"%)[/], referencing "
			+string(floor(struct.index2/reference.size*100))+"%, status: [c_lime]"
			+string(100-floor(struct.failed/struct.index1*100))+"% matched")
			
			struct.line1 = source.get_line(struct.seek1); source.visual_set_line(struct.seek1, c_navy);source.scroll = clamp(source.scroll, struct.seek1-20, struct.seek1-10);
			struct.length1 = string_length(struct.line1);
			struct.seek1++
			if struct.length1<match_length // line too short to match, skipping
			{
				struct.stage = 4;
				break;
			}
			/*
			while(struct.length1<match_length)
			{
				if struct.seek1>=source.size break;
				struct.line1 += source.get_line(struct.seek1); source.visual_set_line(struct.seek1, c_navy);source.scroll = clamp(source.scroll, struct.seek1-20, struct.seek1-10);
				struct.length1 = string_length(struct.line1);
				struct.seek1++;
			}
			*/
			struct.line2 = "";
			for(var i=struct.seek2; i<reference.size; i++)
			{
				struct.line2 += reference.get_line(i);
				if string_length(struct.line2)>=struct.length1 {break}
			}
			struct.seek2=i+1;
			var _prev = source.line_get_score(struct.index1);
			var _match = string_compare(struct.line1, struct.line2);
			//log("string compare "+string(struct.index1)+"="+string(struct.index2)+" ("+struct.line1+"="+struct.line2+")")
			if _match<fuzzy_match || _match<_prev
			{
				struct.stage = 4;
				break;
			}
			
			var offset = check_timing(struct);
			if !is_undefined(offset) struct.offset=offset;
			
			reference.visual_set_line(struct.seek2, merge_colour(c_red, c_lime, _match));
			reference.scroll = clamp(reference.scroll, struct.seek2-20, struct.seek2-10);
			struct.match = [struct.index1, struct.index2, struct.seek1-1, struct.seek2-1, offset];
			struct.scores = [_match]
			struct.evaluate=_match;
			struct.stage=3;
			break;
			
		case 3: // match subsequence lines
			struct.size1 = string_length(struct.line1);
			struct.size2 = string_length(struct.line2);
			if struct.seek1>=source.size  // end of file
			{
				struct.stage = 4;
				break;
			}
			struct.line1 += source.get_line(struct.seek1); source.visual_set_line(struct.seek1, c_teal); source.scroll = clamp(source.scroll, struct.seek1-20, struct.seek1-10);
			struct.length1 = string_length(struct.line1);
			struct.seek1++;
			for(var i=struct.seek2; i<reference.size; i++)
			{
				struct.line2 += reference.get_line(i);
				if string_length(struct.line2)>=struct.length1 {break}
			}
			struct.seek2=i+1;
			//log("check next line "+string(struct.seek2-1))
			//var pos = min(struct.size1, struct.size2);
			var pos = min(struct.size1, string_length(struct.line1)-match_length);
			var str1 = string_copy(struct.line1, pos+1, string_length(struct.line1)-pos);
			var str2 = string_copy(struct.line2, pos+1, string_length(struct.line2)-pos);
			//log("additional compare "+string(struct.line1)+"="+string(struct.line2)+" pos: "+string(pos)+" ("+str1+"="+str2+")")
			var _match = string_compare(str1, str2);
			if _match<fuzzy_match || check_duration(struct)==false
			{
				struct.stage = 4;
				break;
			}
			reference.visual_set_line(struct.seek2, merge_colour(c_red, c_lime, _match));
			reference.scroll = clamp(reference.scroll, struct.seek2-20, struct.seek2-10);
			struct.match[@2] = struct.seek1-1;
			struct.match[@3] = struct.seek2-1;
			array_push(struct.scores, _match);
			struct.evaluate += _match;
			
			var offset = check_timing(struct, struct.offset_skip);
			if !is_undefined(offset)
			{
				if !is_undefined(struct.offset)
				{
					if abs(struct.offset-offset)>0.3	// timing is off, skip checking
					{
						struct.stage = 4;
						break
					}
				}
				struct.offset=offset;
				struct.offset_skip=struct.seek1-1;
			}
			break;
			
		case 4: // evaluate
			if struct.evaluate>match_minimum
			{
				if struct.evaluate>struct.highest
				{
					struct.highest=struct.evaluate;
					struct.highest_match=struct.match;
					struct.highest_score=struct.scores;
				}
			}
			if struct.evaluate>match_maximum {struct.stage=5; break}	// highest score, skip matching
			if struct.index2>=reference.size {struct.stage=5; break}	// end of reference, end match and go to next line
			struct.index2+=1;
			struct.stage=1;	// seek again, reference different line
			break
			
		case 5:	// finish match line
			if struct.highest_match==0
			{
				log("Line "+string(struct.index1)+" Finish matching, score="+string(struct.highest))
				if buffer_peek(source.line_task, struct.index1*buffer_sizeof(buffer_s16), buffer_s16)<0
				{
					// no line match (Failed)
					source.visual_set_line(struct.index1, c_red);
					struct.failed++;
					ds_list_add(main.task, [subtitle_task.retain, struct.index1])
				} else {
					// line already matched previously. (Acceptable)
					source.visual_set_line(struct.index1, c_olive);
				}
				
				struct.index1++;
			} else {
				log("Line "+string(struct.index1)+" Finish matching, score="+string(struct.highest)+" ("+string(struct.match[2]-struct.match[0]+1)+" line)")
				var _match = struct.highest_match;
				task_override(struct, _match);
				var offset = _match[4];
				var ind = ds_list_size(main.task);
				for(var i=struct.index1; i<=_match[2]; i++)
				{
					
					buffer_poke(source.line_task, i*buffer_sizeof(buffer_s16), buffer_s16, ind);
					if is_undefined(offset) source.visual_set_line(i, c_purple);
					else source.visual_set_line(i, c_green);
				}
				var s = array_length(struct.highest_score);
				for(var i=0; i<s; i++)
				{
					var _score = struct.highest_score[i];
					buffer_poke(source.match_score, (_match[0]+i)*buffer_sizeof(buffer_f16), buffer_f16, _score);
				}
				struct.index1 = _match[2]+1;
				for(var i=1; i<s; i++) // recheck line if score isn't higher
				{
					var _score = struct.highest_score[i];
					if _score<0.9 {struct.index1 = _match[0]+i; break}
				}
				array_insert(_match, 0, subtitle_task.match);
				ds_list_add(main.task, _match);
			}
			struct.stage=0
			if struct.index1>=source.size {struct.stage=6}
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
function check_timing(struct, skip=0)
{
	var source = struct.source;
	var reference = struct.reference;
	for(var i=struct.index1+skip; i<=struct.seek1-1; i++)
	{
		var _str1 = source.get_line(i);
		if string_length(_str1)<5 continue;
		_str1 = string_copy(_str1, 1, 5);
		
		for(var j=struct.seek2-1; j>=struct.index2; j--)
		{
			var _str2 = reference.get_line(j);
			if string_length(_str2)<5 continue;
			_str2 = string_copy(_str2, 1, 5);
			
			if string_compare(_str1, _str2)>0.5
			{
				var _time1 = source.get_timestamp(i, true);
				var _time2 = reference.get_timestamp(j, true);
				var _offset = _time2 - _time1;
				return _offset;
			}
		}
	}
	return undefined
}
function check_duration(struct, tolerance=1)
{
	var source = struct.source;
	var reference = struct.reference;
	
	var _from = source.get_timestamp(struct.index1, true);
	var _to = source.get_timestamp(struct.seek1-1, false);
	
	var _start = reference.get_timestamp(struct.index2, true)
	var _end = reference.get_timestamp(struct.seek2-1, true);
	//if _start>_to+tolerance {return false}
	if (_end-_start)>(_to-_from)+tolerance
	{
		return false;
	}
	return true;
}
function task_override(struct, match)
{
	var source = struct.source;
	var reference = struct.reference;
	
	for(var i=match[0]; i<=match[2]; i++)
	{
		var ind = buffer_peek(source.line_task, i*buffer_sizeof(buffer_s16), buffer_s16);
		if ind<0 continue;
		var task = main.task[| ind];
		task[@3] = min(task[3], match[0]-1);
	}
}


function srt_generate_begin(source, reference, translate=-1)
{
	var filename;
	filename = get_save_filename("Subtitle file|*.srt", "");
	if (filename = "") return -1;
	
	log("Initiate subtitle generate...")
	var file = file_text_open_write(filename);
	var path = filename_path(filename);
	if file_exists( path+"\\Debugging.txt") file_delete(path+"Debugging.txt");
	var _debug = file_text_open_write(path+"Debugging.txt")
	var struct = 
	{
		source: source,
		reference: reference,
		translate: translate,
		file: file,
		filename: filename,
		line: 1,
		task: 0,
		size: ds_list_size(main.task),
		debug: _debug,
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
	var translate = struct.translate;
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
			
		case subtitle_task.match:
			var line = task[2];
			var size = task[4];
			var offset;
			var _duration = source.get_timestamp(task[3], false)-source.get_timestamp(task[1], true);
			
			offset = reference.get_timestamp(line, true) - source.get_timestamp(task[1], true);
			log("source match line "+string(task[1]+1)+"-"+string(task[3]+1)+" with reference "+string(task[2]+1)+"-"+string(task[4]+1));
			if translate==-1
			{
				var _start = reference.get_timestamp(line, true);
				for(var i=line; i<=size; i++)
				{
					var _to = reference.get_timestamp(i, true);
					if (_to-_start)>_duration-time_tolerance break
					
					reference.scroll = clamp(reference.scroll, i-20, i-10);
					var _from = reference.get_timestamp(i, true)-offset;
					var _to = reference.get_timestamp(i, false)-offset;
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
					
					var _to = reference.get_timestamp(i, false);
					if _to-_start>_duration-time_tolerance break;
				}
				_prev = translate.original[min(i,s-1)];
				break
			}			
			
		case subtitle_task.offset:
			//if main.debugging=true break
			var line = 0;
			var time_from = reference.get_timestamp(task[2], true);
			var time_to = reference.get_timestamp(task[4], false);
			
			var t = infinity, _t;
			var s = array_length(translate.lines);
			buffer_seek(translate.timestamp_seek, buffer_seek_start, 0);
			for(var i=0; i<s; i++)
			{
				var time = buffer_read(translate.timestamp_seek, buffer_f32);
				if time>time_from-time_tolerance {line=i; break}
			}
			if line==-1 log("Can't find line for timestamp "+srt_time_stringify(time_from))
			//show_debug_message("At "+srt_time_stringify(task[1])+": Seek timestamp "+srt_time_stringify(task[3])+" found: "+srt_time_stringify(_t)+", line "+string(line)+": "+string(reference.original[line]));
			
			var offset;
			offset = task[5];
			if is_undefined(offset) offset = time_from - source.get_timestamp(task[1], true);		
			var _start = translate.get_timestamp(line, true);	
			for(var i=line; i<s; i++)
			{
				translate.scroll = clamp(translate.scroll, i-20, i-10);
				translate.visual_set_line(i, c_blue);
				
				var _to = translate.get_timestamp(i, true);
				if _to-_start>_duration-time_tolerance break;
				
				var _from = translate.get_timestamp(i, true);
				var _to = translate.get_timestamp(i, false);
				
				var str = translate.original[i];
				if str!=_prev
				{
					file_text_write_string(struct.file, struct.line);
					file_text_writeln(struct.file);
					file_text_write_string(struct.file, srt_time_stringify(_from-offset)+" --> "+srt_time_stringify(_to-offset))
					file_text_writeln(struct.file);
					file_text_write_string(struct.file, str);
					file_text_writeln(struct.file);
					file_text_writeln(struct.file);
					struct.line++;
				}
				_prev = ""
				
				var _to = translate.get_timestamp(i, false);
				if _to-_start>_duration-time_tolerance break;
			}
			_prev = translate.original[min(i,s-1)];
			break
			
		case "legacy":
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