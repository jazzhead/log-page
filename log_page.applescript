(*
	Log Page - Log categorized web page bookmarks to a text file

	Version: @@VERSION@@
	Date:    2013-01-04
	Author:  Steve Wheeler

	Get the title, URL, current date and time, and a user-definable
	category for the frontmost Safari window and log the info to a text
	file.

	Optionally, open the text file in the text editing application of
	your choice.

	This program is free software available under the terms of a
	BSD-style (3-clause) open source license detailed below.
*)

(*
Copyright (c) 2011-2013 Steve Wheeler
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
	TODO: The edit_log() function should also support opening the text
	file in a command-line editor run in the Terminal.
*)


(*==== Init ====*)

set io_obj to make_io() -- Instantiate an object for read/write/append file operations
--set io_obj to make_null_io() -- :DEBUG: don't write to file; just read

---- properties and globals ----

property script_name : "Log Page"
property script_version : "@@VERSION@@"
property bundle_id : "net.jazzhead.scpt.Safari.LogPage"

property p_list_types : {"top", "sub", "all"}

global g_top_categories, g_all_categories, g_previous_categories
global g_list_type, g_previous_list_type
global g_prompt_count, g_prompt_total

set g_list_type to missing value
set g_previous_list_type to missing value


---- Unicode characters for list dialogs ----

property u_dash : Çdata utxt2500È as Unicode text -- BOX DRAWINGS LIGHT HORIZONTAL

property u_bullet : Çdata utxt25CFÈ as Unicode text -- BLACK CIRCLE
--property u_bullet : "¥" -- standard bullet, but slightly smaller than Unicode black circle
--property u_bullet : Çdata utxt2043È as Unicode text -- HYPHEN BULLET
--property u_bullet : Çdata utxt25A0È as Unicode text -- BLACK SQUARE
--property u_bullet : Çdata utxt25B6È as Unicode text -- BLACK RIGHT-POINTING TRIANGLE
--property u_bullet : Çdata utxt27A1È as Unicode text -- BLACK RIGHTWARDS ARROW

