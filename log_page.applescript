(*
	Log Page - Log categorized web page bookmarks to a text file

	Version: @@VERSION@@
	Date:    2011-02-09
	Author:  Steve Wheeler

	Get the title, URL, current date and time, and a user-definable
	category for the frontmost Safari window and log the info to a text
	file.

	This program is free software available under the terms of a
	BSD-style (3-clause) open source license detailed below.
*)

(*
Copyright (c) 2011 Steve Wheeler
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the copyright holder nor the names of
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)

(*
	TODO: Change the following local-only config before any public release.
	The log file should be: $GTD_IN/logs/urls/urls.YYYY.txt
	Or just: $GTD_IN/logs/urls.txt

	TODO: The edit_log() function is currently incomplete. It will only launch
	an editor from the shell and only if that editor is a GUI editor (in this
	case, MacVim). If I release this script publicly, I will still need to
	implement funtionality to launch a GUI editor normally (with the 'open'
	AppleScript commmand) as well as a command-line editor run in the Terminal.
*)

property script_name : "Log Page"
property script_version : "@@VERSION@@"

---------- USER CONFIGURATION ----------------------------------------
-- Default log directory to use if one is not read from config file:
--set log_dir to POSIX path of (path to application support folder from user domain) & "Jazzhead/Log Page/"
set log_dir to POSIX path of (path to desktop folder) & "Log Page/" -- :DEBUG:

-- Log file name:
set log_name to "urls.txt"

-- Default categories/labels if none are found in (or there is no)
-- URL file. Modify as desired:
set default_cats to "Development
Development:AppleScript
Development:AppleScript:Mail
Design
Productivity:GTD
Apple:Mac OS X
Apple:iOS
Career
Education
Health
Health:Diet
Health:Fitness
General"

-- Text editor to use if manually editing the log file.
--
-- This example:
--	1. Opens the file using MacVim ('mvim' as installed by MacPorts)
--	2. Switches the local working directory for just that buffer to the
--	    directory containing the file ('lcd')
--	3. Gives the MacVim window a name ('--servername').
--
set text_editor to "/opt/local/bin/mvim \"+lcd %:p:h\" --servername LOG_PAGE"

-- Should the specified editor be launched from the unix shell?
set should_use_shell to true
---------- END User Configuration ----------------------------------------


---------- ADVANCED (EXPERIMENTAL) ---------------------------------------------
-- For advanced users familiar with the command-line, override the default log
-- directory path. This probably won't be in a public release.
--
-- Grab an exported shell environment variable from a config file to use as the
-- log directory path. For this example, I have a "~/.gtdrc" config file that I
-- source from my "~/.bash_profile" file so that it exportss environment
-- variables relating to my GTD system. That makes those variables available to
-- any of the shell scripts and tools that I use. For instance, when I'm
-- editing files in Vim, I can write paths to other files using one of the
-- environment variables rather than a full or relative path and the 'gf'
-- command will work for jumping to that file. The config file looks like this:
--
--         # ~/.gtdrc
--         #
--         # File locations for GTD documents
--
--         export GTD_DIR=$HOME/Documents/org  # GTD root directory
--         export GTD_IN=$GTD_DIR/content      # source/input files
--         export GTD_OUT=$GTD_DIR/html        # generated HTML output files
--         export GTD_LIB=$GTD_DIR/lib         # code library files
--         export GTD_BIN=$GTD_LIB/script      # scripts
--
-- Remove (or comment out) the "(*" and "*)" comment markers below to use this
-- section. Make sure you also configure the two variables for your system.
--(*
--------------- USER CONFIGURATION ----------
-- Path to your config file:
set cfg_file to POSIX path of (path to home folder) & ".gtdrc"
-- The environment variable you're interested in:
set env_var to "GTD_IN"
--------------- END User Configuration ---------

-- Check for environment variable in config file:
set s to "egrep '\\<" & env_var & "=' " & quoted form of cfg_file & Â
	" > /dev/null 2>&1; echo $?"
set shell_status to (do shell script s) as integer
-- Source the config file and echo the desired variable:
if shell_status is 0 then -- (means that grep found a match)
	set s to ". " & quoted form of cfg_file & " && echo $" & env_var
	set gtd_in_dir to do shell script s
	set log_dir to gtd_in_dir & "/logs/"
	
	--------------------
	-- OPTIONAL: Override the Text editor to integrate with my GTD system.
	--
	-- This example:
	--	1. Opens the file using MacVim ('mvim' as installed by MacPorts)
	--	2. Switches the local working directory ('lcd') for just that buffer to
	--	    my GTD content directory ($GTD_IN after escaping potential spaces)
	--	3. Gives the MacVim window a name ('--servername').
	
	----- First, escape any potential spaces in the directory path:
	--
	--set gtd_in_dir to gtd_in_dir & " foo    bar" -- :DEBUG: spaces in path
	--
	set s to "echo " & quoted form of gtd_in_dir & " | sed 's/ \\{1,\\}/\\\\ /g'" -- escape spaces
	set gtd_in_dir to do shell script s
	--
	--log gtd_in_dir -- :DEBUG: need to use 'log' to see the value w/o AppleScript escapes
	
	----- Finally, set the editor with all of the options:
	--
	set text_editor to "/opt/local/bin/mvim \"+lcd " & gtd_in_dir & "\" --servername GTD --remote-silent"
	--
	--log text_editor -- :DEBUG:
	--return text_editor -- :DEBUG:
	--------------------
end if
---------- END Advanced --------------------------------------------------------
--*)

