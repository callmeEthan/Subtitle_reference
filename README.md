# Subtitle cross-reference tool
![alt text]([http://url/to/img.png](https://github.com/callmeEthan/Subtitle_reference/blob/main/thumb.jpg?raw=true))
### Introduction
Want to share a fan-edit media? but subtitle in your prefered language is not available? Dont have the patience to create and translate subtitle from scratch? This tool will help generate **most** of the subtitle in your language.
> Made in gamemaker, just because

> This is a proof of concept that I hastily put together in the span of 2 days, while the overal result are good, someone with better coding skill might be able to create something better (audio recognition, fuzzy string matching, AI,...) and yield better result.

### Requirement
- Compiled for windows.
- Only support .srt format subtitles, 3 file are required:
	- Subtitle for the edited media, use as **Source**, provided by the author, in the original language (english).
	- Subtitle for the original/unedited media, to be used as **Reference**, in the same language (english).
	- **Translated** subtitle for the original/uneditted media, in the preferred language (ie Spanish), it must have timestamps synchornized to the **reference** subtitle.

### How it works?
This tool break all subtitle lines down to arrays of words, then compare each word to find matching lines.  
Estimate the editted timestamp offset, then pull lines from translated subtitle to create new subtitle.
> This tool pull line from translated subtitle, it does not perform any translation, any new line not available in original media (restored deleted scene) will not be translated and will retain from source subtitle.

### Usage
Download the latest release, extract and open exe file.
Press (+) to add subtitle files.
- Only 1 **Source** subtitle file are accepted, adding another will replace current data.
- You must add both **Reference** and **Translated** subtitle simultaneously
- You can add more **Reference** and **Translated** subtitle, they will be appended to the current data automatically (Useful for TV->Movie type fan-edit).

Once enough data is provided, you can click arrow button, or press [Enter] key to begin subtitle matching.  
When matching has finished, you can click the save button, or press [Ctrl+S] to export subtitle file.  
Pressed [F5] to restart application, flush all current data.  
> When saving subtitle, it also save to Debugging.txt, this file contain all the line failed to match, retained from the source subtitle. It can be useful for manual fixing/translation.

### Result
The result may not be perfect as there are many factor, the tool mostly do guesswork to tolerate typo, missing words, line mismatch, time sync.     
Some factor to consider:
- Line too short, matching with wrong part.
- Translated line is too long or too short, timing mismatch.
- Different phrasing and grammar causing mismatch (I am vs I'm)
- Typo.
- Fan-edit change the context of the line.
- Line is unavailable in the original media (deleted scenes).
- Micro cuts, multiple lines are stiched together instead of a whole part.
- ...

### The final human touch will always be required for a perfect subitle.
While not 100% perfect, if the provided data is sufficient and accurate, 80-90% of subitle will be generated for you.  
Recommend using tool such as [SubtitleEdit](https://github.com/SubtitleEdit/subtitleedit/releases) to finish your subtitle:  
- Timing overlapse.  
- Untranslated line.  
