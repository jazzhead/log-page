(*
	Log Page - Log categorized web page bookmarks to a text file

	Version: @@VERSION@@
	Date:    2012-12-21
	Author:  Steve Wheeler

	Get the title, URL, current date and time, and a user-definable
	category for the frontmost Safari window and log the info to a text
	file.

	This program is free software available under the terms of a
	BSD-style (3-clause) open source license detailed below.
*)

(*
Copyright (c) 2011-2012 Steve Wheeler
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

property p_list_types : {"top", "sub", "all"}

global g_top_categories, g_all_categories, g_previous_categories
global g_list_type, g_previous_list_type
global g_prompt_count, g_prompt_total

set g_list_type to missing value
set g_previous_list_type to missing value


-- Unicode characters for list dialogs
property uRule : Çdata utxt2500È as Unicode text -- BOX DRAWINGS LIGHT HORIZONTAL

--property uBullet : Çdata utxt25B6È as Unicode text -- BLACK RIGHT-POINTING TRIANGLE
--property uBullet : Çdata utxt27A1È as Unicode text -- BLACK RIGHTWARDS ARROW
--property uBullet : "¥"
--property uBullet : Çdata utxt25CFÈ as Unicode text -- BLACK CIRCLE
--property uBullet : Çdata utxt2043È as Unicode text -- HYPHEN BULLET
property uBullet : Çdata utxt25A0È as Unicode text -- BLACK SQUARE

--property uBack : Çdata utxt25C0È as Unicode text -- BLACK LEFT-POINTING TRIANGLE
property uBack : Çdata utxt2B05È as Unicode text -- LEFTWARDS BLACK ARROW



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
--         #
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
" & head_sep & linefeed & default_categories & linefeed & head_sep & "
# END: category/label list
" & head_sep & linefeed
	tell _IO to write_file(log_file, file_header)
	set all_category_txt to default_categories
else
	-- Read categories from file
	(*
		:TODO: Error handling.
	*)
	set all_category_txt to text 2 thru -2 of (item 3 of split_text(_IO's read_file(log_file), head_sep))
end if

-- Parse any existing labels from the "Label" fields of the URLs file:
set s to "LANG=C sed -n 's/^Label | //p' " & quoted form of log_file_posix & " | sort | uniq"
--return s
set categories_used to do shell script s without altering line endings
-- Sort those along with the manually entered categories/labels:
set s to "echo \"" & all_category_txt & linefeed & categories_used & "\" | egrep -v '^$' | sort | uniq"
set all_category_txt to do shell script s without altering line endings
--return all_category_txt -- :DEBUG:
-- Coerce the lines into a list:
set g_all_categories to paragraphs of all_category_txt
if g_all_categories's last item is "" then set g_all_categories to g_all_categories's items 1 thru -2
--return g_all_categories -- :DEBUG:

-- Get top-level categories:
set s to "LANG=C echo \"" & all_category_txt & "\" | sed -n 's/^\\([^:]\\{1,\\}\\).*/\\1/p' | uniq"
set top_category_txt to do shell script s without altering line endings
--return top_category_txt -- :DEBUG:
-- Coerce the lines into a list:
set g_top_categories to paragraphs of top_category_txt
if g_top_categories's last item is "" then set g_top_categories to g_top_categories's items 1 thru -2
--return g_top_categories -- :DEBUG:

--
-- Prompt for title, category/subcategories and optional note for URL
--

-- The number of dialog prompts will vary depending on if a subcategory list is requested.
set g_prompt_count to 1 -- increment with every dialog or list prompt, decrement if going back
set g_prompt_total to 4 -- increment if sub/full lists are displayed, decrement if going back

-- Accept or modify URL title
set b to {"Manually Edit Log File", "Cancel", "Next..."}
set t to "" & script_name & ": Title (" & g_prompt_count & "/" & g_prompt_total & ")"
set m to "To log the URL for:" & return & return Â
	& tab & "\"" & this_title & "\"" & return & return & Â
	"first accept or edit the title."
display dialog m default answer this_title with title t buttons b default button last item of b cancel button second item of b with icon note
set {this_title, btn_pressed} to {text returned of result, button returned of result}
set g_prompt_count to g_prompt_count + 1
if btn_pressed is first item of b then
	if should_use_shell then
		set this_log_file to quoted form of log_file_posix
	else
		set this_log_file to log_file
	end if
	edit_log(this_log_file, text_editor, should_use_shell)
	return "Script ended with '" & (first item of b as text) & "'"
end if

-- Select a category
set chosen_category to choose_category(g_top_categories, "top")
if chosen_category is false then error number -128 -- User canceled

-- Get the info so far:
set cur_info to "TITLE:" & tab & tab & this_title & return & "URL:" & tab & tab & this_url

-- Modify selected category or enter a new category
set t to "" & script_name & ": Category (" & g_prompt_count & "/" & g_prompt_total & ")"
set m to cur_info & return & return & "Please provide a category and any optional subcategories (or edit your selected category) for the URL. Example: \"Development:AppleScript:Mail\""
repeat --10 times -- limit loops as a precaution during development
	display dialog m default answer chosen_category with title t buttons b default button last item of b cancel button second item of b with icon note
	set {this_label, btn_pressed} to {text returned of result, button returned of result}
	if this_label is not "" then
		exit repeat
	else
		display alert "Category required" message "Please supply a category for the URL." as warning
	end if
end repeat
set g_prompt_count to g_prompt_count + 1

-- Update the info:
set cur_info to cur_info & return & "CATEGORY:" & tab & this_label

-- Optionally add note
if btn_pressed is last item of b then
	set last item of b to "Append URL to Log File"
	set t to "" & script_name & ": Note (" & g_prompt_count & "/" & g_prompt_total & ")"
	set m to cur_info & return & return & "Optionally add a short note. Just leave the field blank if you don't want to add a note."
	display dialog m default answer "" with title t buttons b default button last item of b with icon note
	set {this_note, btn_pressed} to {text returned of result, button returned of result}
end if

--
-- Append or edit the log file
--
if btn_pressed is last item of b then
	set final_text to join_list({Â
		"Date " & field_sep & date_time, Â
		"Label" & field_sep & this_label, Â
		"Title" & field_sep & this_title, Â
		"URL  " & field_sep & this_url}, linefeed) & linefeed
	if this_note is not "" then
		set final_text to final_text & "Note " & field_sep & this_note & linefeed
	end if
	set final_text to final_text & rec_sep & linefeed
	--return "[DEBUG]" & return & final_text
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

----- Dialog Views

on choose_category(cur_list, cur_list_type)
	--log "[debug] in choose_category(_list_, \"" & cur_list_type & "\")"
	
	if cur_list_type is not in p_list_types then
		set t to "Error: Bad list type"
		set m to "choose_category():  The supplied list type parameter, '" & cur_list_type & "', is not a valid list type from the 'p_list_types' property. Please report this bug to the developer."
		-- This bug is probably the result of a typo in the recursive section below.
		display alert t message m buttons {"Cancel"} cancel button 1 as critical
	end if
	
	if cur_list_type is not "all" then copy cur_list to g_previous_categories
	
	--log "[debug] g_previous_categories: " & joinList(g_previous_categories, ", ")
	
	set_list_type(cur_list_type) -- set global current and previous list types
	
	--
	-- Configure the non-category navigation selections for the category list dialogs
	--
	set extra_items to get_extra_items(cur_list_type)
	set list_rule to extra_items's last item
	
	--
	-- Customize list dialog properties
	--
	set t to "" & script_name & ": Category (" & g_prompt_count & "/" & g_prompt_total & ")"
	if cur_list_type is "top" then
		set m to "Please select a top-level category for the URL you want to log. Next you will be able to select subcategories unless you are creating a new category."
	else if cur_list_type is in {"sub", "all"} then
		set m to "Please select a category or subcategory for the URL you want to log. You will have a chance to edit your choice (to add a new category or subcategory)."
	end if
	set b to "Next..."
	
	--
	-- Prompt the user for category and/or subcategory choices
	--
	repeat --10 times -- limit loops as a precaution during development
		set chosen_category to choose from list extra_items & cur_list with title t with prompt m OK button name b
		if chosen_category as text is not list_rule then
			exit repeat
		else
			display alert "Invalid selection" message "Please select a category or an action." as warning
		end if
	end repeat
	if chosen_category is false then return false
	
	--
	-- Call this handler recursively if another list was requested.
	-- When specifying a 'cur_list_type' parameter to choose_category(), make
	-- sure it is one of the allowed types from the 'p_list_types' property.
	--
	if cur_list_type is in {"top", "sub"} and chosen_category as text is extra_items's first item then
		--log "[debug] incrementing both prompt count and total"
		set g_prompt_count to g_prompt_count + 1
		set g_prompt_total to g_prompt_total + 1
		--log "[debug] recurse to choose_category(g_all_categories, \"all\")"
		set chosen_category to choose_category(g_all_categories, "all")
	else if cur_list_type is "sub" and chosen_category as text is extra_items's second item then
		--log "[debug] decrementing both prompt count and total"
		set g_prompt_count to g_prompt_count - 1
		set g_prompt_total to g_prompt_total - 1
		--log "[debug] recurse to choose_category(g_top_categories, \"top\")"
		set chosen_category to choose_category(g_top_categories, "top")
	else if cur_list_type is "all" and chosen_category as text is extra_items's first item then
		--log "[debug] decrementing both prompt count and total"
		set g_prompt_count to g_prompt_count - 1
		set g_prompt_total to g_prompt_total - 1
		if g_previous_list_type is "sub" then
			--log "[debug] recurse to choose_category(g_previous_categories, \"sub\")"
			set chosen_category to choose_category(g_previous_categories, "sub")
		else if g_previous_list_type is "top" then
			--log "[debug] recurse to choose_category(g_top_categories, \"top\")"
			set chosen_category to choose_category(g_top_categories, "top")
		end if
	else if cur_list_type is "top" and chosen_category as text is extra_items's second item then
		set g_prompt_count to g_prompt_count + 1
		return ""
	else if cur_list_type is "top" then
		set sub_categories to get_subcategories(chosen_category)
		--log "[debug] incrementing both prompt count and total"
		set g_prompt_count to g_prompt_count + 1
		set g_prompt_total to g_prompt_total + 1
		--log "[debug] recurse to choose_category(sub_categories, \"sub\")"
		set chosen_category to choose_category(sub_categories, "sub")
	else
		--log "[debug] incrementing prompt count"
		set g_prompt_count to g_prompt_count + 1
	end if
	
	return chosen_category
end choose_category

on get_subcategories(chosen_category)
	set sub_categories to {}
	repeat with this_cat in g_all_categories
		if (this_cat as text) is (chosen_category as text) Â
			or (this_cat as text) starts with (chosen_category & ":") then
			set end of sub_categories to this_cat as text
		end if
	end repeat
	return sub_categories
end get_subcategories

on set_list_type(cur_type)
	set g_previous_list_type to g_list_type
	set g_list_type to cur_type
end set_list_type

on get_extra_items(list_type)
	if list_type is "top" then
		return {Â
			" " & uBullet & "  Show full list with subcategoriesÉ", Â
			" " & uBullet & "  Create a new category...", Â
			multiplyTxt(uRule, 20)}
	else if list_type is "sub" then
		return {Â
			" " & uBullet & "  Show full list of categories...", Â
			uBack & "  Go back to previous list...", Â
			multiplyTxt(uRule, 35)}
	else if list_type is "all" then
		return {Â
			uBack & "  Go back to previous list...", Â
			multiplyTxt(uRule, 35)}
	else
		return false
	end if
end get_extra_items

----- External Views

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
	--
	-- From 'man iconv_open':
	--
	--    When  the string "//TRANSLIT" is appended to tocode, transliteration is
	--    activated. This means that when a character cannot  be  represented  in
	--    the target character set, it can be approximated through one or several
	--    characters that look similar to the original character.
	--
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