--return log_dir -- :DEBUG:


--
-- Get URL and title from front browser window
--
tell application "Safari"
	--activate
	try
		set this_url to URL of front document
		set this_title to name of first tab of front window whose visible is true
	on error
		return false
	end try
end tell
-- Transliterate non-ASCII characters to ASCII
set this_title to convert_to_ascii(this_title)

--return this_title -- :DEBUG:

--
-- Format the record separator between log entries
--
set rule_char to "-"
set rule_width to 80
set field_width to 7
set field_sep to " | "
set rec_sep to "" & multiply_text(rule_char, field_width - 1) & Â
	"+" & multiply_text(rule_char, rule_width - field_width)

--
-- Format date-time string as "YYYY-MM-DD HH:MM:SS"
--
set {year:y, month:m, day:d, hours:hh, minutes:mm, seconds:ss} to current date
set m to m as integer -- coerce month string
-- Pad numbers with leading zeros:
set tmp_list to {}
repeat with this_item in {m, d, hh, mm, ss}
	set this_item to text 2 thru -1 of (100 + this_item as text)
	set end of tmp_list to this_item
end repeat
set {m, d, hh, mm, ss} to tmp_list
-- Final string:
set date_time to join_list({y, m, d}, "-") & " " & join_list({hh, mm, ss}, ":")

-- Log file name
--set log_name to "urls." & y & ".txt"

--
-- Create log directory if it doesn't already exist. (Go ahead and use a shell
-- command since it's easy to create intermediate directories all in one step.):
--
try
	set s to "mkdir -pm700 " & quoted form of log_dir
	do shell script s
on error err_msg number err_num
	error "Can't create log directory: " & err_msg number err_num
	return "Fatal Error: Can't create log directory"
end try

set log_file_posix to "" & log_dir & log_name
set log_file to POSIX file log_file_posix


