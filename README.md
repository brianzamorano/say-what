### Description
Convert your epub/mobi/pdf/txt files to MP3 for "reading" on the go! (Mac OSX only)

### Requirements
Links for install provided for Calibre & Lame.
* [Calibre](https://calibre-ebook.com/download_osx) - Ebook Management and Conversion Tool
* [Lame](https://gist.github.com/trevorsheridan/1948448) - Open Source Mp3 Encoder
* [Mac OSX] - Say What requires Mac OSX's TTS "say" command line tool

### Parameters
* -f     **MANDATORY**: provide FILE to convert into an "audiobook"
* -s    Indicates a starting point for your "audiobook". When using this option, please enter your text between two quotation " marks. 
* -r    Sets the reading speed (default value is 260) - Recommended values are between 250-300.
* -h    Prints out this usage message summarizing these command-line options, then exits

### Sample Usage
$ ./say-what.sh -f "EBOOK.mobi" -r 275 -s "Perry sat on the couch"

### Notes
PDF support is iffy-at best unless it is primarily text but give it a shot!

### TODO: 
* Better error handling
* Add Linux support
