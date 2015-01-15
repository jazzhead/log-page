(*
 *  GUI testing for AppleScript dialogs
 *
 *  This is a GUI testing library. It should be subclassed by test scripts.
 *  Those test scripts also require an overall test script specific to the
 *  target script being tested for setting up and launching the target script
 *  and running the tests.
 *
 *  This library subclasses the TAP library which provides all of the actual
 *  methods for producing TAP output. That library also contains the method
 *  (`try_action`) that actually runs all of the methods in this library and
 *  handles the result.
 *)
script
	property name : "TestGUI"
	property class : "TestGUI"
	property parent : _load_lib("tap.applescript") -- extends "TAP"
	property _Util : _load_lib("util.applescript")
	
	property _test_delay : missing value
	
	-- Properties used by subclasses
	property _process_id : missing value -- the GUI process id of the target script
	
	
	-- Fetch any data needed from the model
	on init(model)
		set _process_id to model's get_process_id()
		set _test_delay to model's get_test_delay()
		set_test_count(model's get_test_count())
	end init
	
	
	(* == GUI Actions == *)
	
	-- Include a delay at the end of each GUI action to give next dialog a
	-- chance to appear.
	
	on click_button(btn_name) --> void
		script this
			property test_desc : "click button \"" & btn_name & "\""
			tell application "System Events" to tell process id (my _process_id)
				set frontmost to true -- just in case; GUI scripting is very fragile
				--delay 1 -- if needed, because... fragile
				tell window 1
					--click button btn_name -- exact name
					click (first button whose name contains btn_name) -- padded name
				end tell
			end tell
			return true
		end script
		try_action(this) -- with logging and error handling (from TAP superclass)
		delay _test_delay
	end click_button
	
	on choose_list_item(list_item, btn_name) --> void
		script this
			property test_desc : "choose list item \"" & list_item & "\""
			tell application "System Events" to tell process id (my _process_id)
				set frontmost to true
				tell window 1
					tell scroll area 1's table 1
						select (first row whose text field 1's value is list_item)
					end tell
					delay 1
					--click button btn_name -- exact name
					click (first button whose name contains btn_name) -- padded name
				end tell
			end tell
			return true
		end script
		try_action(this)
		delay _test_delay
	end choose_list_item
	
	on choose_list_item_containing(list_item, btn_name) --> void
		script this
			property test_desc : "choose list item containing \"" & list_item & "\""
			tell application "System Events" to tell process id (my _process_id)
				set frontmost to true
				tell window 1
					tell scroll area 1's table 1
						select (first row whose text field 1's value contains list_item)
					end tell
					delay 1
					--click button btn_name -- exact name
					click (first button whose name contains btn_name) -- padded name
				end tell
			end tell
			return true
		end script
		try_action(this)
		delay _test_delay
	end choose_list_item_containing
	
	on set_text_field(str) --> void
		script this
			property test_desc : "set text field to \"" & str & "\""
			tell application "System Events" to tell process id (my _process_id)
				set frontmost to true
				tell window 1
					--set text field 1's value to str
					-- Or, to test actually typing characters into the field:
					tell text field 1 to keystroke str
				end tell
			end tell
			return true
		end script
		try_action(this)
		delay _test_delay
	end set_text_field
	
	
	(* == GUI Info == *)
	
	-- These methods query the GUI and test for matches.
	
	-- -- -- Buttons -- -- --
	
	on has_buttons(btn_list) --> void
		script this --> boolean
			property test_desc : "has buttons: \"" & _Util's join_list(btn_list, "\", \"") & "\""
			tell application "System Events" to tell process id (my _process_id)
				set frontmost to true
				tell window 1
					set dialog_btns to name of every button
				end tell
			end tell
			set match_count to 0
			repeat with this_btn in btn_list
				repeat with that_btn in dialog_btns
					-- Using "contains" instead of "is" comparison to account
					-- for buttons with padding and other embellishments.
					if that_btn's contents contains this_btn's contents then
						set match_count to match_count + 1
						exit repeat
					end if
				end repeat
			end repeat
			if match_count = btn_list's length then
				return true
			else
				return false
			end if
		end script
		try_action(this)
	end has_buttons
	
	-- -- -- Windows -- -- --
	
	on _dialog_text_is(idx, str, _test_desc) --> Script Object -- PRIVATE
		script this --> boolean
			property test_desc : _test_desc
			try
				tell application "System Events" to tell process id (my _process_id)
					set frontmost to true
					tell window 1
						(static text idx's value as text) is str
					end tell
				end tell
			on error
				return false
			end try
		end script
	end _dialog_text_is
	
	on _dialog_text_starts_with(idx, str, _test_desc) --> Script Object -- PRIVATE
		script this --> boolean
			property test_desc : _test_desc
			try
				tell application "System Events" to tell process id (my _process_id)
					set frontmost to true
					tell window 1
						(static text idx's value as text) starts with str
					end tell
				end tell
			on error
				return false
			end try
		end script
	end _dialog_text_starts_with
	
	on _dialog_text_contains(idx, str, _test_desc) --> Script Object -- PRIVATE
		script this --> boolean
			property test_desc : _test_desc
			try
				tell application "System Events" to tell process id (my _process_id)
					set frontmost to true
					tell window 1
						(static text idx's value as text) contains str
					end tell
				end tell
			on error
				return false
			end try
		end script
	end _dialog_text_contains
	
	---
	
	on alert_title_is(str) --> void
		-- For alert dialogs, the title (if any) is static text 1.
		set test_desc to "alert title is \"" & str & "\""
		set this_action to _dialog_text_is(1, str, test_desc)
		try_action(this_action)
	end alert_title_is
	
	on alert_message_starts_with(str) --> void
		-- The alert dialog message is in static text 2 (assuming
		-- a title; didn't test w/o title).
		set test_desc to "alert message starts with \"" & str & "\""
		set this_action to _dialog_text_starts_with(2, str, test_desc)
		try_action(this_action)
	end alert_message_starts_with
	
	on alert_message_contains(str) --> void
		-- The alert dialog message is in static text 2 (assuming
		-- a title; didn't test w/o title).
		set test_desc to "alert message contains \"" & str & "\""
		set this_action to _dialog_text_contains(2, str, test_desc)
		try_action(this_action)
	end alert_message_contains
	
	on text_is(str) --> void
		set test_desc to "dialog text is \"" & str & "\""
		set this_action to _dialog_text_is(1, str, test_desc)
		try_action(this_action)
	end text_is
	
	on text_starts_with(str) --> void
		set test_desc to "dialog text starts with \"" & str & "\""
		set this_action to _dialog_text_starts_with(1, str, test_desc)
		try_action(this_action)
	end text_starts_with
	
	on text_contains(str) --> void
		set test_desc to "dialog text contains \"" & str & "\""
		set this_action to _dialog_text_contains(1, str, test_desc)
		try_action(this_action)
	end text_contains
	
	---
	
	-- Works for standard dialogs and list dialogs, but not alert dialogs.
	on dialog_title_is(str) --> void
		script this --> boolean
			property test_desc : "dialog title is \"" & str & "\""
			try
				tell application "System Events" to tell process id (my _process_id)
					set frontmost to true
					tell window 1
						title is str
					end tell
				end tell
			on error
				return false
			end try
		end script
		try_action(this)
	end dialog_title_is
	
	on is_alert_dialog() --> void
		script this --> boolean
			property test_desc : "is alert dialog"
			try
				tell application "System Events" to tell process id (my _process_id)
					set frontmost to true
					tell window 1
						role description is "dialog"
						description is "alert"
					end tell
				end tell
			on error
				return false
			end try
		end script
		try_action(this)
	end is_alert_dialog
	
	---
	
	on text_field_is(str) --> void
		script this --> boolean
			property test_desc : "text field is \"" & str & "\""
			try
				tell application "System Events" to tell process id (my _process_id)
					set frontmost to true
					tell window 1
						text field 1's value is str
					end tell
				end tell
			on error
				return false
			end try
		end script
		try_action(this)
	end text_field_is
	
	on text_field_contains(str) --> void
		script this --> boolean
			property test_desc : "text field contains \"" & str & "\""
			try
				tell application "System Events" to tell process id (my _process_id)
					set frontmost to true
					tell window 1
						text field 1's value contains str
					end tell
				end tell
			on error
				return false
			end try
		end script
		try_action(this)
	end text_field_contains
	
	on text_field_starts_with(str) --> void
		script this --> boolean
			property test_desc : "text field starts with \"" & str & "\""
			try
				tell application "System Events" to tell process id (my _process_id)
					set frontmost to true
					tell window 1
						text field 1's value starts with str
					end tell
				end tell
			on error
				return false
			end try
		end script
		try_action(this)
	end text_field_starts_with
	
	on text_field_ends_with(str) --> void
		script this --> boolean
			property test_desc : "text field ends with \"" & str & "\""
			try
				tell application "System Events" to tell process id (my _process_id)
					set frontmost to true
					tell window 1
						text field 1's value ends with str
					end tell
				end tell
			on error
				return false
			end try
		end script
		try_action(this)
	end text_field_ends_with
	
	-- -- -- Lists -- -- --
	
	(* Does list have at least one item selected? *)
	on list_has_selection() --> void
		script this --> boolean
			property test_desc : "list has a selection"
			tell application "System Events" to tell process id (my _process_id)
				set frontmost to true
				tell window 1
					tell scroll area 1's table 1
						try
							first row whose selected is true
						on error
							return false
						end try
					end tell
				end tell
			end tell
			return true
		end script
		try_action(this)
	end list_has_selection
	
	(* Are no list items selected? *)
	on list_has_no_selection() --> void
		script this --> boolean
			property test_desc : "list has no selection"
			tell application "System Events" to tell process id (my _process_id)
				set frontmost to true
				tell window 1
					tell scroll area 1's table 1
						try
							first row whose selected is true
							return false
						on error
							return true
						end try
					end tell
				end tell
			end tell
			return true
		end script
		try_action(this)
	end list_has_no_selection
	
	---
	
	on selected_list_item_is(str) --> void
		script this --> boolean
			property test_desc : "selected list item is \"" & str & "\""
			tell application "System Events" to tell process id (my _process_id)
				set frontmost to true
				tell window 1
					tell scroll area 1's table 1
						try
							return str is value of text field 1 of (first row whose selected is true)
						on error
							return false
						end try
					end tell
				end tell
			end tell
			return true
		end script
		try_action(this)
	end selected_list_item_is
	
	on selected_list_item_contains(str) --> void
		script this --> boolean
			property test_desc : "selected list item contains \"" & str & "\""
			tell application "System Events" to tell process id (my _process_id)
				set frontmost to true
				tell window 1
					tell scroll area 1's table 1
						try
							return value of text field 1 of (first row whose selected is true) contains str
						on error
							return false
						end try
					end tell
				end tell
			end tell
			return true
		end script
		try_action(this)
	end selected_list_item_contains
	
	---
	
	on has_list_item(str) --> void
		script this --> boolean
			property test_desc : "has list item " & str & "\""
			tell application "System Events" to tell process id (my _process_id)
				set frontmost to true
				tell window 1
					tell scroll area 1's table 1
						try
							first row whose text field 1's value is str
						on error
							return false
						end try
					end tell
				end tell
			end tell
			return true
		end script
		try_action(this)
	end has_list_item
	
	on has_list_item_containing(str) --> void
		script this --> boolean
			property test_desc : "has list item containing \"" & str & "\""
			tell application "System Events" to tell process id (my _process_id)
				set frontmost to true
				tell window 1
					tell scroll area 1's table 1
						try
							first row whose text field 1's value contains str
						on error
							return false
						end try
					end tell
				end tell
			end tell
			return true
		end script
		try_action(this)
	end has_list_item_containing
	
	---
	
	on has_list_items_containing(lst) --> void
		script this --> boolean
			property test_desc : "has list items containing \"" & _Util's join_list(lst, "\", \"") & "\""
			tell application "System Events" to tell process id (my _process_id)
				set frontmost to true
				tell window 1
					tell scroll area 1's table 1
						try
							repeat with this_str in lst
								(first row whose text field 1's value contains this_str)
							end repeat
						on error
							return false
						end try
					end tell
				end tell
			end tell
			return true
		end script
		try_action(this)
	end has_list_items_containing
	
	---
	
	on has_list_item_at_index(idx, str) --> void
		script this --> boolean
			property test_desc : "has list item at index " & idx & ": \"" & str & "\""
			tell application "System Events" to tell process id (my _process_id)
				set frontmost to true
				tell window 1
					tell scroll area 1's table 1
						try
							return row idx's text field 1's value is str
						on error
							return false
						end try
					end tell
				end tell
			end tell
			return true
		end script
		try_action(this)
	end has_list_item_at_index
	
	on has_similar_list_item_at_index(idx, str) --> void
		script this --> boolean
			property test_desc : "has similar list item at index " & idx & ": \"" & str & "\""
			tell application "System Events" to tell process id (my _process_id)
				set frontmost to true
				tell window 1
					tell scroll area 1's table 1
						try
							return row idx's text field 1's value contains str
						on error
							return false
						end try
					end tell
				end tell
			end tell
			return true
		end script
		try_action(this)
	end has_similar_list_item_at_index
	
	
	(* == Getters == *)
	
	on identify() --> string
		return my name
	end identify
end script

on _load_lib(script_lib)
	tell application "System Events" to set cur_dir to (path to me)'s container's POSIX path
	set this_lib to cur_dir & "/" & script_lib
	run script POSIX file this_lib
end _load_lib
