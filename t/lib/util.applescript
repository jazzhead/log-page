script
	property name : "Util"
	property class : "Util"
	
	on split_text(txt, delim) --> array
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
	
	on join_list(lst, delim) --> string
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
	
	on get_cur_dir() --> string
		tell application "System Events" to set cur_dir to (path to me)'s container's POSIX path
	end get_cur_dir
	
	on create_directory(posix_dir) --> void
		set this_dir to expand_home_path(posix_dir)
		try
			set s to "mkdir -pm700 " & quoted form of this_dir
			do shell script s
		on error err_msg number err_num
			error "Can't create directory: " & err_msg number err_num
			return "Fatal Error: Can't create directory"
		end try
	end create_directory
	
	on split_path_into_dir_and_file(file_path) --> array
		set path_parts to split_text(file_path, "/")
		set dir_path to join_list(items 1 thru -2 of path_parts, "/")
		set file_name to path_parts's last item
		return {dir_path, file_name}
	end split_path_into_dir_and_file
	
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
	
	on shorten_home_path(posix_path) --> string
		local posix_path, posix_home
		set posix_home to get_posix_home()
		if posix_path starts with posix_home then
			set posix_path to "~" & characters (posix_home's length) thru -1 of posix_path as string
		end if
		return posix_path
	end shorten_home_path
	
	on get_posix_home() --> string
		return POSIX path of (path to home folder from user domain)
	end get_posix_home
	
	on write_pref(plist_path, pref_key, pref_value) --> void (writes to file)
		local pref_key, pref_value, this_plistfile
		try
			tell application "System Events"
				-- Make a new plist file if one doesn't exist
				if not (exists disk item plist_path) then
					-- Create any missing directories first
					set plist_dir to item 1 of my split_path_into_dir_and_file(plist_path)
					my create_directory(plist_dir)
					-- Create the plist
					set this_plistfile to my _new_plist(plist_path)
				else
					set this_plistfile to property list file plist_path
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
	
	on read_file(file_path)
		_read_file(file_path, string)
	end read_file
	
	---
	
	on gui_scripting_status()
		local os_ver, is_before_mavericks, ui_enabled, apple_accessibility_article
		local err_msg, err_num, msg, t, b
		
		set os_ver to system version of (system info)
		
		considering numeric strings -- version strings
			set is_before_mavericks to os_ver < "10.9"
		end considering
		
		if is_before_mavericks then -- things changed in Mavericks (10.9)
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
		else
			-- In Mavericks (10.9) and later, the system should prompt the user with
			-- instructions on granting accessibility access, so try to trigger that.
			try
				tell application "System Events"
					tell (first process whose frontmost is true)
						set frontmost to true
						tell window 1
							UI elements
						end tell
					end tell
				end tell
			on error err_msg number err_num
				-- In some cases, the system prompt doesn't appear, so always give some info.
				set msg to "Error: " & err_msg & " (" & err_num & ")"
				if err_num is -1719 then
					set apple_accessibility_article to "http://support.apple.com/en-us/HT202802"
					set t to "GUI Scripting needs to be activated"
					set msg to msg & return & return & "This script utilizes the built-in Graphic User Interface Scripting architecture of Mac OS X which is currently disabled." & return & return & "If the system doesn't prompt you with instructions for how to enable GUI scripting access, then see Apple's article at: " & return & apple_accessibility_article
				set b to {"Go to Apple's Webpage", "Cancel"}
				display alert t message msg buttons b default button 2
					if button returned of result is b's item 1 then
						tell me to open location apple_accessibility_article
					end if
					error number -128 --> User canceled
				end if
			end try
		end if
	end gui_scripting_status
	
	
	(* == Private == *)
	
	on _new_plist(plist_path) --> 'property list file' -- PRIVATE
		local parent_dictionary, this_plistfile
		try
			tell application "System Events"
				-- delete any existing property list from memory
				delete every property list item
				-- create an empty property list dictionary item
				set parent_dictionary to make new property list item with properties {kind:record}
				-- create a new property list using the empty record
				set this_plistfile to make new property list file with properties {contents:parent_dictionary, name:plist_path}
				return this_plistfile
			end tell
		on error err_msg number err_num
			error "Can't _new_plist(): " & err_msg number err_num
		end try
	end _new_plist
	
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