property u_back : Çdata utxt276EÈ as Unicode text -- HEAVY LEFT-POINTING ANGLE QUOTATION MARK ORNAMENT
-- property u_back : Çdata utxt25C0È as Unicode text -- BLACK LEFT-POINTING TRIANGLE
--property u_back : Çdata utxt2B05È as Unicode text -- LEFTWARDS BLACK ARROW
-- (A smaller black left-pointing triangle or a slightly more angled heavy left-pointing angle quotation mark ornament would be better. The leftwards black arrow just doesn't seem Mac-like.)

-- Format for dialogs
property u_bullet_ls : missing value -- for list items
property u_back_ls : missing value -- for list items
property u_back_btn : missing value -- for buttons
set u_bullet_ls to " " & u_bullet & "  "
set u_back_ls to " " & u_back & "  "
set u_back_btn to "" & u_back & "  "


---- Preferences ----

--set plist_dir to POSIX path of (path to preferences from user domain)
set plist_dir to "~/Desktop/Test Folder/Preferences/" -- :DEBUG:TEMP:

set plist_path to plist_dir & bundle_id & ".plist"
set plist_keys to {"logFile", "textEditor"}
set state_keys to {"lastMainLabel", "lastFullLabel"}

--set default_file to POSIX path of (path to application support folder from user domain) & "Jazzhead/Log Page/urls.txt"
set default_file to POSIX path of (path to desktop folder from user domain) & "Test Folder/App Support/Log Page/urls.txt" -- :DEBUG:TEMP:

set default_editor to "TextEdit"


---- Sample categories for URL file ----

-- Default categories/labels if none are found in (or there is no) URL file.
-- (These can be edited or deleted afterwards in the URL file).
--
-- :TODO: These should only be written to new URL files where they can be
--     later deleted. They should NOT be included in every list dialog. Maybe
--     change the name of this variable to 'sample_categories'.
--
set default_categories to "Development
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


(*==== Read preferences ====*)

--
-- Instantiate an object to store the preferences.
--
set settings_model to make_settings_model(plist_path, default_file, default_editor)
try
	settings_model's read_settings(plist_keys)
on error err_msg number err_num
	--error "DEBUG: " & err_msg number err_num
	set settings_model to do_first_run(settings_model)
end try

--
-- Get the needed settings from the model
--
tell settings_model
	set log_file to get_item("logFile")
	set text_editor to get_item("textEditor")
end tell

display dialog log_file & return & return & text_editor with title "DEBUG"
--return "[debug] BREAK"

--
-- Expand '~/' or '$HOME/' at the beginning of a posix file path.
--
set log_file to expand_home_path(log_file)

--
-- Get a mac file path for file IO and editing
--
set log_file_mac to POSIX file log_file

--
-- Create any directories needed in the web page log file path
--
create_directory(first item of split_path_into_dir_and_file(log_file))

--return "[debug] BREAK"


(*
==================================================
    Main
==================================================
*)

(*==== Get web page info ====*)

--
-- Get URL and title from front browser window
--
tell application "Safari"
	activate
	try
		set this_url to URL of front document
		set this_title to name of first tab of front window whose visible is true
		--error "DEBUG: throw an error"
	on error err_msg number err_num
		--error "Can't get info from Safari: " & err_msg number err_num
		set t to "Error: Can't get info from Safari"
		set m to err_msg & " (" & err_num & ")"
		display alert t message m buttons {"Cancel"} cancel button 1 as critical
	end try
end tell
-- Transliterate non-ASCII characters to ASCII
set this_title to convert_to_ascii(this_title)

--return this_title -- :DEBUG:


(*==== Parse existing data (model-ish) ====*)

--
-- Format the record separator between log entries
--
set rule_char to "-"
set rule_width to 80 -- total width
set name_col_width to 7 -- name column width only
set field_sep to " | "
set rec_sep to "" & multiply_text(rule_char, name_col_width - 1) & Â
	"+" & multiply_text(rule_char, rule_width - name_col_width)

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

--
-- Add header to new or empty log file
--
set should_init to false
tell application "Finder"
	if (not (exists log_file_mac)) or (io_obj's read_file(log_file_mac) is "") then
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
	tell io_obj to write_file(log_file_mac, file_header)
	set all_category_txt to default_categories
else
	-- Read categories from file
	(*
		:TODO: Error handling.
	*)
	set all_category_txt to text 2 thru -2 of (item 3 of split_text(io_obj's read_file(log_file_mac), head_sep))
end if

--
-- Parse any existing labels from the "Label" fields of the URLs file:
--
set s to "LANG=C sed -n 's/^Label | //p' " & quoted form of log_file & " | sort | uniq"
--return s
set categories_used to do shell script s without altering line endings

--
-- Sort those along with the manually entered categories/labels:
--
set s to "echo \"" & all_category_txt & linefeed & categories_used & "\" | egrep -v '^$' | sort | uniq"
set all_category_txt to do shell script s without altering line endings
--return all_category_txt -- :DEBUG:
--
-- Coerce the lines into a list:
--
set g_all_categories to paragraphs of all_category_txt
if g_all_categories's last item is "" then set g_all_categories to g_all_categories's items 1 thru -2
--return g_all_categories -- :DEBUG:

--
-- Get top-level categories:
--
set s to "LANG=C echo \"" & all_category_txt & "\" | sed -n 's/^\\([^:]\\{1,\\}\\).*/\\1/p' | uniq"
set top_category_txt to do shell script s without altering line endings
--return top_category_txt -- :DEBUG:
--
-- Coerce the lines into a list:
--
set g_top_categories to paragraphs of top_category_txt
if g_top_categories's last item is "" then set g_top_categories to g_top_categories's items 1 thru -2
--return g_top_categories -- :DEBUG:


(*==== Main view(-ish) ====*)

--
-- Prompt for title, category/subcategories and optional note for URL
--

-- The number of dialog prompts will vary depending on if a subcategory list is requested.
set g_prompt_count to 1 -- increment with every dialog or list prompt, decrement if going back
set g_prompt_total to 4 -- increment if sub/full lists are displayed, decrement if going back

--
-- Accept or modify page title
--
set b to {"Manually Edit Log File", "Cancel", "Next..."}
set t to "" & script_name & ": Title (" & g_prompt_count & "/" & g_prompt_total & ")"
set m to "To log the URL for:" & return & return Â
	& tab & "\"" & this_title & "\"" & return & return & Â
	"first accept or edit the title."
display dialog m default answer this_title with title t buttons b default button last item of b cancel button second item of b with icon note
set {this_title, btn_pressed} to {text returned of result, button returned of result}
set g_prompt_count to g_prompt_count + 1
if btn_pressed is first item of b then
	-- :TODO:2013.01.03: only opening file in GUI editor now, so need Mac path?
	(*if should_use_shell then
		set this_log_file to quoted form of log_file_posix
	else
		set this_log_file to log_file
	end if
	edit_log(this_log_file, text_editor, should_use_shell)*)
	edit_log(log_file_mac, text_editor)
	return "Script ended with '" & (first item of b as text) & "'"
end if

--
-- Accept or modify URL
--
-- :TODO:

--
-- Select a category
--
set chosen_category to choose_category(g_top_categories, "top")
if chosen_category is false then error number -128 -- User canceled

--
-- Get the info so far
--
set cur_info to "TITLE:" & tab & tab & this_title & return & "URL:" & tab & tab & this_url

--
-- Modify selected category or enter a new category
--
set t to "" & script_name & ": Category (" & g_prompt_count & "/" & g_prompt_total & ")"
set m to cur_info & return & return & "Please provide a category and any optional subcategories (or edit your selected category) for the URL. Example: \"Development:AppleScript:Mail\""
repeat --10 times -- limit loops as a precaution during development
	display dialog m default answer chosen_category with title t buttons b default button last item of b cancel button second item of b with icon note
	set {this_label, btn_pressed} to {text returned of result, button returned of result}
	if this_label is not "" then
		exit repeat
	else
		set t2 to "Category required"
		set m2 to "Please supply a category for the URL."
		display alert t2 message m2 as warning
	end if
end repeat
set g_prompt_count to g_prompt_count + 1

--
-- Update the info
--
set cur_info to cur_info & return & "CATEGORY:" & tab & this_label

--
-- Optionally add note
--
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
	io_obj's append_file(log_file_mac, final_text)
else
	(*if should_use_shell then
		set this_log_file to quoted form of log_file_posix
	else
		set this_log_file to log_file
	end if
	edit_log(this_log_file, text_editor, should_use_shell)*)
	-- :TODO:2013.01.03: only opening file in GUI editor now, so need Mac path?
	edit_log(log_file_mac, text_editor)
end if

--display alert "Log Page" message "DEBUG: Script complete."


(*
==================================================
    Subroutines
==================================================
*)

(*==== Main Functions ====*)

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
	
	--log "[debug] g_previous_categories: " & join_list(g_previous_categories, ", ")
	
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
		if (count of sub_categories) is greater than 1 then
			--log "[debug] incrementing both prompt count and total"
			set g_prompt_count to g_prompt_count + 1
			set g_prompt_total to g_prompt_total + 1
			--log "[debug] recurse to choose_category(sub_categories, \"sub\")"
			set chosen_category to choose_category(sub_categories, "sub")
		else
			-- Advance to next dialog (category editing)
			set g_prompt_count to g_prompt_count + 1
		end if
	else
		-- Advance to next dialog (category editing)
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
			u_bullet_ls & "Show full list with subcategoriesÉ", Â
			u_bullet_ls & "Create a new category...", Â
			multiply_text(u_dash, 20)}
	else if list_type is "sub" then
		return {Â
			u_bullet_ls & "Show full list of categories...", Â
			u_back_ls & "Go back to previous list...", Â
			multiply_text(u_dash, 35)}
	else if list_type is "all" then
		return {Â
			u_back_ls & "Go back to previous list...", Â
			multiply_text(u_dash, 35)}
	else
		return false
	end if
end get_extra_items

----- External Views

on edit_log(log_file, text_editor)
	--on edit_log(log_file, text_editor, should_use_shell)
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
	(*if should_use_shell then
		set s to text_editor & space & log_file & space & "> /dev/null 2>&1"
		do shell script s
		return
	else*)
	set t to script_name
	--set m to ":TODO: edit_log() function: use non-shell-invoked editor."
	set m to ":TODO:2013.01.03: only opening file in GUI editor now, so need Mac path?"
	set b to {"Cancel"}
	display alert t message m buttons b cancel button 1 as critical
	return false
	--end if
end edit_log

(*==== Settings Functions ====*)

on do_first_run(settings_model)
	local settings_model
	set t to "Log Page > First Run"
	set m to "This script will append the URL of the front Safari document to a text file along with the current date/time, the title of the web page and a user-definable category. The script also includes an option to open the file in your favorite text editor for editing. The default file and text editor are:" & return & return Â
		& "	URLs File:	" & settings_model's get_default_file() & return & return Â
		& "	Text Editor:	" & settings_model's get_default_editor() & return & return Â
		& "You can continue using those defaults or change the settings now. You can also change the settings later by selecting the \"Preferences\" item from any list dialog. (You would have to manually move your old URLs file though if you wanted to keep appending to it.)"
	-- :TODO: Offer to move the file when changing file location/name. (Not here.)
	set b to {"Change settingsÉ", "Cancel", "Continue"}
	display dialog m with title t buttons b default button b's last item with icon note
	set btn_pressed to button returned of result
	
	--settings_model's set_item("logFile", "DEBUG: logFile: do_first_run()") -- :DEBUG:
	--settings_model's set_item("textEditor", "DEBUG: textEditor: do_first_run()") -- :DEBUG:
	
	-- Use defaults
	settings_model's set_item("logFile", settings_model's get_default_file())
	settings_model's set_item("textEditor", settings_model's get_default_editor())
	
	-- Change settings
	if btn_pressed is b's first item then
		set_preferences(settings_model, settings_model's get_default_file(), settings_model's get_default_editor())
	end if
	
	-- Save settings
	settings_model's write_settings()
	
	return settings_model
end do_first_run

on set_preferences(settings_model, default_file, default_editor)
	(*
		Triggered from:
		  * do_first_run()
		  * any list dialog from main script (when saving a URL)
	*)
	local settings_model, default_file, default_editor, settings_view
	
	--
	-- Prompt user for preferences
	--
	set settings_view to make_settings_view(default_file, default_editor, settings_model's get_item("logFile"), settings_model's get_item("textEditor"))
	settings_view's display()
	
	--
	-- Write preferences file (if necessary)
	--
	if settings_view's get_file() is not settings_model's get_item("logFile") then
		settings_model's set_item_and_write_pref("logFile", settings_view's get_file())
	end if
	
	if settings_view's get_editor() is not settings_model's get_item("textEditor") then
		settings_model's set_item_and_write_pref("textEditor", settings_view's get_editor())
	end if
	
	return settings_model
