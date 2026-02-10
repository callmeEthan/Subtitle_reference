/* Source: github.com/kartik1998/phonetics/
Simple script for indexing words by their English pronunciation, use in my subitle matching tool.
Example:
	metaphone("energize") returns "ENRJS"
	metaphone("holidays") returns "HLTS"
	metaphone("download") returns "TNLT"
*/


function string_to_metaphone() constructor
{
	text = "";
	sh = "X";
	th = "0";
	phonized = "";
	index = 0;
	skip = 0;
	size = 0;

	static word = function(text)
	{
		self.text=string_upper(text);
		index=0;
		phonized=""
		size = string_length(text);
		skip = 0;
		return get_phonic();
	}
	static phonize = function(characters)
	{
		phonized += characters;
	}

	static at = function(pos)
	{
		if pos<0 || pos>=size return "";
		return string_char_at(self.text, pos+1);
	}
	static next = function() {return at(index+1)}
	static previous = function() {return at(index-1)}
	static current = function() {return at(index)}

	static char = function(character) {
	  return string_upper(character);
	}
	static charCode = function(character) {
	  return ord(character)
	}
	
	static noGhToF = function(character) {
	  character = char(character);

	  if (character == "B" || character == "D" || character == "H") return true else return false;
	}
	static soft = function(character) {
	  character = char(character);
	  if (character == "E" || character == "I" || character == "Y") return true else return false;
	}
	static vowel = function(character) {
	  character = char(character);

	  if (character == "A" || character == "E" || character == "I" || character == "O" || character == "U") return true else return false;
	}
	static dipthongH = function(character) {
	  character = char(character);

	  if (character == "C" || character == "G" || character == "P" || character == "S" || character == "T") return true else return false;
	}
	static alpha = function(character) {
	  var code = charCode(character);
	  if code >= 65 && code <= 90 return true else return false;
	}

	static get_phonic = function()
	{
	  switch (current()) {
	    case "A":
	      if (next() == "E") {
	        phonize("E");
	        index += 2;
	      } else {
	        phonize("A");
	        index++;
	      }

	      break;
	    case "G":
	    case "K":
	    case "P":
	      if (next() == "N") {
	        phonize("N");
	        index += 2;
	      }

	      break;

	    case "W":
	      if (next() == "R") {
	        phonize(next());
	        index += 2;
	      } else if (next() == "H") {
	        phonize(current());
	        index += 2;
	      } else if (vowel(next())) {
	        phonize("W");
	        index += 2;
	      }

	      break;
	    case "X":
	      phonize("S");
	      index++;

	      break;
	    case "E":
	    case "I":
	    case "O":
	    case "U":
	      phonize(current());
	      index++;
	      break;
	    default:
	      break;
	  }

	  while (index<size) {
	    skip = 1;

	    if (!alpha(current()) || (current() == previous() && current() != "C")) {
	      index += skip;
	      continue;
	    }

	    switch (current()) {
	      case "B":
	        if (previous() != "M") {
	          phonize("B");
	        }

	        break;
	      case "C":
	        if (soft(next())) {
	          if (next() == "I" && at(2) == "A") {
	            phonize(sh);
	          } else if (previous() != "S") {
	            phonize("S");
	          }
	        } else if (next() == "H") {
	          phonize(sh);
	          skip++;
	        } else {
	          phonize("K");
	        }

	        break;
	      case "D":
	        if (next() == "G" && soft(at(2))) {
	          phonize("J");
	          skip++;
	        } else {
	          phonize("T");
	        }

	        break;
	      case "G":
	        if (next() == "H") {
	          if (!(noGhToF(at(-3)) || at(-4) == "H")) {
	            phonize("F");
	            skip++;
	          }
	        } else if (next() == "N") {
	          if (!(!alpha(at(2)) || (at(2) == "E" && at(3) == "D"))) {
	            phonize("K");
	          }
	        } else if (soft(next()) && previous() != "G") {
	          phonize("J");
	        } else {
	          phonize("K");
	        }

	        break;

	      case "H":
	        if (vowel(next()) && !dipthongH(previous())) {
	          phonize("H");
	        }

	        break;
	      case "K":
	        if (previous() != "C") {
	          phonize("K");
	        }

	        break;
	      case "P":
	        if (next() == "H") {
	          phonize("F");
	        } else {
	          phonize("P");
	        }

	        break;
	      case "Q":
	        phonize("K");
	        break;
	      case "S":
	        if (next() == "I" && (at(2) == "O" || at(2) == "A")) {
	          phonize(sh);
	        } else if (next() == "H") {
	          phonize(sh);
	          skip++;
	        } else {
	          phonize("S");
	        }

	        break;
	      case "T":
	        if (next() == "I" && (at(2) == "O" || at(2) == "A")) {
	          phonize(sh);
	        } else if (next() == "H") {
	          phonize(th);
	          skip++;
	        } else if (!(next() == "C" && at(2) == "H")) {
	          phonize("T");
	        }

	        break;
	      case "V":
	        phonize("F");
	        break;
	      case "W":
	        if (vowel(next())) {
	          phonize("W");
	        }

	        break;
	      case "X":
	        phonize("KS");
	        break;
	      case "Y":
	        if (vowel(next())) {
	          phonize("Y");
	        }

	        break;
	      case "Z":
	        phonize("S");
	        break;
	      case "F":
	      case "J":
	      case "L":
	      case "M":
	      case "N":
	      case "R":
	        phonize(current());
	        break;
	    }

	    index += skip;
	  }

	  return phonized;
	}
}
function metaphone(word)
{
	static strct = new string_to_metaphone();
	return strct.word(word);
}