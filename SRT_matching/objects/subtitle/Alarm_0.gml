/// @description Import srt subtitle
pending = -1;
repeat(import_speed)
{
	var text = file_text_read_string(file);

	switch(format)
	{
		default:
			if text=="" break;
			if line_index<0 line_index=0 else line_index++;
			format=1;
			scroll = line_index;
			break
	
		case 1:
			if string_pos(" --> ", text)
			{
				var time = string_split(text, " --> ");
				time_from = srt_parse_time(time[0])+offset;
				time_to = srt_parse_time(time[1])+offset;
			}
			str="";
			format=2;
			break
		
		case 2:
			if text=""		// END OF LINE
			{
				format=0;
				array_push(original, str);
				string_process(str);
				buffer_write(timestamp, buffer_f32, time_from);
				buffer_write(timestamp, buffer_f32, time_to);
				buffer_write(timestamp_seek, buffer_f32, time_from);
				duration = max(duration, time_to, time_from);
				size++
				break;
			}
			if str="" str=text else str=str+"\n"+text;
			break
	}
	file_text_readln(file)
	if file_text_eof(file) {file_text_close(file); exit}
}
if !file_text_eof(file) alarm[0]=1 else file_text_close(file)