end set_preferences


(*==== Utility Functions ====*)

on convert_to_ascii(non_ascii_txt)
	--
	-- From 'man iconv_open':
	--
	--    When the string "//TRANSLIT" is appended to _tocode_, transliteration
	--    is activated. This means that when a character cannot be represented
	--    in the target character set, it can be approximated through one or
	--    several characters that look similar to the original character.
	--
	--    When the string "//IGNORE" is appended to _tocode_, characters that
	--    cannot be represented in the target character set will be silently
	--    discarded.
	--
	set s to "iconv -f UTF-8 -t US-ASCII//TRANSLIT//IGNORE <<<" & quoted form of non_ascii_txt
	do shell script s
end convert_to_ascii

on create_directory(posix_dir)
	set this_dir to expand_home_path(posix_dir)
	try
		set s to "mkdir -pm700 " & quoted form of this_dir
		do shell script s
	on error err_msg number err_num
		error "Can't create directory: " & err_msg number err_num
		return "Fatal Error: Can't create directory"
	end try
end create_directory

on split_path_into_dir_and_file(file_path)
	set path_parts to split_text(file_path, "/")
	set dir_path to join_list(items 1 thru -2 of path_parts, "/")
	set file_name to path_parts's last item
	return {dir_path, file_name}
end split_path_into_dir_and_file

