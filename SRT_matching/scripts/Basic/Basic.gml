function log(text)
{
	show_debug_message(text)
	//main.debug = main.debug+"\n"+string(text)
	ds_list_add(main.debug, text);
	if ds_list_size(main.debug)>8 ds_list_delete(main.debug, 0);
}


function string_compare(string1, string2, ngram=3)
{
	// Simple fuzzy string comparision, allow to typo tolerance, string length must be longer than ngram
	// return a value between 0 to 1, with 1 being perfect match and vice versa
	if string_length(string1)<=ngram || string_length(string2)<=ngram
	{
		if string1==string2 return 1 else return 0;
	}
	
	var _score=0;
	var _max=max(string_length(string1), string_length(string2))-ngram;
	var s = string_length(string1)-ngram;
	for(var i=1; i<=s+1; i++)
	{
		var match = string_copy(string1, i, ngram);
		if string_pos(match, string2)>0 _score++
	}
	return _score/_max;
}