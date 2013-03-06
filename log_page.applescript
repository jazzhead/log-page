(*
	Log Page - Log categorized web page bookmarks to a text file

	Version: @@VERSION@@
	Date:    2013-03-05
	Author:  Steve Wheeler

	Get the title and URL from the frontmost web browser window and
	save that along with the current date and time, a user-definable
	category, and an optional note to a plain text file. The result is
	a categorized, chronological, plain text list of bookmarks -- a
	bookmarks log.

	Supports Safari, Google Chrome, Firefox, and WebKit Nightly.

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


property __SCRIPT_NAME__ : "Log Page"
property __SCRIPT_VERSION__ : "@@VERSION@@"
property __SCRIPT_AUTHOR__ : "Steve Wheeler"
property __SCRIPT_COPYRIGHT__ : "Copyright © 2011-2013 " & __SCRIPT_AUTHOR__
property __SCRIPT_WEBSITE__ : "http://jazzheaddesign.com/work/code/log-page/"

property __NAMESPACE__ : "Jazzhead"
property __BUNDLE_ID__ : "net.jazzhead.scpt.LogPage"
property __PLIST_DIR__ : missing value

-- Debug settings
property __DEBUG_LEVEL__ : 0 -- integer (0 = no event logging)
property __NULL_IO__ : false -- boolean (if true, don't write to URL file)

on run
	-- Initialize any script properties here that should not be hardcoded
	set __PLIST_DIR__ to POSIX path of (path to preferences from user domain)
	
	set app_controller to make_app_controller()
	run app_controller
end run

(* ==== Main Controller ==== *)

-- This is the main client controller that creates the models and creates
-- and runs the other controllers.

on make_app_controller()
	script this
		property class : "AppController" -- the main controller
		
		on run
			my debug_log(1, "--->  running " & my class & "...")
			
			(* == Settings == *)
			
			--
			-- The settings controller is run first to load the saved
			-- settings from disk or show a "first run" settings dialog
			-- if there is no existing preferences file.
			--
			
			-- Need the settings model first
			set settings_model to make_page_log_settings()
			settings_model's init()
			
			-- Main model needs the settings model
			set page_log to make_page_log(settings_model)
			
			-- Settings controller needs both models
			set settings_controller to make_settings_controller(settings_model, page_log)
			run settings_controller
			
			(* == Data Retrieval == *)
			
			--
			-- Get the web page info from the web browser
			--
			set browser_model to my WebBrowserFactory's make_browser()
			browser_model's fetch_page_info()
			
			--
			-- Load initial data into the main model
			--
			tell page_log
				-- Get last-used category read from preferences file
				update_category_state()
				
				-- Store the web page info in the main model
				--
				set_page_url(browser_model's get_url())
				set_page_title(browser_model's get_title())
				set_browser_name(browser_model's to_string())
				
				my debug_log(1, "[debug] " & get_page_url())
				my debug_log(1, "[debug] " & get_page_title())
				
				-- Parse the categories from the log file
				--
				parse_log()
			end tell
			
			-- Done with browser. Does this make any difference?
			set browser_model to missing value
			
			(* == Controllers == *)
			
			--
			-- Create the shared navigation controller
			--
			set nav_controller to make_navigation_controller()
			
			--
			-- Create shared category base view
			--
			set label_base_view to make_label_base_view(page_log)
			
			--
			-- Create any other needed controllers, passing in whatever
			-- shared models, controllers and/or views they need.
			--
			set help_controller to make_help_controller(nav_controller, settings_model)
			set file_editor_controller to make_file_editor_controller(nav_controller, settings_model)
			set file_viewer_controller to make_file_viewer_controller(nav_controller, settings_model)
			--
			set title_controller to make_title_controller(nav_controller, page_log)
			set url_controller to make_url_controller(nav_controller, page_log)
			-- 
			set label_controller to make_label_controller(nav_controller, page_log, label_base_view)
			set sub_label_controller to make_sub_label_controller(nav_controller, page_log, label_base_view)
			set all_label_controller to make_all_label_controller(nav_controller, page_log, label_base_view)
			--
			set label_edit_controller to make_label_edit_controller(nav_controller, page_log)
			set note_controller to make_note_controller(nav_controller, page_log)
			--
			set label_help_controller to make_label_help_controller()
			set about_controller to make_about_controller()
			
			--
			-- Dependency Injection
			--
			-- Each controller needs a reference to any other
			-- controllers that it might add to the navigation stack.
			-- (The injected controllers are referred to by index so for
			-- ease of implementation, add the default action first. For
			-- list dialogs, then add actions in the list order.)
			--
			help_controller's set_controllers({settings_controller})
			title_controller's set_controllers({Â
				help_controller, Â
				url_controller})
			url_controller's set_controllers({label_controller})
			label_controller's set_controllers({Â
				sub_label_controller, Â
				all_label_controller, Â
				label_edit_controller, Â
				file_editor_controller, Â
				file_viewer_controller, Â
				settings_controller, Â
				about_controller, Â
				help_controller, Â
				label_help_controller})
			sub_label_controller's set_controllers({Â
				label_edit_controller, Â
				all_label_controller, Â
				file_editor_controller, Â
				file_viewer_controller, Â
				settings_controller, Â
				about_controller, Â
				help_controller, Â
				label_help_controller})
			all_label_controller's set_controllers({Â
				label_edit_controller, Â
				file_editor_controller, Â
				file_viewer_controller, Â
				settings_controller, Â
				about_controller, Â
				help_controller, Â
				label_help_controller})
			label_edit_controller's set_controllers({note_controller})
			
			--
			-- Load the first (root) controller onto the stack
			--
			nav_controller's push_root_controller(title_controller)
			
			my debug_log(1, my class & "'s History Stack: " & nav_controller's history_to_string())
			my debug_log(1, my class & "'s Controller Stack: " & nav_controller's to_string())
			
			(* == UI == *)
			
			--
			-- This is the main UI/View loop. It will loop through the
			-- controller stack until empty, prompting the user for info.
			--
			-- The controller stack can be modified by any controller so
			-- the loop will run as long as controllers keep pushing
			-- other controllers onto the stack in response to user
			-- action.
			--
			if nav_controller's is_empty() then
				error "The navigation controller stack needs at least one controller."
			end if
			repeat while not nav_controller's is_empty()
				set this_controller to nav_controller's pop()
				set ret_val to run this_controller --> returns boolean
				
				my debug_log(1, my class & "'s History Stack: " & nav_controller's history_to_string())
				my debug_log(1, my class & "'s Controller Stack: " & nav_controller's to_string())
				
				if not ret_val then -- {FileEditor,FileViewer}Controller will return false
					my debug_log(1, "--->  finished " & my class)
					return -- don't do any post-processing
				end if
			end repeat
			
			(* == Processing == *)
			
			--
			-- All that's left is to append the data to the log file.
			--
			page_log's write_record()
			
			my debug_log(1, "--->  finished " & my class)
		end run
	end script
	
	my debug_log(1, "--->  new " & this's class & "()")
	return this
end make_app_controller

(* ==== Model ==== *)

-- -- -- Main App Models -- -- --

on make_page_log(settings_model)
	script this
		property class : "PageLog" -- the main model
		property parent : make_observable() -- extends Observable
		property _settings : settings_model --> Settings
		property _io : missing value --> IO
		
		-- Sample categories (labels) if the URL file is new. After
		-- sample categories have been written to file, any of them
		-- can be deleted, modified or added to there.
		--
		property _sample_categories : "Development
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
		property _log_header_sep : my multiply_text("#", 80)
		property _log_record_sep : missing value --> string
		
		property _page_url : missing value --> string
		property _page_title : missing value --> string
		property _page_label : missing value --> string
		property _page_note : missing value --> string
		property _browser_name : missing value --> string
		property _log_record : missing value --> string
		property _should_create_file : false --> boolean
		
		property _root_categories : missing value --> array
		property _all_categories : missing value --> array
		
		property _chosen_root_category : missing value --> string -- label view state
		property _chosen_category : missing value --> string -- label view state
		
		(* == Setters == *)
		
		on set_browser_name(this_value) --> void
			set _browser_name to this_value
			settings_changed() -- notify observers
		end set_browser_name
		
		on set_page_url(this_value) --> void
			set _page_url to this_value
			settings_changed() -- notify observers
		end set_page_url
		
		on set_page_title(this_value) --> void
			my debug_log(1, my class & ".set_page_title(" & this_value & ")")
			set _page_title to this_value
			settings_changed() -- notify observers
		end set_page_title
		
		on set_page_label(this_value) --> void
			set _page_label to this_value
			settings_changed() -- notify observers
		end set_page_label
		
		on set_page_note(this_value) --> void
			set _page_note to this_value
			settings_changed() -- notify observers
		end set_page_note
		
		on set_chosen_root_category(this_value) --> void
			set _chosen_root_category to this_value
			settings_changed() -- notify observers
		end set_chosen_root_category
		
		on set_chosen_category(this_value) --> void
			set _chosen_category to this_value
			settings_changed() -- notify observers
		end set_chosen_category
		
		(* == Getters == *)
		
		on get_browser_name() --> string
			return _browser_name
		end get_browser_name
		
		on get_page_url() --> string
			return _page_url
		end get_page_url
		
		on get_page_title() --> string
			return _page_title
		end get_page_title
		
		on get_page_label() --> string
			return _page_label
		end get_page_label
		
		on get_page_note() --> string
			return _page_note
		end get_page_note
		
		on get_all_categories() --> array
			return _all_categories
		end get_all_categories
		
		on get_root_categories() --> array
			return _root_categories
		end get_root_categories
		
		on get_sub_categories() --> array
			local sub_categories, this_cat
			set sub_categories to {}
			repeat with this_cat in _all_categories
				set this_cat to this_cat's contents -- dereference
				if this_cat is _chosen_root_category Â
					or this_cat starts with (_chosen_root_category & ":") then
					set end of sub_categories to this_cat
				end if
			end repeat
			return sub_categories
		end get_sub_categories
		
		on get_chosen_root_category() --> string
			return _chosen_root_category
		end get_chosen_root_category
		
		on get_chosen_category() --> string
			return _chosen_category
		end get_chosen_category
		
		(* == Actions == *)
		
		on write_record() --> void
			local log_file_posix, log_file_mac
			
			set log_file_posix to expand_home_path(_settings's get_log_file())
			set log_file_mac to get_mac_path(log_file_posix)
			
			-- Write last selected category to preferences file (save state)
			_settings's set_pref(_settings's get_last_category_key(), _page_label)
			
			_format_record()
			
			_validate_fields()
			
			-- Create any directories needed in the web page log file path
			create_directory(first item of split_path_into_dir_and_file(log_file_posix))
			
			if _should_create_file then _create_log_file()
			
			_io's append_file(log_file_mac, _log_record)
		end write_record
		
		on parse_log() --> void
			my debug_log(2, my class & ".parse_log()...")
			
			local log_file_posix, log_file_mac, header_items
			local all_category_txt, root_category_txt
			local all_categories, root_categories, existing_categories
			
			set log_file_posix to expand_home_path(_settings's get_log_file())
			set log_file_mac to get_mac_path(log_file_posix)
			
			my debug_log(2, my class & ".parse_log(): file = " & log_file_posix)
			
			-- Does file exist?
			tell application "Finder"
				if (not (exists log_file_mac)) then set _should_create_file to true
			end tell
			
			-- If file exists, is it empty?
			if not _should_create_file then
				try
					if (get eof file log_file_mac) is 0 then set _should_create_file to true
				on error
					set _should_create_file to true
				end try
			end if
			
			if _should_create_file then
				-- Use sample categories when creating a new file
				set all_category_txt to _sample_categories
			else
				-- Read manually-entered (and/or previous sample)
				-- categories from existing file header
				try
					set header_items to split_text(_io's read_file(log_file_mac), _log_header_sep)
					if header_items's length is 5 then
						set all_category_txt to text 2 thru -2 of header_items's item 3
					else
						error
					end if
				on error -- file header is bad or missing, or user deleted samples
					set all_category_txt to missing value
				end try
			end if
			
			-- Parse any existing labels from the "Label" fields of the URLs file:
			--
			set s to "LANG=C sed -n 's/^Label | //p' " & quoted form of log_file_posix Â
				& " | sort | uniq"
			set existing_categories to do shell script s without altering line endings
			
			-- Sort those along with the manual/sample categories/labels:
			--
			if all_category_txt is not missing value then
				set existing_categories to all_category_txt & linefeed & existing_categories
			end if
			set s to "echo \"" & existing_categories & "\" | egrep -v '^$' | sort | uniq"
			set all_category_txt to do shell script s without altering line endings
			
			-- Coerce the lines into a list:
			--
			set all_categories to paragraphs of all_category_txt
			try -- omit trailing blank lines
				repeat until all_categories's last item is not ""
					set all_categories to all_categories's items 1 thru -2
				end repeat
			on error -- no categories found
				set all_categories to {}
			end try
			
			-- Get root-level categories:
			--
			set s to "LANG=C echo \"" & all_category_txt Â
				& "\" | sed -n 's/^\\([^:]\\{1,\\}\\).*/\\1/p' | uniq"
			set root_category_txt to do shell script s without altering line endings
			
			-- Coerce the lines into a list:
			--
			set root_categories to paragraphs of root_category_txt
			try -- omit trailing blank lines
				repeat until root_categories's last item is not ""
					set root_categories to root_categories's items 1 thru -2
				end repeat
			on error -- no categories found
				set root_categories to {}
			end try
			
			set _all_categories to all_categories
			set _root_categories to root_categories
			settings_changed() -- notify observers
			
			my debug_log(1, get_root_categories())
			my debug_log(2, get_all_categories())
			
			my debug_log(2, my class & ".parse_log() done")
		end parse_log
		
		on update_category_state()
			my debug_log(1, my class & ".update_category_state()")
			set _page_label to _settings's get_last_category()
			if _page_label is missing value or _page_label is "" then
				set _chosen_category to ""
			else
				set _chosen_category to _page_label
			end if
			try
				set _chosen_root_category to my split_text(_page_label, ":")'s item 1
			on error
				set _chosen_root_category to ""
			end try
		end update_category_state
		
		(* == Observer Pattern == *)
		
		on settings_changed() -- void
			set_changed()
			notify_observers()
			if __DEBUG_LEVEL__ > 0 then identify_observers()
		end settings_changed
		
		(* == PRIVATE == *)
		
		on _validate_fields() --> void
			if _page_url is missing value then
				_error_missing("page URL")
			else if _page_title is missing value then
				_error_missing("page title")
			else if _page_label is missing value or _page_label is "" then
				_error_missing("page label (category)")
			else if _log_record is missing value then
				_error_missing("formatted page data")
			end if
		end _validate_fields
		
		on _error_missing(this_field) --> void
			error my class & ": missing value for: " & this_field & " - can't append to log"
		end _error_missing
		
		on _create_log_file() --> void
			local log_file_posix, log_file_mac, file_header
			
			set log_file_posix to expand_home_path(_settings's get_log_file())
			set log_file_mac to get_mac_path(log_file_posix)
			
			set file_header to _log_header_sep & "
# urls.txt - Timestamped and categorized URL archive               vim:ft=conf:
# ==================================================
#
# For use with \"Log Page\", an AppleScript available at:
#
#     " & __SCRIPT_WEBSITE__ & "
#
# When editing this file, take care not to alter the format. The field
# names, field widths, field delimiters and record delimiters should not
# be altered or the script will not be able to parse the data. Each URL
# record consists of a date, label (category), title, URL and optional
# note:
#
#     ------+----------------------------------------------------------
#     Date  | 2013-02-28 20:14:38
#     Label | Example Category:Subcategory:Another Subcategory
#     Title | Example Web Page Record
#     URL   | http://example.com
#     Note  | An optional note
#     ------+----------------------------------------------------------
#
# The \"Label\" field is for categories and subcategories assigned to a
# URL. A colon (:) is used to separate subcategories. Subcategories
# delimited in such a way represent a nested hierarchy. For example, a
# category of \"Development:AppleScript:Mail\" could be thought of as a
# nested list as in:
#
#     - Development
#         - AppleScript
#             - Mail
#
# Optionally list some sample categories/labels below that might not yet
# be used in any web page records. Any sample categories/labels listed
# below will be presented along with categories/labels parsed from the
# web page records as a list to select from when saving new URLs.
#
# The two sections that are surrounded by '#' characters (this one, and
# the one that follows the sample category list) should not be deleted.
#
# BEGIN: sample category/label list (after the '#' delimiter on the next line)
" & _log_header_sep & linefeed & _sample_categories & linefeed & _log_header_sep & "
# END: sample category/label list
#
# BEGIN: Web page records (after the '#' delimiter on the next line)
" & _log_header_sep & linefeed & _log_record_sep & linefeed
			
			_io's append_file(log_file_mac, file_header)
		end _create_log_file
		
		on _set_record_delimiter() --> string
			-- Format the record separator between log entries
			local rule_char, rule_width, name_col_width
			set rule_char to "-"
			set rule_width to 80 -- total width
			set name_col_width to 7 -- name column width only
			return "" & my multiply_text(rule_char, name_col_width - 1) & Â
				"+" & my multiply_text(rule_char, rule_width - name_col_width)
		end _set_record_delimiter
		
		on _format_record() --> void
			local field_sep, final_text
			
			set field_sep to " | "
			set final_text to join_list({Â
				"Date " & field_sep & _format_date(), Â
				"Label" & field_sep & _page_label, Â
				"Title" & field_sep & _page_title, Â
				"URL  " & field_sep & _page_url}, linefeed) & linefeed
			if _page_note is not missing value then
				set final_text to final_text & _format_note(_page_note)
			end if
			
			set _log_record to final_text & _log_record_sep & linefeed
		end _format_record
		
		on _format_date() --> string  (YYYY-MM-DD HH:MM:SS)
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
			return join_list({y, m, d}, "-") & space & join_list({hh, mm, ss}, ":")
		end _format_date
		
		on _format_note(this_text) --> string
			-- Line wrap the Note field (and transliterate non-ASCII characters)
			set s to "LANG=C echo " & quoted form of convert_to_ascii(this_text) Â
				& "| fmt -w 72 | sed '1 s/^/Note  | /; 2,$ s/^/      | /'"
			do shell script s without altering line endings
		end _format_note
	end script
	
	my debug_log(1, return & "--->  new " & this's class & "()" & return)
	
	if __NULL_IO__ then
		set this's _io to make_null_io()
	else
		set this's _io to make_io()
	end if
	
	set this's _log_record_sep to this's _set_record_delimiter()
	
	return this
end make_page_log

on make_web_browser()
	script
		property class : "WebBrowser" -- abstract
		property _page_url : missing value
		property _page_title : missing value
		
		on fetch_page_info() --> void
			error my class & ".fetch_page_info(): abstract method not overridden" number -1717
		end fetch_page_info
		
		on get_url() --> string
			return _page_url
		end get_url
		
		on get_title() --> string
			return _page_title
		end get_title
		
		on set_values(this_url, this_title) --> void
			try
				set _page_url to this_url
				set _page_title to convert_to_ascii(this_title) -- Transliterate non-ASCII
			on error err_msg number err_num
				handle_error(err_msg, err_num)
			end try
		end set_values
		
		on reset_values() --> void
			set _page_url to missing value
			set _page_title to missing value
		end reset_values
		
		on to_string() --> string
			return my short_name
		end to_string
		
		on handle_error(err_msg, err_num) --> void
			set t to "Error: Can't get info from web browser"
			set m to "[" & my class & "] " & err_msg & " (" & err_num & ")"
			display alert t message m buttons {"Cancel"} cancel button 1 as critical
			--display alert t message m buttons {"OK"} default button 1 as critical
			--error err_msg number err_num
		end handle_error
	end script
end make_web_browser

script SafariBrowser
	property class : "SafariBrowser"
	property parent : make_web_browser() -- extends WebBrowser
	property short_name : "Safari"
	
	on fetch_page_info() --> void
		reset_values()
		using terms from application "Safari" -- for compilation
			tell application (my short_name)
				activate
				try
					set this_url to URL of front document
					set this_title to name of first tab of front window whose visible is true
				on error err_msg number err_num
					my handle_error(err_msg, err_num)
				end try
			end tell
		end using terms from
		set_values(this_url, this_title)
	end fetch_page_info
end script

script WebKitBrowser
	property class : "WebKitBrowser"
	property parent : SafariBrowser -- extends SafariBrowser
	property short_name : "WebKit"
end script

script ChromeBrowser
	property class : "ChromeBrowser"
	property parent : make_web_browser() -- extends WebBrowser
	property short_name : "Chrome"
	
	on fetch_page_info() --> void
		reset_values()
		using terms from application "Google Chrome" -- for compilation
			tell application (my short_name)
				activate
				try
					set this_url to URL of (active tab of window 1)
					set this_title to title of (active tab of window 1)
				on error err_msg number err_num
					my handle_error(err_msg, err_num)
				end try
			end tell
		end using terms from
		set_values(this_url, this_title)
	end fetch_page_info
end script

script FirefoxBrowser
	property class : "FirefoxBrowser"
	property parent : make_web_browser() -- extends WebBrowser
	property short_name : "Firefox"
	
	on fetch_page_info() --> void
		reset_values()
		gui_scripting_status() -- Firefox requires GUI scripting
		
		tell application (my short_name)
			activate
			try
				set this_title to name of front window -- Standard Suite
			on error err_msg number err_num
				my handle_error(err_msg, err_num)
			end try
		end tell
		
		try
			set old_clipboard to the clipboard
		end try
		
		-- Firefox has very limited AppleScript support, so GUI
		-- scripting is required.
		tell application "System Events"
			try
				keystroke "l" using {command down} -- select the URL field
				keystroke "c" using {command down} -- copy to clipboard
				keystroke tab -- tab focus away
				keystroke tab
			on error err_msg number err_num
				my handle_error(err_msg, err_num)
			end try
		end tell
		
		delay 1 -- GUI scripting can be slow; give it a second
		set this_url to the clipboard
		
		try
			set the clipboard to old_clipboard
		end try
		
		set_values(this_url, this_title)
	end fetch_page_info
end script

script WebBrowserFactory
	property class : "WebBrowserFactory"
	property supported_browsers : {SafariBrowser, ChromeBrowser, FirefoxBrowser, WebKitBrowser}
	
	on make_browser() --> WebBrowser
		my debug_log(1, "--->  " & my class & ".make_browser()...")
		set cur_app to get_front_app_name()
		repeat with this_browser in supported_browsers
			if cur_app is this_browser's to_string() then
				my debug_log(1, "--->  using " & this_browser's class)
				return this_browser
			end if
		end repeat
		_handle_unsupported(cur_app)
	end make_browser
	
	on _handle_unsupported(cur_app) --> void -- PRIVATE
		set err_msg to "The application " & cur_app & " is not a supported web browser. Currently supported browsers are:" & return & return & tab & get_browser_names()
		set err_num to -2700
		set t to "Error: Unsupported Application (" & err_num & ")"
		set m to err_msg
		if __DEBUG_LEVEL__ > 0 then set m to "[" & my class & "]" & return & m
		display alert t message m buttons {"Cancel"} cancel button 1 as critical
		--display alert t message m buttons {"OK"} default button 1 as critical
		--error err_msg number err_num
	end _handle_unsupported
	
	on get_browser_names() --> string
		set these_names to ""
		repeat with i from 1 to supported_browsers's length
			set this_item to supported_browsers's item i
			if i = 1 then
				set these_names to this_item's to_string()
			else
				set these_names to these_names & ", " & this_item's to_string()
			end if
		end repeat
		return these_names
	end get_browser_names
end script

script FileApp
	property class : "FileApp"
	
	on open_file(this_app, posix_file_path) --> void
		my debug_log(1, my class & ".open_file()")
		
		set posix_file_path to expand_home_path(posix_file_path)
		set mac_file_path to get_mac_path(posix_file_path)
		
		tell application this_app
			activate
			open mac_file_path
		end tell
	end open_file
end script

-- -- -- Settings Models -- -- --

on make_settings()
	(*
		This class should be subclassed rather than modified to
		customize it for a particular application.

		Dependencies:
			* Observable (class)
			* AssociativeList (class)
			* Plist (class)
	*)
	script
		property class : "Settings" -- model
		property parent : make_observable() -- extends Observable
		property _settings : make_associative_list() --> AssociativeList
		property _default_settings : make_associative_list() --> AssociativeList
		property _plist : missing value --> Plist (object)
		
		on init()
			set plist_path to __PLIST_DIR__ & __BUNDLE_ID__ & ".plist"
			set _plist to make_plist(plist_path, me)
		end init
		
		(* == Preferences Methods == *)
		
		on get_default_item(this_key) --> anything
			_default_settings's get_item(this_key)
		end get_default_item
		
		on get_default_keys() --> list
			_default_settings's get_keys()
		end get_default_keys
		
		(* == Observer Pattern == *)
		
		on settings_changed() -- void
			set_changed()
			notify_observers()
		end settings_changed
		
		(* == Associative List Methods (delegate) == *)
		
		on set_pref(this_key, this_value) --> void
			--
			-- Use this method to both set the associative list item and save
			-- the preference to disk
			--
			_settings's set_item(this_key, this_value)
			_plist's write_pref(this_key, this_value)
			settings_changed() -- notify observers
		end set_pref
		
		on set_item(this_key, this_value) --> void
			--
			-- Use this method to only set the associative list item without
			-- saving the preference to disk
			--
			_settings's set_item(this_key, this_value)
			settings_changed() -- notify observers
		end set_item
		
		on get_item(this_key) --> anything
			_settings's get_item(this_key)
		end get_item
		
		on count_items() --> integer
			_settings's count_items()
		end count_items
		
		on delete_item(this_key) --> void
			_settings's delete_item(this_key)
			settings_changed()
		end delete_item
		
		on get_keys() --> list
			_settings's get_keys()
		end get_keys
		
		on get_values() --> list
			_settings's get_values()
		end get_values
		
		on key_exists(this_key) --> boolean
			_settings's key_exists(this_key)
		end key_exists
		
		(* == Plist File Methods (delegate) == *)
		
		on read_settings(plist_keys) --> void (modifies associative list)
			_plist's read_settings(plist_keys)
		end read_settings
		
		on write_settings() --> void (writes to file)
			_plist's write_settings()
		end write_settings
		
		(*on set_and_write_pref(this_key, this_value) --> void (modifies ass. list, saves file)
			_plist's set_and_write_pref(this_key, this_value)
			settings_changed()
		end set_and_write_pref*)
		
		on read_pref(pref_key) --> anything
			_plist's read_pref(pref_key)
		end read_pref
		
		on write_pref(pref_key, pref_value) --> void (writes to file)
			_plist's write_pref(pref_key, pref_value)
		end write_pref
	end script
end make_settings

on make_page_log_settings()
	script
		property class : "PageLogSettings" -- model
		property parent : make_settings() -- extends Settings
		
		-- Define all preference keys here
		property _log_file_key : "logFile" -- required pref
		property _text_editor_key : "textEditor" -- required pref
		property _file_viewer_key : "fileViewer" -- required pref
		--
		property _warn_before_editing_key : "warnBeforeEditing" -- optional state
		property _last_category_key : "lastCategory" -- optional state
		
		property _optional_keys : {_last_category_key, _warn_before_editing_key} --> array
		
		on init()
			continue init()
			
			-- Initialize default values for required preferences
			my _default_settings's set_item(_text_editor_key, "TextEdit")
			my _default_settings's set_item(_file_viewer_key, "Safari")
			my _default_settings's set_item(_log_file_key, Â
				POSIX path of (path to application support folder from user domain) Â
				& __NAMESPACE__ & "/" & __SCRIPT_NAME__ & "/urls.txt")
		end init
		
		(* == Preferences Methods == *)
		
		on get_default_log_file() --> string
			my _default_settings's get_item(_log_file_key)
		end get_default_log_file
		
		on get_default_file_viewer() --> string
			my _default_settings's get_item(_file_viewer_key)
		end get_default_file_viewer
		
		on get_default_text_editor() --> string
			my _default_settings's get_item(_text_editor_key)
		end get_default_text_editor
		
		on get_optional_keys() --> list
			return _optional_keys
		end get_optional_keys
		
		on get_log_file_key() --> string
			return _log_file_key
		end get_log_file_key
		
		on get_file_viewer_key() --> string
			return _file_viewer_key
		end get_file_viewer_key
		
		on get_text_editor_key() --> string
			return _text_editor_key
		end get_text_editor_key
		
		on get_warn_before_editing_key() --> string
			return _warn_before_editing_key
		end get_warn_before_editing_key
		
		on get_log_file() --> string
			my _settings's get_item(_log_file_key)
		end get_log_file
		
		on get_file_viewer() --> string
			my _settings's get_item(_file_viewer_key)
		end get_file_viewer
		
		on get_text_editor() --> string
			my _settings's get_item(_text_editor_key)
		end get_text_editor
		
		on warn_before_editing() --> boolean
			try
				my _settings's get_item(_warn_before_editing_key)
			on error err_msg number err_num -- set, write and return default
				continue set_pref(_warn_before_editing_key, true) -- call super
				--display alert "Error (" & err_num & ")" message err_msg as warning
				return true -- the default value
			end try
		end warn_before_editing
		
		(* == State Methods == *)
		
		on get_last_category_key() --> string
			return _last_category_key
		end get_last_category_key
		
		on get_last_category() --> string
			try
				my _settings's get_item(_last_category_key)
			on error
				return missing value
			end try
		end get_last_category
		
		(* == Associative List Methods (delegate) == *)
		
		on set_pref(this_key, this_value) --> void
			--
			-- Use this method to both set the associative list item and save
			-- the preference to disk
			--
			set this_value to _handle_log_file(this_key, this_value)
			continue set_pref(this_key, this_value)
		end set_pref
		
		on set_item(this_key, this_value) --> void
			--
			-- Use this method to only set the associative list item without
			-- saving the preference to disk
			--
			set this_value to _handle_log_file(this_key, this_value)
			continue set_item(this_key, this_value)
		end set_item
		
		(* == Utility Methods == *)
		
		on _handle_log_file(this_key, this_value) --> string -- PRIVATE
			if this_key is _log_file_key then
				set this_value to my shorten_home_path(this_value)
			end if
			return this_value
		end _handle_log_file
	end script
end make_page_log_settings

on make_plist(plist_path, settings_model)
	(*
		Dependencies:
			* Settings (class)
			* split_path_into_dir_and_file() function (supplied by main script)
			* create_directory() function (supplied by main script)
	*)
	script
		property class : "Plist"
		property _plist_path : plist_path
		property _model : settings_model --> Settings
		
		-- Get the values for each key in the given list
		on read_settings(plist_keys) --> void (modifies associative list)
			my debug_log(1, "[debug] read_settings()")
			try
				repeat with this_key in plist_keys
					set this_key to this_key's contents -- dereference implicit loop reference
					set this_value to read_pref(this_key)
					_model's set_item(this_key, this_value)
				end repeat
			on error err_msg number err_num
				error "Can't read_settings(): " & err_msg number err_num
			end try
			my debug_log(1, "[debug] read_settings(): done")
		end read_settings
		
		on write_settings() --> void (writes to file)
			try
				repeat with this_key in _model's get_keys()
					set this_key to this_key's contents -- dereference implicit loop reference
					write_pref(this_key, _model's get_item(this_key))
				end repeat
			on error err_msg number err_num
				error "Can't write_settings(): " & err_msg number err_num
			end try
		end write_settings
		
		(*on set_and_write_pref(this_key, this_value) --> void (modifies ass. list, saves file)
			_model's set_item(this_key, this_value) -- store value in object
			write_pref(this_key, this_value) -- write value to file
		end set_and_write_pref*)
		
		on read_pref(pref_key) --> anything
			my debug_log(1, "[debug] read_pref()")
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
		
		on write_pref(pref_key, pref_value) --> void (writes to file)
			--
			-- :XXX: This function only sets string types now. If need
			-- to set other types, write a function to detect the type
			-- of the given value. (I've already got one somewhere.)
			-- UPDATE: It actually appears to be doing the right thing;
			-- not sure why. It appears that the value type is being
			-- detected and the "kind" automatically overridden. I only
			-- tested strings, integers and booleans though.
			--
			my debug_log(1, "[debug] write_pref(" & pref_key & ", " & pref_value & ")")
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
							my debug_log(1, tab & "[debug] write_pref(): writing new item")
							make new property list item at end of property list items with properties {kind:string, name:pref_key, value:pref_value}
						end try
					end tell
				end tell
			on error err_msg number err_num
				error "Can't write_pref(): " & err_msg number err_num
			end try
		end write_pref
		
		on _new_plist() -- returns a 'property list file' -- PRIVATE
			my debug_log(1, "[debug] _new_plist()")
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
end make_plist

(* ==== Controller ==== *)

-- -- -- Common Controllers -- -- --

on make_navigation_controller()
	script this
		property class : "NavigationController"
		property controller_stack : make_named_stack("ControllerStack") --> Stack
		property controller_history : make_named_stack("ControllerHistory") --> Stack
		
		(* == Private Methods == *)
		
		on _push_controller_with_history(controller_array) --> void -- PRIVATE
			set {current_controller, next_controller} to controller_array
			controller_history's push(current_controller) -- save this controller in history
			controller_stack's push(next_controller) -- push next controller onto stack
		end _push_controller_with_history
		
		on _push_controller_without_history(controller_array) --> void -- PRIVATE
			set {next_controller} to controller_array
			controller_stack's push(next_controller) -- push next controller onto stack
		end _push_controller_without_history
		
		(* == Convenience Methods == *)
		
		on push_controller(controller_array) --> void
			if controller_array's class is not list then
				error my class & ".push_controller(): Invalid parameter." number -1704
			end if
			-- Simulate method overloading. Delegate to another
			-- method depending on number of items in list.
			if controller_array's length is 2 then
				_push_controller_with_history(controller_array)
			else if controller_array's length is 1 then
				_push_controller_without_history(controller_array)
			else
				error my class & ".push_controller(): More than two items in list." number -1704
			end if
		end push_controller
		
		on push_root_controller(next_controller) --> void
			controller_history's reset() -- clear the history stack
			controller_stack's reset() -- clear the controller stack
			controller_stack's push(next_controller) -- push root controller onto stack
		end push_root_controller
		
		on go_back() --> void
			-- Pop the top controller off the history stack and push it
			-- onto the pending controller stack.
			controller_stack's push(controller_history's pop())
		end go_back
		
		(* == Controller Stack Methods == *)
		
		on pop() --> controller object
			controller_stack's pop()
		end pop
		
		on peek() --> controller object
			controller_stack's peek()
		end peek
		
		on is_empty() --> boolean
			controller_stack's is_empty()
		end is_empty
		
		on to_string() --> string
			controller_stack's to_string()
		end to_string
		
		(* == History Stack Methods == *)
		
		on push_history(this_controller) --> void
			controller_history's push(this_controller)
		end push_history
		
		on pop_history() --> controller object
			controller_history's pop()
		end pop_history
		
		on peek_history() --> controller object
			controller_history's peek()
		end peek_history
		
		on history_is_empty() --> boolean
			controller_history's is_empty()
		end history_is_empty
		
		on history_to_string() --> string
			controller_history's to_string()
		end history_to_string
	end script
	
	my debug_log(1, return & "--->  new " & this's class & "()")
	return this
end make_navigation_controller

on make_base_controller()
	script
		property class : "BaseController"
		property other_controllers : {} --> array
		
		-- subclasses must define a '_nav_controller' property
		
		on set_controllers(these_controllers) --> void
			set my other_controllers to these_controllers
		end set_controllers
		
		on go_back() --> void
			my _nav_controller's go_back()
		end go_back
		
		on to_string() --> string
			return my class
		end to_string
	end script
end make_base_controller

-- -- -- Main App Controllers -- -- --

on make_file_editor_controller(navigation_controller, settings_model)
	script this
		property class : "FileEditorController"
		property parent : make_base_controller() -- extends BaseController
		property _nav_controller : navigation_controller
		property _model : settings_model
		property _app : FileApp
		property _view : missing value
		
		on run
			my debug_log(1, return & "--->  running " & my class & "...")
			if _model's warn_before_editing() then
				if _view is missing value then set _view to make_file_edit_view(me, _model)
				set ret_val to _view's create_view() --> returns boolean
			else
				launch_app()
				set ret_val to false
			end if
			my debug_log(1, "--->  finished " & my class & return)
			return ret_val --> false ends controller loop and exits script
		end run
		
		on launch_app() --> void
			my debug_log(1, my class & ".launch_app()")
			set this_app to _model's get_text_editor()
			set this_file to _model's get_log_file()
			_app's open_file(this_app, this_file)
		end launch_app
		
		on disable_warning() --> void
			my debug_log(1, my class & ".disable_warning()")
			_model's set_pref(_model's get_warn_before_editing_key(), false)
			launch_app()
		end disable_warning
	end script
	
	my debug_log(1, return & "--->  new " & this's class & "()")
	return this
end make_file_editor_controller

on make_file_viewer_controller(navigation_controller, settings_model)
	script this
		property class : "FileViewerController"
		property parent : make_base_controller() -- extends BaseController
		property _nav_controller : navigation_controller
		property _model : settings_model
		property _app : FileApp
		property _view : missing value
		
		on run
			my debug_log(1, return & "--->  running " & my class & "...")
			launch_app()
			my debug_log(1, "--->  finished " & my class & return)
			return false --> false ends controller loop and exits script
		end run
		
		on launch_app() --> void
			my debug_log(1, my class & ".launch_app()")
			set this_app to _model's get_file_viewer()
			set this_file to _model's get_log_file()
			_app's open_file(this_app, this_file)
		end launch_app
	end script
	
	my debug_log(1, return & "--->  new " & this's class & "()")
	return this
end make_file_viewer_controller

on make_about_controller()
	script this
		property class : "AboutController"
		property parent : make_base_controller() -- extends BaseController
		property _view : missing value
		
		on run
			my debug_log(1, return & "--->  running " & my class & "...")
			if _view is missing value then set _view to make_about_view(me)
			set ret_val to _view's create_view() --> returns boolean
			my debug_log(1, "--->  finished " & my class & return)
			return ret_val --> false ends controller loop and exits script
		end run
		
		on go_to_website() --> void
			my debug_log(1, my class & ".go_to_website()")
			tell me to open location __SCRIPT_WEBSITE__
		end go_to_website
	end script
	
	my debug_log(1, return & "--->  new " & this's class & "()")
	return this
end make_about_controller

on make_help_controller(navigation_controller, settings_model)
	script this
		property class : "HelpController"
		property parent : make_base_controller() -- extends BaseController
		property _nav_controller : navigation_controller
		property _model : settings_model
		property _view : missing value
		
		on run
			my debug_log(1, return & "--->  running " & my class & "...")
			if _view is missing value then set _view to make_help_view(me, _model)
			_view's create_view()
			my debug_log(1, "--->  finished " & my class & return)
			return true
		end run
		
		on change_settings() --> void
			_nav_controller's push_controller({my other_controllers's item 1})
		end change_settings
	end script
	
	my debug_log(1, return & "--->  new " & this's class & "()")
	return this
end make_help_controller

on make_label_help_controller()
	script this
		property class : "LabelHelpController"
		property parent : make_base_controller() -- extends BaseController
		property _view : missing value
		
		on run
			my debug_log(1, return & "--->  running " & my class & "...")
			if _view is missing value then set _view to make_label_help_view()
			_view's create_view()
			my debug_log(1, "--->  finished " & my class & return)
			return true
		end run
	end script
	
	my debug_log(1, return & "--->  new " & this's class & "()")
	return this
end make_label_help_controller

on make_title_controller(navigation_controller, main_model)
	script this
		property class : "TitleController"
		property parent : make_base_controller() -- extends BaseController
		property _nav_controller : navigation_controller
		property _model : main_model
		property _view : missing value
		
		on run
			my debug_log(1, return & "--->  running " & my class & "...")
			if _view is missing value then set _view to make_title_view(me, _model)
			_view's create_view()
			my debug_log(1, "--->  finished " & my class & return)
			return true
		end run
		
		on show_help() --> void
			--
			-- We want to return to the current controller after the
			-- help controller is finished, so push this controller back
			-- onto the stack first, then the help controller.
			--
			_nav_controller's push_controller({me})
			_nav_controller's push_controller({my other_controllers's item 1})
		end show_help
		
		on set_page_title(this_value) --> void
			_model's set_page_title(this_value)
			_nav_controller's push_controller({me, my other_controllers's item 2})
		end set_page_title
	end script
	
	my debug_log(1, return & "--->  new " & this's class & "()")
	return this
end make_title_controller

on make_url_controller(navigation_controller, main_model)
	script this
		property class : "URLController"
		property parent : make_base_controller() -- extends BaseController
		property _nav_controller : navigation_controller
		property _model : main_model
		property _view : missing value
		
		on run
			my debug_log(1, return & "--->  running " & my class & "...")
			if _view is missing value then set _view to make_url_view(me, _model)
			_view's create_view()
			my debug_log(1, "--->  finished " & my class & return)
			return true
		end run
		
		on set_page_url(this_value) --> void
			_model's set_page_url(this_value)
			_nav_controller's push_controller({me, my other_controllers's item 1})
		end set_page_url
	end script
	
	my debug_log(1, return & "--->  new " & this's class & "()")
	return this
end make_url_controller

on make_label_base_controller()
	script this
		property class : "LabelBaseController"
		property parent : make_base_controller() -- extends BaseController
		
		on push_controller(i) --> void
			my _nav_controller's push_controller({me, my other_controllers's item i})
		end push_controller
		
		on push_controller_and_return(i) --> void
			-- Return to current controller after next controller is
			-- finished.
			my _nav_controller's push_controller({me})
			my _nav_controller's push_controller({my other_controllers's item i})
		end push_controller_and_return
	end script
end make_label_base_controller

on make_label_controller(navigation_controller, main_model, label_base_view)
	script this
		property class : "LabelController"
		property parent : make_label_base_controller() -- extends BaseController
		property _nav_controller : navigation_controller
		property _model : main_model
		property _view : missing value
		property _label_base_view : label_base_view
		
		on run
			my debug_log(1, return & "--->  running " & my class & "...")
			if _model's get_root_categories()'s length < 2 Â
				and _model's get_sub_categories()'s length < 2 then
				_skip_to_edit_label()
			else
				if _view is missing value then set _view to make_label_view(me, _label_base_view)
				_view's create_view()
			end if
			my debug_log(1, "--->  finished " & my class & return)
			return true
		end run
		
		on _skip_to_edit_label() --> void -- PRIVATE
			_nav_controller's push_controller({my other_controllers's item 3})
		end _skip_to_edit_label
		
		on set_chosen_root(this_value) --> void
			_model's set_chosen_root_category(this_value)
			push_controller(1)
		end set_chosen_root
		
		on choose_from_all() --> void
			push_controller(2)
		end choose_from_all
		
		on edit_label() --> void
			push_controller(3)
		end edit_label
		
		on edit_file() --> void
			push_controller(4)
		end edit_file
		
		on view_file() --> void
			push_controller(5)
		end view_file
		
		on change_settings() --> void
			push_controller_and_return(6)
		end change_settings
		
		on show_about() --> void
			push_controller_and_return(7)
		end show_about
		
		on show_help() --> void
			push_controller_and_return(8)
		end show_help
		
		on show_category_help() --> void
			push_controller_and_return(9)
		end show_category_help
	end script
	
	my debug_log(1, return & "--->  new " & this's class & "()")
	return this
end make_label_controller

on make_sub_label_controller(navigation_controller, main_model, label_base_view)
	script this
		property class : "SubLabelController"
		property parent : make_label_base_controller() -- extends BaseController
		property _nav_controller : navigation_controller
		property _model : main_model
		property _view : missing value
		property _label_base_view : label_base_view
		
		on run
			my debug_log(1, return & "--->  running " & my class & "...")
			if _model's get_sub_categories()'s length < 2 then
				_model's set_chosen_category(_model's get_chosen_root_category())
				_skip_to_edit_label()
			else
				if _view is missing value then set _view to make_sub_label_view(me, _label_base_view)
				_view's create_view()
			end if
			my debug_log(1, "--->  finished " & my class & return)
			return true
		end run
		
		on _skip_to_edit_label() --> void -- PRIVATE
			tell _nav_controller
				-- This dialog always follows the root category dialog,
				-- so remove that last controller from the navigation
				-- history if it also has less than two items.
				if _model's get_root_categories()'s length < 2 then pop_history()
				
				-- Now go to the next controller w/o adding this
				-- controller to the history.
				push_controller({my other_controllers's item 1})
			end tell
		end _skip_to_edit_label
		
		on set_chosen_category(this_value) --> void
			_model's set_chosen_category(this_value)
			push_controller(1)
		end set_chosen_category
		
		on choose_from_all() --> void
			push_controller(2)
		end choose_from_all
		
		on edit_file() --> void
			push_controller(3)
		end edit_file
		
		on view_file() --> void
			push_controller(4)
		end view_file
		
		on change_settings() --> void
			push_controller_and_return(5)
		end change_settings
		
		on show_about() --> void
			push_controller_and_return(6)
		end show_about
		
		on show_help() --> void
			push_controller_and_return(7)
		end show_help
		
		on show_category_help() --> void
			push_controller_and_return(8)
		end show_category_help
	end script
	
	my debug_log(1, return & "--->  new " & this's class & "()")
	return this
end make_sub_label_controller

on make_all_label_controller(navigation_controller, main_model, label_base_view)
	script this
		property class : "AllLabelController"
		property parent : make_label_base_controller() -- extends BaseController
		property _nav_controller : navigation_controller
		property _model : main_model
		property _view : missing value
		property _label_base_view : label_base_view
		
		on run
			my debug_log(1, return & "--->  running " & my class & "...")
			if _model's get_all_categories()'s length < 2 then
				_skip_to_edit_label()
			else
				if _view is missing value then set _view to make_all_label_view(me, _label_base_view)
				_view's create_view()
			end if
			my debug_log(1, "--->  finished " & my class & return)
			return true
		end run
		
		on _skip_to_edit_label() --> void -- PRIVATE
			tell _nav_controller
				-- This dialog always follows at least one other list
				-- dialog, so remove the last controller from the
				-- navigation history.
				pop_history()
				
				-- If the previous list dialog was a subcategory list,
				-- then there is still a root category controller that
				-- needs to be removed from the history.
				if peek_history()'s class is "LabelController" then pop_history()
				
				-- Okay, now go to the next controller w/o adding this
				-- controller to the history.
				push_controller({my other_controllers's item 1})
			end tell
		end _skip_to_edit_label
		
		on set_chosen_category(this_value) --> void
			_model's set_chosen_category(this_value)
			push_controller(1)
		end set_chosen_category
		
		on edit_file() --> void
			push_controller(2)
		end edit_file
		
		on view_file() --> void
			push_controller(3)
		end view_file
		
		on change_settings() --> void
			push_controller_and_return(4)
		end change_settings
		
		on show_about() --> void
			push_controller_and_return(5)
		end show_about
		
		on show_help() --> void
			push_controller_and_return(6)
		end show_help
		
		on show_category_help() --> void
			push_controller_and_return(7)
		end show_category_help
	end script
	
	my debug_log(1, return & "--->  new " & this's class & "()")
	return this
end make_all_label_controller

on make_label_edit_controller(navigation_controller, main_model)
	script this
		property class : "LabelEditController"
		property parent : make_base_controller() -- extends BaseController
		property _nav_controller : navigation_controller
		property _model : main_model
		property _view : missing value
		
		on run
			my debug_log(1, return & "--->  running " & my class & "...")
			if _view is missing value then set _view to make_label_edit_view(me, _model)
			_view's create_view()
			my debug_log(1, "--->  finished " & my class & return)
			return true
		end run
		
		on set_chosen_category(this_value) --> void
			_model's set_page_label(this_value)
			_model's set_chosen_category(this_value)
			_nav_controller's push_controller({me, my other_controllers's item 1})
		end set_chosen_category
	end script
	
	my debug_log(1, return & "--->  new " & this's class & "()")
	return this
end make_label_edit_controller

on make_note_controller(navigation_controller, main_model)
	script this
		property class : "NoteController"
		property parent : make_base_controller() -- extends BaseController
		property _nav_controller : navigation_controller
		property _model : main_model
		property _view : missing value
		
		on run
			my debug_log(1, return & "--->  running " & my class & "...")
			if _view is missing value then set _view to make_note_view(me, _model)
			_view's create_view()
			my debug_log(1, "--->  finished " & my class & return)
			return true
		end run
		
		on set_page_note(this_value) --> void
			if this_value is not missing value then _model's set_page_note(this_value)
		end set_page_note
	end script
	
	my debug_log(1, return & "--->  new " & this's class & "()")
	return this
end make_note_controller

-- -- -- Settings Controllers -- -- --

on make_settings_controller(settings_model, app_model)
	script this
		property class : "SettingsController"
		property _model : settings_model
		property _app_model : app_model
		property _is_first_run : missing value --> boolean
		property _has_run_this_session : false --> boolean
		
		-- Controllers instantiated during construction:
		property nav_controller : make_navigation_controller()
		property app_settings_controller : missing value
		property file_settings_controller : missing value
		-- Controllers instantiated on first run:
		property main_controller : missing value
		
		on run
			my debug_log(1, return & "--->  running " & my class & "...")
			
			-- Read required keys
			try
				_model's read_settings(_model's get_default_keys())
				set _is_first_run to false
			on error err_msg number err_num
				set _is_first_run to true
			end try
			
			-- Read optional keys (such as saved state)
			repeat with this_key in _model's get_optional_keys()
				set this_key to this_key's contents -- dereference
				my debug_log(2, my class & ": trying to read " & this_key & " pref")
				try
					set this_value to _model's read_pref(this_key)
					my debug_log(2, my class & ": " & this_key & " = " & this_value)
					_model's set_item(this_key, this_value)
				end try
			end repeat
			
			-- Run the settings user interface only if requested by
			-- the user or if this is the first time running the script
			if _has_run_this_session or _is_first_run then
				_show_ui()
			else
				set _has_run_this_session to true
				my debug_log(1, my class & ": skipping settings UI at startup")
			end if
			
			my debug_log(1, "--->  finished " & my class & return)
			return true
		end run
		
		on _show_ui() --> void
			if main_controller is missing value then
				-- Create main settings view controller
				set main_controller to make_settings_main_controller(nav_controller, _model)
				-- Inject any controller dependencies
				main_controller's set_controllers({app_settings_controller, file_settings_controller})
			end if
			
			if _is_first_run then
				set root_controller to make_settings_first_controller(nav_controller, _model)
				root_controller's set_controllers({main_controller})
			else
				set root_controller to main_controller
			end if
			
			-- Load first controller
			nav_controller's push_root_controller(root_controller)
			
			my debug_log(1, my class & "'s History Stack: " & nav_controller's history_to_string())
			my debug_log(1, my class & "'s Controller Stack: " & nav_controller's to_string())
			
			repeat while not nav_controller's is_empty()
				set this_controller to nav_controller's pop() -- Pop controller off top of stack
				run this_controller -- Call its run() method
				
				my debug_log(1, my class & "'s History Stack: " & nav_controller's history_to_string())
				my debug_log(1, my class & "'s Controller Stack: " & nav_controller's to_string())
			end repeat
			
			if _is_first_run then -- clean-up after first run
				set _is_first_run to false
				set _has_run_this_session to true
			end if
		end _show_ui
		
		on _create_controllers() --> void -- PRIVATE
			-- Controllers for the preference editing dialogs:
			set app_settings_controller to make_settings_app_controller(nav_controller, _model)
			set file_settings_controller to make_settings_file_controller(nav_controller, _model, _app_model)
		end _create_controllers
		
		on to_string() --> string
			return my class
		end to_string
	end script
	
	my debug_log(1, return & "--->  new " & this's class & "()")
	this's _create_controllers()
	return this
end make_settings_controller

on make_settings_first_controller(navigation_controller, settings_model)
	script this
		property class : "SettingsFirstController"
		property parent : make_base_controller() -- extends BaseController
		property _nav_controller : navigation_controller
		property _model : settings_model
		property _view : missing value
		
		on run
			my debug_log(1, return & "--->  running " & my class & "...")
			if _view is missing value then set _view to make_settings_first_view(me, _model)
			_view's create_view()
			my debug_log(1, "--->  finished " & my class & return)
			return true
		end run
		
		on use_defaults() --> void
			_set_missing_prefs()
		end use_defaults
		
		on change_settings() --> void
			_set_missing_prefs() -- the main view will need the defaults too
			_nav_controller's push_controller({me, my other_controllers's item 1})
		end change_settings
		
		on _set_missing_prefs() --> void -- PRIVATE
			repeat with this_key in _model's get_default_keys()
				set this_key to this_key's contents -- dereference implicit loop reference
				try
					_model's get_item(this_key)
				on error
					my debug_log(1, my class & ".set_missing_prefs(): setting missing pref")
					_model's set_pref(this_key, _model's get_default_item(this_key))
				end try
			end repeat
		end _set_missing_prefs
	end script
	
	my debug_log(1, return & "--->  new " & this's class & "()")
	return this
end make_settings_first_controller

on make_settings_main_controller(navigation_controller, settings_model)
	script this
		property class : "SettingsMainController"
		property parent : make_base_controller() -- extends BaseController
		property _nav_controller : navigation_controller
		property _model : settings_model
		property _view : missing value
		
		on run
			my debug_log(1, return & "--->  running " & my class & "...")
			if _view is missing value then set _view to make_settings_main_view(me, _model)
			_view's create_view()
			my debug_log(1, "--->  finished " & my class & return)
			return true
		end run
		
		on choose_app() --> void
			_nav_controller's push_controller({me, my other_controllers's item 1})
		end choose_app
		
		on choose_file() --> void
			_nav_controller's push_controller({me, my other_controllers's item 2})
		end choose_file
	end script
	
	my debug_log(1, return & "--->  new " & this's class & "()")
	return this
end make_settings_main_controller

on make_settings_app_controller(navigation_controller, settings_model)
	script this
		property class : "SettingsAppController"
		property parent : make_base_controller() -- extends BaseController
		property _nav_controller : navigation_controller
		property _model : settings_model
		property _view : missing value
		property _editor_controller : missing value
		property _viewer_controller : missing value
		
		on run
			my debug_log(1, return & "--->  running " & my class & "...")
			if _view is missing value then
				set _view to make_settings_app_view(me, _model)
			end if
			_view's create_view()
			my debug_log(1, "--->  finished " & my class & return)
			return true
		end run
		
		on choose_editor() --> void
			if _editor_controller is missing value then -- lazy instantiation
				set _editor_controller to make_settings_editor_controller(_nav_controller, _model)
			end if
			_nav_controller's push_controller({me, _editor_controller})
		end choose_editor
		
		on choose_viewer() --> void
			if _viewer_controller is missing value then -- lazy instantiation
				set _viewer_controller to make_settings_viewer_controller(_nav_controller, _model)
			end if
			_nav_controller's push_controller({me, _viewer_controller})
		end choose_viewer
	end script
	
	my debug_log(1, return & "--->  new " & this's class & "()")
	return this
end make_settings_app_controller

on make_settings_app_base_controller()
	script this
		property class : "SettingsAppBaseController" -- abstract
		property parent : make_base_controller() -- extends BaseController
		
		on run
			-- subclasses must instantiate a view first here, then call super
			my _view's create_view()
			my debug_log(1, "--->  finished " & my class & return)
			return true
		end run
		
		on set_app(_val) --> void
			my _model's set_pref(my _app_key, _val)
			go_back()
		end set_app
	end script
	
	my debug_log(1, return & "--->  new " & this's class & "()")
	return this
end make_settings_app_base_controller

on make_settings_editor_controller(navigation_controller, settings_model)
	script this
		property class : "SettingsEditorController" -- concrete
		property parent : make_settings_app_base_controller() -- extends SettingsAppBaseController
		property _nav_controller : navigation_controller
		property _model : settings_model
		property _view : missing value
		property _app_key : _model's get_text_editor_key()
		
		on run
			my debug_log(1, return & "--->  running " & my class & "...")
			if _view is missing value then
				set _view to make_settings_editor_view(me, _model)
			end if
			continue run -- call superclass
		end run
	end script
	
	my debug_log(1, return & "--->  new " & this's class & "()")
	return this
end make_settings_editor_controller

on make_settings_viewer_controller(navigation_controller, settings_model)
	script this
		property class : "SettingsViewerController" -- concrete
		property parent : make_settings_app_base_controller() -- extends SettingsAppBaseController
		property _nav_controller : navigation_controller
		property _model : settings_model
		property _view : missing value
		property _app_key : _model's get_file_viewer_key()
		
		on run
			my debug_log(1, return & "--->  running " & my class & "...")
			if _view is missing value then
				set _view to make_settings_viewer_view(me, _model)
			end if
			continue run -- call superclass
		end run
	end script
	
	my debug_log(1, return & "--->  new " & this's class & "()")
	return this
end make_settings_viewer_controller

on make_settings_file_controller(navigation_controller, settings_model, app_model)
	script this
		property class : "SettingsFileController"
		property parent : make_base_controller() -- extends BaseController
		property _nav_controller : navigation_controller
		property _model : settings_model
		property _app_model : app_model
		property _view : missing value
		
		on run
			my debug_log(1, return & "--->  running " & my class & "...")
			if _view is missing value then
				set _view to make_settings_file_view(me, _model)
			end if
			_view's create_view()
			my debug_log(1, "--->  finished " & my class & return)
			return true
		end run
		
		on set_log_file(_val) --> void
			_model's set_pref(_model's get_log_file_key(), _val)
			_app_model's parse_log()
			delay 1 -- script needs time to process before next dialog
			go_back()
		end set_log_file
		
		on reset_warning() --> void
			my debug_log(1, my class & ".reset_warning()")
			_model's set_pref(_model's get_warn_before_editing_key(), true)
			delay 1 -- script needs time to process before next dialog
			go_back()
		end reset_warning
	end script
	
	my debug_log(1, return & "--->  new " & this's class & "()")
	return this
end make_settings_file_controller

(* ==== View ==== *)

-- -- -- Common Views -- -- --

on make_base_view()
	script
		property class : "BaseView"
		
		property _app_description : "This script will append the URL of the front web browser document to a text file along with the current date/time, the title of the web page and a user-definable category. The script can also open the file for viewing or editing in the apps of your choice (although care should be taken when editing to not alter the format of the file)."
		
		(* == Unicode Characters for Views == *)
		
		property u_dash : Çdata utxt2500È as Unicode text -- BOX DRAWINGS LIGHT HORIZONTAL
		
		property u_back : Çdata utxt276EÈ as Unicode text -- HEAVY LEFT-POINTING ANGLE QUOTATION MARK ORNAMENT
		-- property u_back : Çdata utxt25C0È as Unicode text -- BLACK LEFT-POINTING TRIANGLE
		--property u_back : Çdata utxt2B05È as Unicode text -- LEFTWARDS BLACK ARROW
		
		property u_bullet : Çdata utxt25CFÈ as Unicode text -- BLACK CIRCLE
		--property u_bullet : "¥" -- standard bullet, but slightly smaller than Unicode black circle
		--property u_bullet : Çdata utxt2043È as Unicode text -- HYPHEN BULLET
		--property u_bullet : Çdata utxt25A0È as Unicode text -- BLACK SQUARE
		--property u_bullet : Çdata utxt25B6È as Unicode text -- BLACK RIGHT-POINTING TRIANGLE
		--property u_bullet : Çdata utxt27A1È as Unicode text -- BLACK RIGHTWARDS ARROW
		
		(* == View Components == *)
		
		property u_back_btn : "" & u_back & "  Back" -- for buttons
		--property u_back_item : " " & u_back_btn -- for menu items
		property u_bullet_item : " " & u_bullet & "  " -- for menu items
		
		-- Making buttons wider is the only way to widen text input
		-- fields in AppleScript dialogs. It looks a little stupid, but
		-- it makes the text input fields a little more functional.
		--
		property btn_pad : multiply_text(tab, 5)
		property back_btn_pad : u_back_btn & btn_pad
		property ok_btn_pad : "OK" & btn_pad
		property next_btn_pad : "Next..." & btn_pad
		property save_btn_pad : "Save" & btn_pad
		property help_btn_pad : "Help" & btn_pad
		--property cancel_btn_pad : "Cancel" & btn_pad -- this prevents cmd-. from working
		
		(* == Methods == *)
		
		on create_view() --> void
			error my class & ".create_view(): abstract method not overridden" number -1717
		end create_view
		
		on handle_cancel_as_back(err_msg, err_num) --> void
			if err_num is -128 then -- treat Cancel as "Back" button
				my create_view()
			else
				error err_msg number err_num
			end if
		end handle_cancel_as_back
	end script
end make_base_view

-- -- -- Main App Views -- -- --

on make_about_view(view_controller)
	script
		property class : "AboutView"
		property parent : make_base_view() -- extends BaseView
		property _controller : view_controller
		
		property _title : __SCRIPT_NAME__
		property _buttons : {"Go to Website", "Cancel", "OK"}
		property _prompt : missing value
		
		on create_view() --> void
			_set_prompt()
			with timeout of (10 * 60) seconds
				display alert _title message _prompt buttons _buttons default button 3 cancel button 2
				set action_event to result's button returned
				action_performed(action_event) --> returns boolean
			end timeout
		end create_view
		
		on action_performed(action_event) --> void
			if action_event is false then error number -128 -- User canceled
			
			set action_event to action_event as string
			if action_event is _buttons's item 1 then
				_controller's go_to_website()
				return false --> stop controller loop
			end if
			return true --> continue controller loop
		end action_performed
		
		on _set_prompt() --> void -- PRIVATE
			set _prompt to Â
				"Save timestamped and categorized URLs to a log file." & return & return Â
				& "Version " & __SCRIPT_VERSION__ & return & return & return & return Â
				& __SCRIPT_COPYRIGHT__
		end _set_prompt
	end script
end make_about_view

on make_help_view(view_controller, settings_model)
	script this
		property class : "HelpView"
		property parent : make_base_view() -- extends BaseView
		property _controller : view_controller
		property _model : settings_model
		
		property _log_file : missing value
		property _file_viewer : missing value
		property _text_editor : missing value
		
		property _title : __SCRIPT_NAME__ & " Help"
		property _prompt : missing value
		property _buttons : {"Preferences...", "Cancel", "OK"}
		
		on create_view() --> void
			_set_prompt()
			with timeout of (10 * 60) seconds
				display alert _title message _prompt buttons _buttons cancel button 2 default button 3
				set action_event to result's button returned
				action_performed(action_event)
			end timeout
		end create_view
		
		on action_performed(action_event) --> void
			if action_event is false then error number -128 -- User canceled
			
			set action_event to action_event as string
			if action_event is _buttons's item 1 then _controller's change_settings()
		end action_performed
		
		on update() --> void  (Observer Pattern)
			set _log_file to _model's get_log_file()
			set _file_viewer to _model's get_file_viewer()
			set _text_editor to _model's get_text_editor()
		end update
		
		on _set_prompt() --> void -- PRIVATE
			set _prompt to my _app_description & " The current settings are:" & return & return Â
				& tab & "URLs File:    " & _log_file & return & return Â
				& tab & "File Viewer:  " & _file_viewer & return & return Â
				& tab & "Text Editor:  " & _text_editor & return & return Â
				& "You can change those settings by clicking \"Preferences\"."
		end _set_prompt
	end script
	
	this's update()
	this's _model's register_observer(this)
	return this
end make_help_view

on make_label_help_view()
	script
		property class : "LabelHelpView"
		
		property _title : __SCRIPT_NAME__ & " Category Help"
		property _buttons : {"Cancel", "OK"}
		property _prompt : "Assign a category and/or subcategories to the logged URL by using a colon (:) to separate subcategories. Subcategories delimited in such a way represent a nested hierarchy. For example, a category (also called a label in the URLs file) of \"Development:AppleScript:Mail\" could be thought of as a nested list as in:" & return & return Â
			& tab & "¥ Development" & return Â
			& tab & tab & "¥ AppleScript" & return Â
			& tab & tab & tab & "¥ Mail"
		
		on create_view() --> void
			with timeout of (10 * 60) seconds
				display alert _title message _prompt buttons _buttons cancel button 1 default button 2
			end timeout
		end create_view
	end script
end make_label_help_view

on make_file_edit_view(view_controller, settings_model)
	script
		property class : "FileEditView"
		property parent : make_base_view() -- extends BaseView
		property _controller : view_controller
		property _model : settings_model
		
		property _title : "Warning: " & __SCRIPT_NAME__ & " > Edit Log File"
		property _buttons : {"Don't Show This Warning Again", my u_back_btn, "Edit File"}
		property _prompt : "If manually editing the log file, take care not to alter the format of the file which could result in file corruption and/or the script no longer being able to use the file." & return & return & "Specifically, don't alter the record separators, the file header (except for the sample categories/labels, which can be modified), the field names in the records, or the field delimiters in the records."
		
		on create_view() --> void
			with timeout of (10 * 60) seconds
				try
					display alert _title message _prompt buttons _buttons default button 3 cancel button 2 as warning
					set action_event to result's button returned
				on error err_msg number err_num
					if err_num is -128 then -- treat cancel (cmd-.) as back
						set action_event to _buttons's item 2
					else
						error err_msg number err_num
					end if
				end try
				action_performed(action_event) --> returns boolean
			end timeout
		end create_view
		
		on action_performed(action_event) --> void
			set action_event to action_event as string
			if action_event is _buttons's item 1 then
				_controller's disable_warning()
			else if action_event is _buttons's item 2 then
				_controller's go_back()
				return true --> continue controller loop
			else if action_event is _buttons's item 3 then
				_controller's launch_app()
			end if
			return false --> stop controller loop
		end action_performed
	end script
end make_file_edit_view

on make_title_view(view_controller, main_model)
	script this
		property class : "TitleView"
		property parent : make_base_view() -- extends BaseView
		property _controller : view_controller
		property _model : main_model
		
		property _page_title : missing value
		
		property _title : __SCRIPT_NAME__ & " > Title"
		property _buttons : {my help_btn_pad, "Cancel", my next_btn_pad}
		property _prompt : missing value
		property _text_field : missing value
		
		on create_view() --> void
			_set_prompt()
			repeat
				display dialog _prompt default answer _page_title with title _title buttons _buttons default button 3
				copy result as list to {text_value, action_event}
				if text_value is not "" or action_event is _buttons's item 1 then
					exit repeat
				else
					display alert "Empty Text Field" message "A web page title is required." as warning
				end if
			end repeat
			set _text_field to text_value
			action_performed(action_event)
		end create_view
		
		on action_performed(action_event) --> void
			if action_event is false then error number -128 -- User canceled
			
			set action_event to action_event as string
			if action_event is _buttons's item 1 then
				_controller's show_help()
			else if action_event is _buttons's item 3 then
				_controller's set_page_title(_text_field)
			end if
		end action_performed
		
		on update() --> void  (Observer Pattern)
			set _page_title to _model's get_page_title()
		end update
		
		on _set_prompt() --> void -- PRIVATE
			set _prompt to "To log the URL for " & _model's get_browser_name() & "'s front document, first edit and/or accept the page title."
		end _set_prompt
	end script
	
	this's update()
	this's _model's register_observer(this)
	return this
end make_title_view

on make_url_view(view_controller, main_model)
	script this
		property class : "URLView"
		property parent : make_base_view() -- extends BaseView
		property _controller : view_controller
		property _model : main_model
		
		property _page_title : missing value
		property _page_url : missing value
		
		property _title : __SCRIPT_NAME__ & " > URL"
		property _buttons : {my back_btn_pad, "Cancel", my next_btn_pad}
		property _prompt : missing value
		property _text_field : missing value
		
		on create_view() --> void
			_set_prompt()
			repeat
				display dialog _prompt default answer _page_url with title _title buttons _buttons default button 3
				copy result as list to {text_value, action_event}
				if text_value is not "" or action_event is _buttons's item 1 then
					exit repeat
				else
					display alert "Empty Text Field" message "A URL is required." as warning
				end if
			end repeat
			set _text_field to text_value
			action_performed(action_event)
		end create_view
		
		on action_performed(action_event) --> void
			if action_event is false then error number -128 -- User canceled
			
			set action_event to action_event as string
			if action_event is _buttons's item 1 then
				_controller's go_back()
			else if action_event is _buttons's item 3 then
				_controller's set_page_url(_text_field)
			end if
		end action_performed
		
		on update() --> void  (Observer Pattern)
			set _page_title to _model's get_page_title()
			set _page_url to _model's get_page_url()
		end update
		
		on _set_prompt() --> void -- PRIVATE
			set _prompt to "TITLE:" & return & tab & _page_title & return & return & "Edit and/or accept the URL."
		end _set_prompt
	end script
	
	this's update()
	this's _model's register_observer(this)
	return this
end make_url_view

on make_label_base_view(main_model)
	script this
		property class : "LabelBaseView"
		property parent : make_base_view() -- extends BaseView
		property _model : main_model
		
		property _page_label : missing value --> string
		property _chosen_root : missing value --> string
		property _chosen_category : missing value --> string
		property _root_categories : missing value --> array
		property _sub_categories : missing value --> array
		property _all_categories : missing value --> array
		
		property _title : __SCRIPT_NAME__ & " > Category"
		property _ok_btn : "Next..."
		property _bullet : my u_bullet_item
		property _prompt_extra : "(Type a number to jump to the corresponding numbered menu item.)"
		
		(*
			Subclasses must define properties for:
				_menu_items
				_default_item
				_title
				_prompt
				_ok_btn
		*)
		
		on create_view() --> void
			set action_event to choose from list my _menu_items with title _title with prompt my _prompt cancel button name my u_back_btn OK button name _ok_btn default items my _default_item
			action_performed(action_event)
		end create_view
		
		on action_performed() --> void
			error my class & ".action_performed(): abstract method not overridden" number -1717
		end action_performed
		
		on show_invalid() --> void
			display alert "Invalid selection" message "Please select a category or an action." as warning
		end show_invalid
		
		on get_base_menu_items(menu_rule) --> array
			local menu_rule
			return {Â
				_bullet & "Edit Log File", Â
				_bullet & "View Log File", Â
				menu_rule, Â
				_bullet & "Preferences...", Â
				menu_rule, Â
				_bullet & "About " & __SCRIPT_NAME__, Â
				_bullet & "Help", Â
				_bullet & "Category Help", Â
				menu_rule, Â
				_bullet & "Quit " & __SCRIPT_NAME__, Â
				menu_rule}
		end get_base_menu_items
		
		on number_menu_items(menu_items, menu_rule) --> array
			local numbered_menu, menu_items, menu_rule, j
			set numbered_menu to {}
			set j to 1
			repeat with i from 1 to menu_items's length
				set this_item to menu_items's item i
				if this_item is menu_rule then
					set numbered_menu's end to this_item
				else
					set numbered_menu's end to j & space & this_item as string
					set j to j + 1
				end if
			end repeat
			return numbered_menu
		end number_menu_items
		
		on update() --> void  (Observer Pattern)
			set _page_label to _model's get_page_label()
			set _chosen_root to _model's get_chosen_root_category()
			set _chosen_category to _model's get_chosen_category()
			set _root_categories to _model's get_root_categories()
			set _sub_categories to _model's get_sub_categories()
			set _all_categories to _model's get_all_categories()
		end update
	end script
	
	this's update()
	this's _model's register_observer(this)
	return this
end make_label_base_view

on make_label_view(view_controller, label_base_view)
	script
		property class : "LabelView"
		--property parent : make_label_base_view() -- extends LabelBaseView
		property parent : label_base_view -- extends LabelBaseView (instance)
		property _controller : view_controller
		
		property _bullet : my u_bullet_item
		property _menu_rule : multiply_text(my u_dash, 18)
		property _prompt : "Please select a top-level category for the URL you want to log. Next you will be able to select subcategories. " & my _prompt_extra
		
		property _default_item : missing value
		property _menu_items : missing value
		
		on create_view() --> void
			set _default_item to my _chosen_root
			set_menu()
			continue create_view()
		end create_view
		
		on action_performed(action_event) --> void
			if action_event is false then --error number -128 -- User canceled
				_controller's go_back()
				return
			end if
			set action_event to action_event as string
			if action_event is _menu_rule then
				show_invalid()
				create_view() -- try again
			else if action_event is _menu_items's item 1 then
				_controller's choose_from_all()
			else if action_event is _menu_items's item 2 then
				_controller's edit_label()
			else if action_event is _menu_items's item 4 then
				_controller's edit_file()
			else if action_event is _menu_items's item 5 then
				_controller's view_file()
			else if action_event is _menu_items's item 7 then
				_controller's change_settings()
			else if action_event is _menu_items's item 9 then
				_controller's show_about()
			else if action_event is _menu_items's item 10 then
				_controller's show_help()
			else if action_event is _menu_items's item 11 then
				_controller's show_category_help()
			else if action_event is _menu_items's item 13 then
				error number -128 -- User canceled
			else -- go to subcategory view
				_controller's set_chosen_root(action_event)
			end if
		end action_performed
		
		on set_menu() --> void
			local these_items
			set these_items to {Â
				_bullet & "Show All Categories...", Â
				_bullet & "New Category...", Â
				_menu_rule} & my get_base_menu_items(_menu_rule)
			set _menu_items to my number_menu_items(these_items, _menu_rule) & my _root_categories
		end set_menu
	end script
end make_label_view

on make_sub_label_view(view_controller, label_base_view)
	script
		property class : "SubLabelView"
		--property parent : make_label_base_view() -- extends LabelBaseView
		property parent : label_base_view -- extends LabelBaseView (instance)
		property _controller : view_controller
		
		property _bullet : my u_bullet_item
		property _menu_rule : multiply_text(my u_dash, 35)
		property _prompt : "Please select a category or subcategory for the URL you want to log. You will have a chance to edit your choice (to add a new category or subcategory). " & my _prompt_extra
		
		property _default_item : missing value
		property _menu_items : missing value
		
		on create_view() --> void
			set _default_item to my _chosen_category
			set_menu()
			continue create_view()
		end create_view
		
		on action_performed(action_event) --> void
			if action_event is false then --error number -128 -- User canceled
				_controller's go_back()
				return
			end if
			set action_event to action_event as string
			if action_event is _menu_rule then
				show_invalid()
				create_view() -- try again
			else if action_event is _menu_items's item 1 then
				_controller's choose_from_all()
			else if action_event is _menu_items's item 3 then
				_controller's edit_file()
			else if action_event is _menu_items's item 4 then
				_controller's view_file()
			else if action_event is _menu_items's item 6 then
				_controller's change_settings()
			else if action_event is _menu_items's item 8 then
				_controller's show_about()
			else if action_event is _menu_items's item 9 then
				_controller's show_help()
			else if action_event is _menu_items's item 10 then
				_controller's show_category_help()
			else if action_event is _menu_items's item 12 then
				error number -128 -- User canceled
			else -- go to category edit view
				_controller's set_chosen_category(action_event)
			end if
		end action_performed
		
		on set_menu() --> void
			local these_items
			set these_items to {Â
				_bullet & "Show All Categories...", Â
				_menu_rule} & my get_base_menu_items(_menu_rule)
			set _menu_items to my number_menu_items(these_items, _menu_rule) & my _sub_categories
		end set_menu
	end script
end make_sub_label_view

on make_all_label_view(view_controller, label_base_view)
	script
		property class : "AllLabelView"
		--property parent : make_label_base_view() -- extends LabelBaseView
		property parent : label_base_view -- extends LabelBaseView (instance)
		property _controller : view_controller
		
		property _bullet : my u_bullet_item
		property _menu_rule : multiply_text(my u_dash, 35)
		property _prompt : "Please select a category or subcategory for the URL you want to log. You will have a chance to edit your choice (to add a new category or subcategory). " & my _prompt_extra
		
		property _default_item : missing value
		property _menu_items : missing value
		
		on create_view() --> void
			set _default_item to my _chosen_category
			set_menu()
			continue create_view()
		end create_view
		
		on action_performed(action_event) --> void
			if action_event is false then --error number -128 -- User canceled
				_controller's go_back()
				return
			end if
			set action_event to action_event as string
			if action_event is _menu_rule then
				show_invalid()
				create_view() -- try again
			else if action_event is _menu_items's item 1 then
				_controller's edit_file()
			else if action_event is _menu_items's item 2 then
				_controller's view_file()
			else if action_event is _menu_items's item 4 then
				_controller's change_settings()
			else if action_event is _menu_items's item 6 then
				_controller's show_about()
			else if action_event is _menu_items's item 7 then
				_controller's show_help()
			else if action_event is _menu_items's item 8 then
				_controller's show_category_help()
			else if action_event is _menu_items's item 10 then
				error number -128 -- User canceled
			else -- go to category edit view
				_controller's set_chosen_category(action_event)
			end if
		end action_performed
		
		on set_menu() --> void
			local these_items
			set these_items to my get_base_menu_items(_menu_rule)
			set _menu_items to my number_menu_items(these_items, _menu_rule) & my _all_categories
		end set_menu
	end script
end make_all_label_view

on make_label_edit_view(view_controller, main_model)
	script this
		property class : "LabelEditView"
		property parent : make_base_view() -- extends BaseView
		property _controller : view_controller
		property _model : main_model
		
		property _page_title : missing value --> string
		property _page_url : missing value --> string
		property _page_label : missing value --> string
		
		property _chosen_category : missing value --> string
		
		property _title : __SCRIPT_NAME__ & " > Category"
		property _buttons : {my back_btn_pad, "Cancel", my next_btn_pad}
		property _prompt : missing value
		
		on create_view() --> void
			_set_prompt()
			repeat
				display dialog _prompt default answer _chosen_category with title _title buttons _buttons default button 3
				copy result as list to {text_value, action_event}
				set text_value to _chop_trailing_colons(text_value)
				if text_value is not "" or action_event is _buttons's item 1 then
					exit repeat
				else
					display alert "Empty Text Field" message "A category is required." as warning
				end if
			end repeat
			set _chosen_category to text_value
			action_performed(action_event)
		end create_view
		
		on action_performed(action_event) --> void
			if action_event is false then error number -128 -- User canceled
			
			set action_event to action_event as string
			if action_event is _buttons's item 1 then
				_controller's go_back()
			else if action_event is _buttons's item 3 then
				_controller's set_chosen_category(_chosen_category)
			end if
		end action_performed
		
		on _chop_trailing_colons(text_value) --> string -- PRIVATE
			try
				repeat until text_value does not end with ":"
					set text_value to characters 1 thru -2 of text_value as string
				end repeat
			on error -- the only remaining character is a colon
				return "" -- let the empty field test catch it
			end try
			return text_value
		end _chop_trailing_colons
		
		on update() --> void  (Observer Pattern)
			set _page_title to _model's get_page_title()
			set _page_url to _model's get_page_url()
			set _page_label to _model's get_page_label()
			set _chosen_category to _model's get_chosen_category()
		end update
		
		on _set_prompt() --> void -- PRIVATE
			set _prompt to "TITLE:" & return & tab & _page_title & return & return Â
				& "URL:" & return & tab & _page_url & return & return Â
				& "Please provide a category and any optional subcategories (or edit your selected category) for the URL. Use a colon to separate subcategories. Example: \"Development:AppleScript:Mail\""
		end _set_prompt
	end script
	
	this's update()
	this's _model's register_observer(this)
	return this
end make_label_edit_view

on make_note_view(view_controller, main_model)
	script this
		property class : "NoteView"
		property parent : make_base_view() -- extends BaseView
		property _controller : view_controller
		property _model : main_model
		
		property _page_title : missing value
		property _page_url : missing value
		property _page_label : missing value
		
		property _title : __SCRIPT_NAME__ & " > Note"
		property _buttons : {my back_btn_pad, "Cancel", my save_btn_pad}
		property _prompt : missing value
		property _text_field : missing value
		
		on create_view() --> void
			_set_prompt()
			display dialog _prompt default answer "" with title _title buttons _buttons default button 3
			copy result as list to {text_value, action_event}
			if text_value is not "" then set _text_field to text_value
			action_performed(action_event)
		end create_view
		
		on action_performed(action_event) --> void
			if action_event is false then error number -128 -- User canceled
			
			set action_event to action_event as string
			if action_event is _buttons's item 1 then
				_controller's go_back()
			else if action_event is _buttons's item 3 then
				_controller's set_page_note(_text_field)
			end if
		end action_performed
		
		on update() --> void  (Observer Pattern)
			set _page_title to _model's get_page_title()
			set _page_url to _model's get_page_url()
			set _page_label to _model's get_page_label()
		end update
		
		on _set_prompt() --> void -- PRIVATE
			set _prompt to "TITLE:" & return & tab & _page_title & return & return Â
				& "URL:" & return & tab & _page_url & return & return Â
				& "CATEGORY:" & return & tab & _page_label & return & return Â
				& "Optionally add a short note. Just leave the field blank if you don't want to add a note."
		end _set_prompt
	end script
	
	this's update()
	this's _model's register_observer(this)
	return this
end make_note_view

-- -- -- Settings Views -- -- --

on make_settings_first_view(settings_controller, settings_model)
	script
		property class : "SettingsFirstView"
		property parent : make_base_view() -- extends BaseView
		property _controller : settings_controller
		property _model : settings_model
		
		property _title : __SCRIPT_NAME__ --& " (First Run)"
		property _prompt : missing value
		property _buttons : {"Change Settings...", "Cancel", "Use Defaults"}
		
		on create_view() --> void
			_set_prompt()
			with timeout of (10 * 60) seconds
				--display dialog _prompt with title _title buttons _buttons default button 3 with icon note
				display alert _title message _prompt buttons _buttons cancel button 2 default button 3
				set action_event to result's button returned
				action_performed(action_event)
			end timeout
		end create_view
		
		on action_performed(action_event) --> void
			if action_event is false then error number -128 -- User canceled
			
			set action_event to action_event as string
			if action_event is _buttons's item 1 then
				_controller's change_settings()
			else if action_event is _buttons's item 3 then
				_controller's use_defaults()
			end if
		end action_performed
		
		on _set_prompt() --> void -- PRIVATE
			set _prompt to my _app_description & " The defaults are:" & return & return Â
				& "	URLs File:		" & _model's get_default_log_file() & return & return Â
				& "	File Viewer:	" & _model's get_default_file_viewer() & return & return Â
				& "	Text Editor:	" & _model's get_default_text_editor() & return & return Â
				& "You can continue using those defaults or change the settings now. You can also change the settings later by selecting the \"Preferences\" item from any list dialog. (You would have to manually move your old URLs file though if you wanted to keep appending to it.)"
		end _set_prompt
	end script
end make_settings_first_view

on make_settings_main_view(settings_controller, settings_model)
	script this
		property class : "SettingsMainView"
		property parent : make_base_view() -- extends BaseView
		property _controller : settings_controller
		property _model : settings_model
		
		property _log_file : missing value
		property _file_viewer : missing value
		property _text_editor : missing value
		
		property _title : __SCRIPT_NAME__ & " > Preferences"
		property _prompt : missing value
		property _buttons : {"Choose a File Editor/Viewer...", "Choose a URLs File...", "OK"}
		
		on create_view() --> void
			_set_prompt()
			display dialog _prompt with title _title buttons _buttons default button 3 with icon note
			set action_event to result's button returned
			action_performed(action_event)
		end create_view
		
		on action_performed(action_event) --> void
			if action_event is false then error number -128 -- User canceled
			
			set action_event to action_event as string
			if action_event is _buttons's item 1 then
				_controller's choose_app()
			else if action_event is _buttons's item 2 then
				_controller's choose_file()
			end if
		end action_performed
		
		on update() --> void  (Observer Pattern)
			set _log_file to _model's get_log_file()
			set _file_viewer to _model's get_file_viewer()
			set _text_editor to _model's get_text_editor()
		end update
		
		on _set_prompt() --> void -- PRIVATE
			set _prompt to "Choose a different URLs file, file viewer or text editor. The current settings are:" & return & return Â
				& tab & "URLs File:" & tab & _log_file & return & return Â
				& tab & "File Viewer:" & tab & _file_viewer & return & return Â
				& tab & "Text Editor:" & tab & _text_editor & return & return
		end _set_prompt
	end script
	
	this's update()
	this's _model's register_observer(this)
	return this
end make_settings_main_view

on make_settings_app_view(settings_controller, settings_model)
	script this
		property class : "SettingsAppView"
		property parent : make_base_view() -- extends BaseView
		property _controller : settings_controller
		property _model : settings_model
		
		property _title : __SCRIPT_NAME__ & " > Preferences > Choose Application"
		property _prompt : missing value
		property _buttons : {my u_back_btn, "Choose a Text Editor...", "Choose a File Viewer..."}
		
		property _text_editor : missing value
		property _file_viewer : missing value
		
		on create_view() --> void
			_set_prompt()
			display dialog _prompt with title _title buttons _buttons with icon note
			set action_event to result's button returned
			action_performed(action_event)
		end create_view
		
		on action_performed(action_event) --> void -- from main view
			if action_event is false then error number -128 -- User canceled
			
			set action_event to action_event as string
			if action_event is _buttons's item 1 then
				_controller's go_back()
			else if action_event is _buttons's item 2 then
				_controller's choose_editor()
			else if action_event is _buttons's item 3 then
				_controller's choose_viewer()
			end if
		end action_performed
		
		on update() --> void  (Observer Pattern)
			set _text_editor to _model's get_text_editor()
			set _file_viewer to _model's get_file_viewer()
		end update
		
		on _set_prompt() --> void -- PRIVATE
			set _prompt to "Choose an application for editing or viewing the URLs file. The current settings are:" & return & return Â
				& tab & "File Viewer:" & tab & _file_viewer & return & return Â
				& tab & "Text Editor:" & tab & _text_editor & return & return
		end _set_prompt
	end script
	
	this's update()
	this's _model's register_observer(this)
	return this
end make_settings_app_view

on make_settings_editor_view(settings_controller, settings_model)
	script this
		property class : "SettingsEditorView" -- concrete app view
		property parent : make_settings_app_base_view() -- extends SettingsAppBaseView
		property _controller : settings_controller
		property _model : settings_model
		
		property _title : __SCRIPT_NAME__ & " > Preferences > Choose App > Editor"
		property _prompt : "Choose a text editor application for editing the URLs file." & return & return
		property _buttons : {my u_back_btn, "Use Default Editor...", "Choose Another Editor..."}
		property _app_type : "text editor"
		property _app_usage : "editing"
		
		property _default_app : missing value
		
		on update() --> void  (Observer Pattern)
			set _default_app to _model's get_default_text_editor()
		end update
	end script
	
	this's update()
	this's _model's register_observer(this)
	return this
end make_settings_editor_view

on make_settings_viewer_view(settings_controller, settings_model)
	script this
		property class : "SettingsViewerView" -- concrete app view
		property parent : make_settings_app_base_view() -- extends SettingsAppBaseView
		property _controller : settings_controller
		property _model : settings_model
		
		property _title : __SCRIPT_NAME__ & " > Preferences > Choose App > Viewer"
		property _prompt : "Choose an application for viewing the URLs file." & return & return
		property _buttons : {my u_back_btn, "Use Default App...", "Choose Another App..."}
		property _app_type : "file viewer"
		property _app_usage : "viewing"
		
		property _default_app : missing value
		
		on update() --> void  (Observer Pattern)
			set _default_app to _model's get_default_file_viewer()
		end update
	end script
	
	this's update()
	this's _model's register_observer(this)
	return this
end make_settings_viewer_view

on make_settings_app_base_view()
	script
		property class : "SettingsAppBaseView" -- abstract app view
		property parent : make_base_view() -- extends BaseView
		
		(* == Main View == *)
		
		on create_view() --> void
			display dialog my _prompt with title my _title buttons my _buttons default button 3 with icon note
			set action_event to result's button returned
			action_performed(action_event)
		end create_view
		
		(* == Subviews == *)
		
		on choose_default() --> void
			local t, m
			set t to my _title & " > Default"
			set m to "The default " & my _app_type & " is:" & tab & my _default_app & return & return & "Use this app?" & return & return
			set b to {my u_back_btn, "Cancel", "Use Default"}
			display dialog m with title t buttons b default button 3 with icon note
			set btn_pressed to button returned of result
			if btn_pressed is b's item 1 then
				create_view() -- back to main view
			else if btn_pressed is b's item 3 then
				my _controller's set_app(my _default_app)
			end if
		end choose_default
		
		on choose_another() --> void
			local _app, t, m
			set t to my _title & " > Choose Application"
			set m to "Select an application to use for " & my _app_usage & " the URLs file. (Click \"Cancel\" to return to the previous dialog.)"
			try
				set _app to name of (choose application with title t with prompt m)
				my _controller's set_app(_app)
			on error err_msg number err_num
				my handle_cancel_as_back(err_msg, err_num)
			end try
		end choose_another
		
		(* == Actions == *)
		
		on action_performed(action_event) --> void -- from main view
			if action_event is false then error number -128 -- User canceled
			
			set action_event to action_event as string
			if action_event is my _buttons's item 1 then
				my _controller's go_back()
			else if action_event is my _buttons's item 2 then
				choose_default()
			else if action_event is my _buttons's item 3 then
				choose_another()
			end if
		end action_performed
		
		on update() --> void  (Observer Pattern)
			error my class & ".update(): abstract method not overridden" number -1717
		end update
	end script
end make_settings_app_base_view

on make_settings_file_view(settings_controller, settings_model)
	script this
		property class : "SettingsFileView"
		property parent : make_base_view() -- extends BaseView
		property _controller : settings_controller
		property _model : settings_model
		
		property _title : __SCRIPT_NAME__ & " > Preferences > Choose File"
		property _prompt : "Choose a file in which to save URLs:"
		property _menu_rule : multiply_text(my u_dash, 19)
		property _menu_items_base : {Â
			"Use Default File...", Â
			"Choose Existing File...", Â
			"Create New File...", Â
			_menu_rule, Â
			"Type in File Path...		(Advanced)", Â
			_menu_rule, Â
			"Quit " & __SCRIPT_NAME__}
		property _menu_items : missing value
		
		property _log_file : missing value
		property _warn_before_editing : missing value
		
		(* == Main View == *)
		
		on create_view() --> void
			update_menu()
			repeat -- until a horizontal rule is not selected
				set action_event to choose from list _menu_items with title _title with prompt _prompt cancel button name my u_back_btn
				if action_event as string is not _menu_rule then
					exit repeat
				else
					display alert "Invalid selection" message "Please select an action." as warning
				end if
			end repeat
			action_performed(action_event)
		end create_view
		
		(* == Subviews == *)
		
		on choose_default() --> void
			set t to _title & " > Default"
			set m to "The default URLs file is:" & return & return & tab & _model's get_default_log_file() & return & return & "Use this file?" & return & return
			set b to {my u_back_btn, "Cancel", "Use Default"}
			display dialog m with title t buttons b default button 3 with icon note
			set btn_pressed to button returned of result
			if btn_pressed is b's item 1 then
				create_view() -- back to main view
			else if btn_pressed is b's item 3 then
				set _log_file to _model's get_default_log_file()
				_controller's set_log_file(_log_file)
			end if
		end choose_default
		
		on choose_existing() --> void
			set m to "Choose an existing URLs file. (Click \"Cancel\" to return to the previous dialog.)"
			try
				set _log_file to POSIX path of (choose file with prompt m default location path to desktop folder from user domain)
				_controller's set_log_file(_log_file)
			on error err_msg number err_num
				my handle_cancel_as_back(err_msg, err_num)
			end try
		end choose_existing
		
		on choose_new() --> void
			set m to "Choose a file name and location for the URLs file. (Click \"Cancel\" to return to the previous dialog.)"
			set file_name to item 2 of split_path_into_dir_and_file(_model's get_default_log_file())
			try
				set _log_file to POSIX path of (choose file name with prompt m default name file_name default location path to desktop folder from user domain)
				_controller's set_log_file(_log_file)
			on error err_msg number err_num
				my handle_cancel_as_back(err_msg, err_num)
			end try
		end choose_new
		
		on enter_path() --> void
			set t to _title & " > Enter Path"
			set m to "Enter a full file path to use for saving the URLs." & return & return & "A '~' (tilde) can be used to indicate your home directory. Example:" & return & return & tab & "~/Desktop/urls.txt"
			set b to {my back_btn_pad, "Cancel", my ok_btn_pad}
			display dialog m with title t default answer _log_file buttons b default button 3
			copy result as list to {text_value, btn_pressed}
			if btn_pressed is b's item 1 then
				create_view() -- back to main view
			else if btn_pressed is b's item 3 then
				if text_value is "" then
					display alert "Empty Field" message "Please enter a file path in the text field." as warning
					enter_path() -- recursion
				else
					set _log_file to text_value
					_controller's set_log_file(_log_file)
				end if
			end if
		end enter_path
		
		on reset_warning() --> void
			set t to __SCRIPT_NAME__ & " > Preferences > Reset Edit File Warning"
			set m to "Care should be taken when manually editing the log file because altering the format of the data could result in file corruption and/or the script no longer being able to use the file." & return & return & "Resetting the warning here will cause a warning to be shown each time the file edit action is invoked."
			set b to {my u_back_btn, "Cancel", "Reset Warning"}
			display dialog m with title t buttons b default button 3 with icon note
			set btn_pressed to button returned of result
			if btn_pressed is b's item 1 then
				create_view() -- back to main view
			else if btn_pressed is b's item 3 then
				_controller's reset_warning()
			end if
		end reset_warning
		
		(* == Actions == *)
		
		on action_performed(action_event) --> void -- from main view
			if action_event is false then --error number -128 -- User canceled
				_controller's go_back()
				return
			end if
			
			set action_event to action_event as string
			if action_event is _menu_items's item 1 then
				choose_default()
			else if action_event is _menu_items's item 2 then
				choose_existing()
			else if action_event is _menu_items's item 3 then
				choose_new()
			else if action_event is _menu_items's item 5 then
				enter_path()
			else if action_event is _menu_items's item 7 then
				error number -128 -- User canceled
			else if action_event is _menu_items's item 9 then
				reset_warning()
			end if
		end action_performed
		
		on update() --> void  (Observer Pattern)
			try
				set _log_file to _model's get_log_file()
			on error
				set _log_file to _model's get_default_log_file()
			end try
			set _warn_before_editing to _model's warn_before_editing()
		end update
		
		on update_menu() --> void
			if _warn_before_editing then
				set _menu_items to _menu_items_base
			else
				set _menu_items to _menu_items_base Â
					& {_menu_rule, "Reset File Edit Warning..."}
			end if
		end update_menu
	end script
	
	this's update()
	this's _model's register_observer(this)
	return this
end make_settings_file_view

(* ==== Helper Classes ==== *)

on make_observable()
	script
		property class : "Observable"
		property _observers : {}
		property _changed : false
		
		on set_changed()
			set _changed to true
		end set_changed
		
		on register_observer(o) -- void
			my debug_log(1, "  [debug] register_observer(" & o's class & ")")
			set end of my _observers to o
		end register_observer
		
		(* Uncomment if needed. Most of the time, it won't be needed for scripts.
		on remove_observer(o) -- void
			my debug_log(1, "  [debug] remove_observer(" & o's class & ")")
			set remaining_observers to {}
			repeat with this_observer in _observers
				set this_observer to this_observer's contents -- dereference
				my debug_log(1, "  [debug] remove_observer(): comparing " & this_observer's class)
				if this_observer is not o then
					set end of remaining_observers to this_observer
				else
					my debug_log(1, "  [debug] remove_observer(): removing " & this_observer's class)
				end if
			end repeat
			set _observers to remaining_observers
		end remove_observer
		*)
		
		on notify_observers() -- void -- (no argument = pull method; best practice)
			my debug_log(1, "  [debug] notify_observers()")
			if _changed then
				my debug_log(1, "  [debug] " & my class & ".notify_observers(): calling update()")
				repeat with i from 1 to count of _observers
					set this_observer to _observers's item i
					this_observer's update()
				end repeat
				set _changed to false
			end if
			return
		end notify_observers
		
		-- Display the class names of the observers (for testing/debugging)
		on identify_observers() --> void
			my debug_log(1, "  [debug] " & my class & ".identify_observers() [" & _observers's length & "]...")
			if _observers's length = 0 then
				my debug_log(1, "  [debug] " & my class & ".identify_observers(): no observers")
				return ""
			else if _observers's length = 1 then
				return _observers's item 1's class
			end if
			set observers_items to ""
			repeat with i from 1 to _observers's length
				set this_item to _observers's item i
				if i = 1 then
					set observers_items to this_item's class
				else
					set observers_items to observers_items & ", " & this_item's class
				end if
			end repeat
			my debug_log(2, "    [debug] " & observers_items)
		end identify_observers
	end script
end make_observable

on make_stack()
	script
		property class : "Stack" -- Data Type -- LIFO (last in, first out)
		property _stack : {}
		
		-- Push an item onto the top of the stack
		on push(this_data) --> void
			set _stack's beginning to this_data
			return
		end push
		
		-- Return the top item of the stack, removing it in the process
		on pop() --> anything
			if is_empty() then error my class & ": Can't pop(): stack is empty." number -1730
			set top_item to _stack's item 1
			set _stack to rest of _stack
			return top_item
		end pop
		
		-- Return the top item of the stack without removing it
		on peek() --> anything
			if is_empty() then error my class & ": Can't peek(): stack is empty." number -1730
			return _stack's item 1
		end peek
		
		-- Test if stack is empty
		on is_empty() --> boolean
			return _stack's length is 0
		end is_empty
		
		-- Clear the stack
		on reset() --> void
			set _stack to {}
		end reset
		
		-- Display the names of the classes in the stack (mostly for testing/debugging)
		on to_string() --> string
			if _stack's length = 0 then
				return ""
			else if _stack's length = 1 then
				return _stack's item 1's class
			end if
			set stack_items to ""
			repeat with i from 1 to _stack's length
				set this_item to _stack's item i
				if i = 1 then
					set stack_items to this_item's class
				else
					set stack_items to stack_items & ", " & this_item's class
				end if
			end repeat
			return stack_items
		end to_string
	end script
end make_stack

on make_named_stack(_name)
	script this
		property class : "Stack (Named)" -- Data Type
		property parent : make_stack() -- extends Stack
		property _name : missing value
		
		on push(this_data) --> void
			continue push(this_data)
			my debug_log(1, "[debug] pushing " & this_data's to_string() & " onto " & _name)
			return
		end push
		
		on pop() --> anything
			set top_item to continue pop()
			my debug_log(1, "[debug] popping " & top_item's to_string() & " off " & _name)
			return top_item
		end pop
		
		on set_name(_name) --> void
			set its _name to _name
		end set_name
		
		on identify() --> string
			if _name is not missing value then return _name
		end identify
	end script
	
	set this's _name to _name
	return this
end make_named_stack

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
	script
		property class : "NullIO" -- Utility
		property parent : make_io()
		
		on write_file(file_path, this_data)
			my debug_log(1, "[debug] " & my class & ".write_file(): would write to file")
			my debug_log(1, linefeed & this_data)
		end write_file
		
		on append_file(file_path, this_data)
			my debug_log(1, "[debug] " & my class & ".append_file(): would append to file")
			my debug_log(1, linefeed & this_data)
		end append_file
	end script
end make_null_io

on make_io()
	script
		property class : "IO" -- Utility
		
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

(* ==== Utility Functions (Global) ==== *)

on gui_scripting_status()
	-- check to see if assistive devices is enabled
	tell application "System Events"
		set ui_enabled to UI elements enabled
	end tell
	if ui_enabled is false then
		tell application "System Preferences"
			activate
			set current pane to pane id "com.apple.preference.universalaccess"
			display dialog "This script utilizes the built-in Graphic User Interface Scripting architecture of Mac OS X which is currently disabled." & return & return & "You can activate GUI Scripting by selecting the checkbox \"Enable access for assistive devices\" in the Accessibility preference pane." with icon 1 buttons {"Cancel"} default button 1
		end tell
	end if
end gui_scripting_status

on get_front_app_name()
	tell application "System Events"
		if __DEBUG_LEVEL__ is 0 then
			set current_app to short name of first process where it is frontmost
		else
			-- We're most likely running in AppleScript Editor so hide
			-- the front app, get the name of the next app, then return
			-- the original app to the front.
			-- Source:  http://macscripter.net/viewtopic.php?id=35442
			set frontmost_process to first process where it is frontmost
			set visible of frontmost_process to false
			repeat while (frontmost_process is frontmost)
				delay 0.2
			end repeat
			set current_app to short name of first process where it is frontmost
			set frontmost of frontmost_process to true
		end if
	end tell
	return current_app
end get_front_app_name

on convert_to_ascii(non_ascii_txt)
	(*
		Transliterate Unicode characters to ASCII, ignoring any that can't be
		represented. Also compress white space since ignoring characters can
		leave mulitple adjacent spaces.
	
		From 'man iconv_open':
		
			When the string "//TRANSLIT" is appended to _tocode_,
			transliteration is activated. This means that when a character
			cannot be represented in the target character set, it can be
			approximated through one or several characters that look similar to
			the original character.

			When the string "//IGNORE" is appended to _tocode_, characters that
			cannot be represented in the target character set will be silently
			discarded.
	*)
	set s to "iconv -f UTF-8 -t US-ASCII//TRANSLIT//IGNORE <<<" & quoted form of non_ascii_txt & " | sed 's/   */ /g'"
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

on get_mac_path(posix_path)
	-- Expand '~/' or '$HOME/' at the beginning of a posix file path.
	set posix_file to expand_home_path(posix_path)
	return POSIX file posix_file
end get_mac_path

-- Could alternatively use 'do shell script "echo" & space & file_path'
-- but it might be slower because of the overhead of starting up a shell.
on expand_home_path(posix_path) --> string
	local posix_path, posix_home, char_length
	if posix_path starts with "~/" then
		set char_length to 3
	else if posix_path starts with "$HOME/" then
		set char_length to 7
	else
		return posix_path
	end if
	set posix_home to get_posix_home()
	set posix_path to posix_home & characters char_length thru -1 of posix_path as text
	return posix_path
end expand_home_path

on shorten_home_path(posix_path)
	local posix_path, posix_home
	set posix_home to get_posix_home()
	if posix_path starts with posix_home then
		set posix_path to "~" & characters (posix_home's length) thru -1 of posix_path as string
	end if
	return posix_path
end shorten_home_path

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

on debug_log(_level, _msg)
	if __DEBUG_LEVEL__ is greater than or equal to _level then log _msg
end debug_log