-- Could alternatively use 'do shell script "echo" & space & file_path'
-- but it might be slower because of the overhead of starting up a shell.
on expand_home_path(file_path)
	if file_path starts with "~/" then
		set posix_home to get_posix_home()
		set file_path to posix_home & characters 3 thru -1 of file_path as text
	else if file_path starts with "$HOME/" then
		set posix_home to get_posix_home()
		set file_path to posix_home & characters 7 thru -1 of file_path as text
	end if
	return file_path
end expand_home_path

on get_posix_home()
	return POSIX path of (path to home folder from user domain)
end get_posix_home

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

(*
==================================================
    Script Objects (and Constructors)
==================================================
*)

(*==== Main Classes ====*)

-- MODEL: Settings
on make_settings_model(plist_path, default_file, default_editor)
	(*
		Dependencies:
		  * AssociativeList class
		  * split_path_into_dir_and_file() function (supplied by main script)
		  * create_directory() function (supplied by main script)
	*)
	script SettingsModel
		property class : "SettingsModel"
		property parent : make_associative_list()
		
		property _plist_path : missing value
		property _default_file : missing value -- for restoring default
		property _default_editor : missing value -- for restoring default
		
		(* == PUBLIC == *)
		
		on get_default_file()
			return _default_file
		end get_default_file
		
		on get_default_editor()
			return _default_editor
		end get_default_editor
		
		-- Get the values for each key in the given list
		on read_settings(plist_keys) -- void; modifies associative list
			log "[debug] read_settings()" -- MARK
			try
				repeat with this_key in plist_keys
					set this_key to this_key's contents -- dereference implicit loop reference
					set this_value to read_pref(this_key)
					set_item(this_key, this_value)
				end repeat
			on error err_msg number err_num
				error "Can't read_settings(): " & err_msg number err_num
			end try
			log "[debug] read_settings(): done"
		end read_settings
		
		on write_settings() -- void; writes to file
			try
				repeat with this_key in get_keys()
					set this_key to this_key's contents -- dereference implicit loop reference
					write_pref(this_key, get_item(this_key))
				end repeat
			on error err_msg number err_num
				error "Can't write_settings(): " & err_msg number err_num
			end try
		end write_settings
		
		on set_item_and_write_pref(this_key, this_value) -- void; modifies associative list, saves file
			set_item(this_key, this_value) -- store value in object
			write_pref(this_key, this_value) -- write value to file
		end set_item_and_write_pref
		
		on read_pref(pref_key) -- returns value of key
			log "[debug] read_pref()"
			local pref_key
			try
				tell application "System Events"
					tell property list file _plist_path
						return value of property list item pref_key
					end tell
				end tell
			on error err_msg number err_num
				error "Can't read_pref(): " & err_msg number err_num
			end try
		end read_pref
		
		on write_pref(pref_key, pref_value) -- void; writes to file
			-- :XXX: This function only sets string types now. If need to set other
			-- types, write a function to detect the type of the given value. (I've
			-- already got one somewhere.)
			log "[debug] write_pref()"
			local pref_key, pref_value, this_plistfile
			try
				tell application "System Events"
					-- Make a new plist file if one doesn't exist
					if not (exists disk item _plist_path) then
						-- Create any missing directories first
						set plist_dir to item 1 of my split_path_into_dir_and_file(_plist_path)
						my create_directory(plist_dir)
						-- Create the plist
						set this_plistfile to my _new_plist()
					else
						set this_plistfile to property list file _plist_path
					end if
					-- Change key value if keys exists, otherwise add new key/value
					-- (This doesn't seem to actually be necessary, but it seems more correct.)
					tell this_plistfile
						try
							my read_pref(pref_key)
							set value of property list item pref_key to pref_value
						on error
							make new property list item at end of property list items with properties {kind:string, name:pref_key, value:pref_value}
						end try
					end tell
				end tell
			on error err_msg number err_num
				error "Can't write_pref(): " & err_msg number err_num
			end try
		end write_pref
		
		(* == PRIVATE == *)
		
		on _new_plist() -- returns a 'property list file'
			log "[debug] _new_plist()"
			local parent_dictionary, this_plistfile
			try
				tell application "System Events"
					-- delete any existing property list from memory
					delete every property list item
					-- create an empty property list dictionary item
					set parent_dictionary to make new property list item with properties {kind:record}
					-- create a new property list using the empty record
					set this_plistfile to make new property list file with properties {contents:parent_dictionary, name:_plist_path}
					return this_plistfile
				end tell
			on error err_msg number err_num
				error "Can't _new_plist(): " & err_msg number err_num
			end try
		end _new_plist
	end script
	
	-- initialize new object instance
	set SettingsModel's _plist_path to plist_path
	set SettingsModel's _default_file to default_file
	set SettingsModel's _default_editor to default_editor
	return SettingsModel
end make_settings_model

-- VIEW: Settings
on make_settings_view(default_file, default_editor, cur_file, cur_editor)
	(*
		Dependencies:
		  * multiply_text() function (supplied by main script)
		  * split_text() function (supplied by main script)
		  * join_list() function (supplied by main script)
		  * split_path_into_dir_and_file() function (supplied by main script)
	*)
	script SettingsView
		property class : "SettingsView"
		
		property _default_file : missing value -- for restoring default
		property _default_editor : missing value -- for restoring default
		property _cur_file : missing value
		property _cur_editor : missing value
		
		property _did_display_2 : false
		property _display_2_action : missing value -- 'file' or 'editor'
		property _display_2_button : missing value
		
		(* == PUBLIC == *)
		
		on get_file()
			return _cur_file
		end get_file
		
		on get_editor()
			return _cur_editor
		end get_editor
		
		on display()
			log "[debug] display()"
			_display_1()
			_show_final_settings()
			log "[debug] display(): returning true"
			return true
		end display
		
		(* == PRIVATE == *)
		
		-- Last preferences display
		on _show_final_settings() -- PRIVATE
			log "[debug] _show_final_settings()"
			log "[debug] _did_display_2: '" & _did_display_2 & "'"
			set t to script_name & " Updated Settings"
			set m to "URLs File:" & tab & tab & _cur_file & return & return Â
				& "Text Editor:" & tab & _cur_editor
			display alert t message m
			log "[debug] _show_final_settings(): returning true"
			return true
		end _show_final_settings
		
		-- Level 1: main (before any changes have been made)
		on _display_1() -- PRIVATE
			log "[debug] _display_1()"
			log "[debug] _did_display_2: '" & _did_display_2 & "'"
			set t to script_name & " > Settings"
			set m to "Choose a URLs file and/or a text editor for editing the file. The current settings are:" & return & return Â
				& "	URLs File:	" & _cur_file & return & return Â
				& "	Text Editor:	" & _cur_editor & return & return
			set b to {"Cancel", "Choose a text editorÉ", "Choose a URLs fileÉ"}
			display dialog m with title t buttons b with icon note
			set btn_pressed to button returned of result
			
			if btn_pressed is b's second item then
				set _cur_editor to _choose_text_editor()
				if _cur_editor is false then error number -128 -- User canceled
				if not _did_display_2 then _prompt_for_file(b's last item)
			else if btn_pressed is b's last item then
				set _cur_file to _choose_urls_file()
				if _cur_file is false then error number -128 -- User canceled
				if not _did_display_2 then _prompt_for_editor(b's second item)
			end if
			
			log "[debug] _display_1(): returning true"
			return true
		end _display_1
		
		-- Level 1: secondary (after a setting has been changed)
		on _display_2(is_from_submenu) -- PRIVATE
			log "[debug] _display_2()"
			log "[debug] _did_display_2: '" & _did_display_2 & "'"
			if _did_display_2 and not is_from_submenu then return true
			
			if _display_2_action is "file" then
				set {m1, m2, m3, m4} to {"text editor", _cur_editor, "URLs file", _cur_file}
			else if _display_2_action is "editor" then
				set {m1, m2, m3, m4} to {"URLs file", _cur_file, "text editor", _cur_editor}
			end if
			set m to "For the " & m1 & ", you chose:" & return & return Â
				& tab & m2 & return & return Â
				& "You can now either continue or also change the current " & m3 Â
				& " which is:" & return & return & tab & m4
			set t to script_name & " > Settings"
			set b to {_display_2_button, "Cancel", "Continue"}
			display dialog m with title t buttons b default button b's last item with icon note
			set btn_pressed to button returned of result
			set _did_display_2 to true
			
			if btn_pressed is b's first item then
				if _display_2_action is "file" then
					set _cur_file to _choose_urls_file() -- recursion
					if _cur_file is false then error number -128 -- User canceled
				else if _display_2_action is "editor" then
					set _cur_editor to _choose_text_editor() -- recursion
					if _cur_editor is false then error number -128 -- User canceled
				end if
			end if
			
			log "[debug] _display_2(): returning true"
			return true
		end _display_2
		
		-- Level 1: secondary (configures _display_2())
		on _prompt_for_file(display_2_button) -- PRIVATE
			log "[debug] _prompt_for_file()"
			log "[debug] _did_display_2: '" & _did_display_2 & "'"
			if not _did_display_2 then
				set _display_2_action to "file"
				set _display_2_button to display_2_button
				_display_2(false)
			end if
			log "[debug] _prompt_for_file(): returning true"
			return true
		end _prompt_for_file
		
		-- Level 1: secondary (configures _display_2())
		on _prompt_for_editor(display_2_button) -- PRIVATE
			log "[debug] _prompt_for_editor()"
			log "[debug] _did_display_2: '" & _did_display_2 & "'"
			if not _did_display_2 then
				set _display_2_action to "editor"
				set _display_2_button to display_2_button
				_display_2(false)
			end if
			log "[debug] _prompt_for_editor(): returning true"
			return true
		end _prompt_for_editor
		
		-- Level 2 (change a setting)
		-- :TODO: Offer to move/rename the file when changing file location/name.
		on _choose_urls_file() -- PRIVATE
			log "[debug] _choose_urls_file()"
			log "[debug] _did_display_2: '" & _did_display_2 & "'"
			set t to script_name & " > Settings > Choose File"
			set m to "Choose a file in which to save URLs:"
			set list_rule to multiply_text(u_dash, 19)
			set list_items to {Â
				u_back_ls & "Back", Â
				list_rule, Â
				"Use default fileÉ", Â
				"Choose an existing fileÉ", Â
				"Choose a new fileÉ", Â
				list_rule, Â
				"Type in a file pathÉ		(Advanced)"}
			repeat -- until a horizontal rule is not selected
				set list_choice to choose from list list_items with title t with prompt m
				if list_choice as text is not list_rule then
					exit repeat
				else
					display alert "Invalid selection" message "Please select an action." as warning
				end if
			end repeat
			if list_choice is false then error number -128 -- User canceled
			
			-- Level 3
			if list_choice as text is list_items's first item then -- GO BACK
				if _did_display_2 then
					_display_2(true) -- recursion
				else
					_display_1() -- recursion
				end if
			else if list_choice as text is list_items's item 3 then -- DEFAULT FILE
				set t to script_name & " > Settings > Choose File > Default"
				set m to "The default URLs file is:" & return & return & tab & _default_file & return & return & "Use this file?" & return & return
				set b to {"Choose a different fileÉ", "Cancel", "Use default"}
				display dialog m with title t buttons b default button b's last item with icon note
				set btn_pressed to button returned of result
				if btn_pressed is b's first item then
					set _cur_file to _choose_urls_file() -- recursion
				else if btn_pressed is b's last item then
					set _cur_file to _default_file
				end if
			else if list_choice as text is list_items's item 4 then -- EXISTING FILE
				set m to "Choose an existing URLs file."
				set _cur_file to POSIX path of (choose file with prompt m default location path to desktop folder from user domain)
			else if list_choice as text is list_items's item 5 then -- NEW FILE
				set m to "Choose a file name and location for the URLs file. Optionally create a new folder for the file."
				set file_name to item 2 of split_path_into_dir_and_file(_default_file)
				set _cur_file to POSIX path of (choose file name with prompt m default name file_name default location path to desktop folder from user domain)
			else if list_choice as text is list_items's last item then -- TYPE PATH
				set t to script_name & " > Settings > Choose File > Enter Path"
				set m to "Enter a full file path to use for saving the URLs." & return & return & "A '~' (tilde) can be used to indicate your home directory. Example:" & return & return & tab & "~/Desktop/urls.txt"
				set b to {u_back_btn & "Back", "Cancel", "Continue"}
				display dialog m with title t buttons b default answer _cur_file default button b's last item with icon note
				set {this_path, btn_pressed} to {text returned of result, button returned of result}
				if btn_pressed is b's first item then
					set _cur_file to _choose_urls_file() -- recursion
				else if btn_pressed is b's last item then
					set _cur_file to this_path
				end if
			end if
			
			log "[debug] _choose_urls_file(): returning '" & _cur_file & "'"
			return _cur_file
		end _choose_urls_file
		
		-- Level 2 (change a setting)
		on _choose_text_editor() -- PRIVATE
			log "[debug] _choose_text_editor()"
			log "[debug] _did_display_2: '" & _did_display_2 & "'"
			set t to script_name & " > Settings > Choose Editor"
			set m to "Choose a text editor application for editing the URLs file:"
			set b to {u_back_btn & "Back", "Use default editorÉ", "Choose another editor..."}
			display dialog m with title t buttons b default button b's last item with icon note
			set btn_pressed to button returned of result
			
			-- Level 3
			if btn_pressed as text is b's first item then -- GO BACK
				if _did_display_2 then
					_display_2(true) -- recursion
				else
					_display_1() -- recursion
				end if
			else if btn_pressed as text is b's second item then -- DEFAULT EDITOR
				set t to script_name & " > Settings > Choose Editor > Default"
				set m to "The default text editor app is:" & tab & _default_editor & return & return & "Use this app?" & return & return
				set b to {u_back_btn & "Back", "Cancel", "Use default"}
				display dialog m with title t buttons b default button b's last item with icon note
				set btn_pressed to button returned of result
				if btn_pressed is b's first item then
					set _cur_editor to _choose_text_editor() -- recursion
				else if btn_pressed is b's last item then
					set _cur_editor to _default_editor
				end if
			else if btn_pressed as text is b's last item then -- ANOTHER EDITOR
				set t to script_name & " > Settings > Choose Editor > Choose Application"
				set m to "Select an application to use for editing the URLs file:"
				set _cur_editor to name of (choose application with title t with prompt m)
			end if
			
			log "[debug] _choose_text_editor(): returning '" & _cur_editor & "'"
			return _cur_editor
		end _choose_text_editor
	end script -- SettingsView
	
	-- initialize new object instance
	set SettingsView's _default_file to default_file
	set SettingsView's _default_editor to default_editor
	set SettingsView's _cur_file to cur_file
	set SettingsView's _cur_editor to cur_editor
	return SettingsView
end make_settings_view

(*==== Utility Objects ====*)

on make_associative_list()
	(*
	Modified and expanded version of associative list class from:
	_Learn AppleScript: The Comprehensive Guide to Scripting and Automation on Mac OS X,
	Third Edition_ (2010, Apress) by Hamish Sanderson and Hanaan Rosenthal
	Chapter 19, page 561
	*)
	script
		property class : "AssociativeList" -- Data Type
		property these_items : {} -- list of two-item key/value records -- see set_item()
		
		on _find_record_for_key(this_key) -- PRIVATE
			(* This is a private handler. Users should not use it directly. *)
			considering diacriticals, hyphens, punctuation and white space but ignoring case
				repeat with record_ref in my these_items
					if |key| of record_ref = this_key then return record_ref -- original
				end repeat
			end considering
			return missing value -- The key wasn't found
		end _find_record_for_key
		
		on set_item(this_key, this_value)
			(*
				Set the value for the given key in an associative list.

				this_key : anything -- the key to use
				this_value : anything -- the new value
			*)
			set record_ref to _find_record_for_key(this_key)
			if record_ref = missing value then
				set end of my these_items to {|key|:this_key, value:this_value} -- original
			else
				set value of record_ref to this_value
			end if
			return -- No return value; the handler modifies the existing associative list.
		end set_item
		
		on get_item(this_key)
			(*
				Get the value for the given key in an associative list.

				this_key : anything -- the key to search for
				Result : anything -- the value, if found

				Note: Raises error -1728 if the key isn't found.
			*)
			set record_ref to _find_record_for_key(this_key)
			if record_ref = missing value then
				error "The key wasn't found." number -1728 from this_key
			end if
			return value of record_ref
		end get_item
		
		on count_items()
			(*
				Return the number of items in an associative list.

				Result : integer
			*)
			return count my these_items
		end count_items
		
		on delete_item(this_key)
			(*
				Delete the value for the given key.

				this_key : anything -- the key to delete
			*)
			set record_ref to _find_record_for_key(this_key)
			if record_ref is missing value then
				error "The key wasn't found." number -1728 from this_key
			end if
			set contents of record_ref to missing value
			set my these_items to every record of my these_items
			return -- No return value; the handler modifies the existing associative list.
		end delete_item
		
		(* == Additional methods == *)
		
		on get_keys()
			set these_keys to {}
			repeat with record_ref in my these_items
				set end of these_keys to record_ref's |key|
			end repeat
			return these_keys
		end get_keys
		
		on get_values()
			set these_values to {}
			repeat with record_ref in my these_items
				set end of these_values to record_ref's value
			end repeat
			return these_values
		end get_values
		
		on key_exists(this_key)
			if _find_record_for_key(this_key) = missing value then
				return false
			else
				return true
			end if
		end key_exists
	end script
end make_associative_list

on make_null_io()
	script NullIO
		property class : "NullIO"
		property parent : make_io()

		on write_file(file_path, this_data)
			-- do nothing
			log "[debug] NullIO: write_file(): not writing to file"
		end write_file

		on append_file(file_path, this_data)
			-- do nothing
			log "[debug] NullIO: append_file(): not appending to file"
		end append_file
	end script
end make_null_io

on make_io()
	script IO
		property class : "IO"
		
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
end make_io
