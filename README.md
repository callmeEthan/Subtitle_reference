# Subtitle reference
#### Introduction
Want to share a fan-edit media? but subtitle in your prefered language is not available? Dont have the patience to create and translate subtitle from scratch? This tool will help generate **most** of the subtitle in your language.
> Made in gamemaker, just because

#### Requirement
- Compiled for windows.
- Only support .srt format subtitles, 3 file are required:
	- Subtitle for the edited media, use as a source, provided by the author, in the original language (english).
	- Subtitle for the original/unedited media, to be used as reference, in the same language (english).
	- Translated subtitle for the original/uneditted media, in the preferred language (ie Spanish), it must have timestamps synchornized to the referenced subtitle.

#### How it works?
This tool break all subtitle lines down to arrays of words, then check each word to find matching lines.  
Estimate the editted timestamp offset, then pull lines from translated subtitle to create new subtitle.
#### Usage
Download the latest release, extract and open exe file.
Press (+) to add subtitle files.
- Only 1 source subtitle file are accepted, adding another will replace current data.
- You must add both reference and translated subtitle simultaneously
- You can add more reference and translated subtitle, they will be appended to the current data automatically (Useful for TV->Movie type fan-edit).

Once enough data is provided, you can click arrow button, or [Enter] to begin subtitle matching.  
When matching has finished, you can click the save button, or press [Ctrl+S] to export subtitle file.  
Pressed [F5] to restart application, to process different subtitle.  
> When saving subtitle, it also save to Debugging.txt, this file contain all the line failed to match, retained from the source subtitle. It can be useful for manual fixing/translation.

#### Result
The result may not perfect as there are many factor, the tool mostly do guesswork to tolerate typo, missing words, line mismatch, time sync.   
While not 100% perfect, the ouput can be 80-90% corrects if the provided data is sufficient and accurate.
Some factor to consider:
- Line too short, matching with wrong part.
- Translated line is too long or too short, timing mismatch.
- Different phrasing and grammar causing mismatch (I am vs I'm)
- Typo.
- Edit change the context of the line.
- Line unavailable in the original media (deleted scenes).
- Micro cut, multiple lines are stiched together instead of a whole part.
- ...
**The final human touch will always be required for a perfect subitle.**
