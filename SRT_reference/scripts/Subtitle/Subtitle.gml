globalvar match_tolerance, match_list,match_minimum, match_maximum, time_tolerance, fuzzy_match;
match_tolerance = 3;
match_list = ds_priority_create();
match_minimum = 5;	// If only match 5 words or less, then not considered as matched
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
			main.progress="Matching line "+string(struct.line)+" of "+string(struct.size)+" [c_orange]("+string(round(struct.line/struct.size*100))+"%)"
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
			source.scroll = clamp(source.scroll, pos-24, pos-16);
			pos = reference.word_get_line(struct.index2);
			reference.scroll = clamp(reference.scroll, pos-24, pos-16);
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
			log("Press [c_lime]Ctrl + D[/] to save [b]lines failed to match only[/], useful for manual fixing.");
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
		if index-ind<ceil(match_tolerance/2)
		{
			struct.matched[1]-=ceil(match_tolerance/2);
			struct.matched[3]-=ceil(match_tolerance/2);
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
	var line2 = source.word_get_line(struct.index1);
	var time1 = source.get_timestamp(line1, true);
	var time2 = source.get_timestamp(line2, false);
	
	line1 = reference.word_get_line(struct.matched[2]);
	line2 = reference.word_get_line(struct.index2);
	var time3 = reference.get_timestamp(line1, true);
	var time4 = reference.get_timestamp(line2, true);
	
	time4 -= time3-time1;
	if time4>time2+time_tolerance return false;
	return true;
}
function add_timestamp(source, reference, match)
{
	var time = array_create(6);
	var line1 = source.word_get_line(match[0]);
	var line2 = source.word_get_line(match[1]);
	time[@1] = source.get_timestamp(line1, true);
	time[@2] = source.get_timestamp(line2, false);
	
	line1 = reference.word_get_line(match[2]);
	line2 = reference.word_get_line(match[3]);
	time[@3] = reference.get_timestamp(line1, true);
	time[@4] = reference.get_timestamp(line2, false);
	
	time[@0] = subtitle_task.offset;
	time[@5] = undefined;
	ds_list_add(main.task, time);
}
function get_time_start()
{
	
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
	
	var struct = 
	{
		source: source,
		reference: translate,
		file: file,
		filename: filename,
		line: 1,
		task: 0,
		size: ds_list_size(main.task)
	}
	return struct;
}
function srt_generate(struct)
{
	if struct.task>=struct.size
	{
		if file_text_close(struct.file) {log("Saved to [c_yellow]"+string(struct.filename))} else {log("[c_red]Failed to write to "+string(struct.filename))}
		main.generating=-1;
		main.progress=-1;
		return false;
	}
	
	main.progress="Generating subtitle, task "+string(struct.task)+" of "+string(struct.size)+" [c_orange]("+string(round(struct.task/struct.size*100))+"%)"
	var task = main.task[| struct.task];
	struct.task++;
	
	var source = struct.source;
	var reference = struct.reference;
	switch(task[0])
	{
		case subtitle_task.retain:
			var line = task[1];
			var time1 = source.get_timestamp(line, true);
			var time2 = source.get_timestamp(line, false);
			
			file_text_write_string(struct.file, struct.line);
			file_text_writeln(struct.file);
			file_text_write_string(struct.file, srt_time_stringify(time1)+" --> "+srt_time_stringify(time2))
			file_text_writeln(struct.file);
			file_text_write_string(struct.file, source.original[line]);
			file_text_writeln(struct.file);
			file_text_writeln(struct.file);
			struct.line+=1;
			break;
			
		case subtitle_task.offset:
			if main.debugging=true break
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
			
			var offset = (task[3]+task[4])/2-(task[1]+task[2])/2;
			for(var i=line; i<s; i++)
			{
				reference.scroll = clamp(reference.scroll, i-24, i-16);
				reference.visual_set_line(i, word_color.blue);
				var _from = reference.get_timestamp(i, true)-offset;
				var _to = reference.get_timestamp(i, false)-offset;
				if _from>task[2]-time_tolerance break;
				
				file_text_write_string(struct.file, struct.line);
				file_text_writeln(struct.file);
				file_text_write_string(struct.file, srt_time_stringify(_from)+" --> "+srt_time_stringify(_to))
				file_text_writeln(struct.file);
				file_text_write_string(struct.file, reference.original[i]);
				file_text_writeln(struct.file);
				file_text_writeln(struct.file);
				struct.line++;
				
				if _to>task[2]-time_tolerance break;
			}
			break
	}
	return true;
}