--
-- Add header to new or empty log file
--
set should_init to false
tell application "Finder"
	if (not (exists log_file)) or (_IO's read_file(log_file) is "") then
		set should_init to true
	end if
end tell

set head_sep to multiply_text("#", 80)
if should_init then
	set file_header to head_sep & "
# urls.txt - Timestamped and categorized URL archive
# ==================================================
# Optionally list some categories/labels of URLs below that might not yet
# be used. Any categories/lables listed here or in the web page records
# will be presented as a list to select from when saving new URLs.
" & head_sep & linefeed & default_cats & linefeed & head_sep & "
# END: category/label list
" & head_sep & linefeed
	tell _IO to write_file(log_file, file_header)
	set cat_txt to default_cats
else
	-- Read categories from file
	(*
		:TODO: Error handling.
	*)
	set cat_txt to text 2 thru -2 of (item 3 of split_text(_IO's read_file(log_file), head_sep))
end if

-- Parse any existing labels from the "Label" fields of the URLs file:
set s to "egrep '^Label ' " & quoted form of log_file_posix & Â
	" | sed 's/^Label | //' | sort | uniq"
--return s
set used_cats to do shell script s without altering line endings
-- Sort those along with the manually entered categories/labels:
set s to "echo \"" & cat_txt & linefeed & used_cats & "\" | egrep -v '^$' | sort | uniq"
set cat_txt to do shell script s
-- Coerce the lines into a list:
set cat_list to paragraphs of cat_txt
--return cat_list -- :DEBUG:


--
-- Prompt for category/subcategory of URL
--

-- Select an existing category
set msg to "Please select a category for the URL you want to log. You will have a chance to edit your choice."
set cat_choice to choose from list cat_list with title script_name with prompt msg OK button name "Select"
--if cat_choice is false then return false
if cat_choice is false then set cat_choice to "Please enter a category..."

-- Modify or enter a new category
set btns to {"Cancel", "Manually Edit Log File", "Append URL to Log File"}
set msg to "To log the URL for:" & return & return Â
	& tab & "\"" & this_title & "\"" & return & return & Â
	"please provide a category and any optional subcategories (or edit your selected category) for the URL. Example: \"Development:AppleScript:Mail\""
display dialog msg default answer cat_choice with title script_name buttons btns default button last item of btns
set {this_label, btn_pressed} to {text returned of result, button returned of result}

--
-- Append or edit the log file
--
if btn_pressed is last item of btns then
	set final_text to join_list({Â
		"Date " & field_sep & date_time, Â
		"Label" & field_sep & this_label, Â
		"Title" & field_sep & this_title, Â
		"URL  " & field_sep & this_url, Â
		rec_sep}, linefeed) & linefeed
	_IO's append_file(log_file, final_text)
else
	if should_use_shell then
		set this_log_file to quoted form of log_file_posix
	else
		set this_log_file to log_file
	end if
	edit_log(this_log_file, text_editor, should_use_shell)
end if

--display alert "Log Page" message "DEBUG: Script complete."


(************************************************************
 *	Subroutines
 ************************************************************)

-- ===== Main Functions =====

on edit_log(log_file, text_editor, should_use_shell)
	(*
		TODO:MAYBE:
		Have a configuration variable in the main script to specify which text
		editor to use. Have another variable for configuring whether or not
		it's a GUI application. Then this function would use 'open' to launch a
		GUI app or script the Terminal to launch a command-line editor.
		Optionally use 'do shell script' to launch a compatible GUI app from a
		command line (so that the working directory can be changed to that of
		the file first), but I don't know if that will really be necessary
		since I have a Vim shortcut for quickly changing the working directory
		if need be.
	*)
	if should_use_shell then
		set s to text_editor & space & log_file & space & "> /dev/null 2>&1"
		do shell script s
		return
	else
		set t to script_name
		set m to ":TODO: edit_log() function: use non-shell-invoked editor."
		set b to {"Cancel"}
		display alert t message m buttons b cancel button 1 as critical
		return false
	end if
end edit_log

-- ===== Utility Functions =====

on convert_to_ascii(non_ascii_txt)
	set s to "iconv -f UTF-8 -t US-ASCII//TRANSLIT <<<" & quoted form of non_ascii_txt
	do shell script s
end convert_to_ascii

on multiply_text(str, n)
	if n < 1 or str = "" then return ""
	set lst to {}
	repeat n times
		set end of lst to str
	end repeat
	return lst as string
end multiply_text

on split_text(txt, delim)
	set old_tids to AppleScript's text item delimiters
	try
		set AppleScript's text item delimiters to (delim as string)
		set lst to every text item of (txt as string)
		set AppleScript's text item delimiters to old_tids
		return lst
	on error err_msg number err_num
		set AppleScript's text item delimiters to old_tids
		error "Can't split_text(): " & err_msg number err_num
	end try
end split_text

on join_list(lst, delim)
	set old_tids to AppleScript's text item delimiters
	try
		set AppleScript's text item delimiters to (delim as string)
		set txt to lst as string
		set AppleScript's text item delimiters to old_tids
		return txt
	on error err_msg number err_num
		set AppleScript's text item delimiters to old_tids
		error "Can't join_list(): " & err_msg number err_num
	end try
end join_list

(************************************************************
 *	Script Objects
 ************************************************************)

script _IO
	
	(* == PUBLIC == *)
	
	on write_file(file_path, this_data)
		_write_file(file_path, this_data, string, false) -- overwrite existing file
	end write_file
	
	on append_file(file_path, this_data)
		_write_file(file_path, this_data, string, true) -- append new data to end of existing file
	end append_file
	
	on read_file(file_path)
		_read_file(file_path, string)
	end read_file
	
	(* == PRIVATE == *)
	
	on _write_file(file_path, this_data, data_class, should_append_data)
		try
			set file_path to file_path as text
			set file_handle to Â
				open for access file file_path with write permission
			if not should_append_data then Â
				set eof of the file_handle to 0
			write this_data as data_class to file_handle starting at eof
			close access file_handle
			return true
		on error err_msg number err_num
			try
				close access file file_path
			end try
			error err_msg number err_num
			return false
		end try
	end _write_file
	
	on _read_file(file_path, data_class)
		try
			set file_path to file_path as text
			if (get eof file file_path) is 0 then
				set file_contents to ""
			else
				set file_contents to read file file_path as data_class
			end if
			return file_contents
		on error
			return 0
		end try
	end _read_file
end script
