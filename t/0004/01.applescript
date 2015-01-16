on run
	script
		property name : "01"
		property parent : _load_lib("../lib/test_gui.applescript")
		property _total_tests : 69 -- for calculating TAP plan (update as tests are added)
		
		on run_tests(model)
			init(model)
			set did_fail_test to false
			
			try
				delay my _test_delay -- start with delay for first dialog

				model's hide_browser()
				
				-- 1
				dialog_title_is("Log Page > Title")
				-- 2
				text_field_is("Log Page Automated Tests")
				-- 3
				click_button("Next")
				
				-- 4
				dialog_title_is("Log Page > Title > URL")
				-- 5
				text_field_starts_with("file:///")
				-- 6
				text_field_ends_with("/t/data/sample.html")
				-- 7
				click_button("Next")
				
				-- 8
				dialog_title_is("Log Page > Title > URL > Category")
				-- 9
				list_has_no_selection()
				-- 10
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 11
				has_similar_list_item_at_index(2, "New Category")
				-- 12
				choose_list_item_containing("Preferences", "Next")
				
				-- 13
				dialog_title_is("Log Page > Preferences")
				-- 14
				has_buttons({"File Editor/Viewer", "Log File", "OK"})
				-- 15
				text_contains("Log File:" & tab & tab & model's get_logfile())
				-- 16
				text_contains("File Viewer:" & tab & "Safari")
				-- 17
				text_contains("Text Editor:" & tab & "TextEdit")
				-- 18
				click_button("Editor/Viewer")
				
				-- 19
				dialog_title_is("Log Page > Preferences > Choose Application")
				-- 20
				has_buttons({"Back", "Text Editor", "File Viewer"})
				-- 21
				text_contains("File Viewer:" & tab & "Safari")
				-- 22
				text_contains("Text Editor:" & tab & "TextEdit")
				-- 23
				click_button("Text Editor")
				
				-- 24
				dialog_title_is("Log Page > Preferences > Choose App > Editor")
				-- 25
				has_buttons({"Back", "Default Editor", "Another Editor"})
				-- 26
				click_button("Default Editor")
				
				-- 27
				dialog_title_is("Log Page > Preferences > Choose App > Editor > Default")
				-- 28
				has_buttons({"Back", "Cancel", "Use Default"})
				-- 29
				click_button("Back")
				
				-- 30
				dialog_title_is("Log Page > Preferences > Choose App > Editor")
				-- 31
				has_buttons({"Back", "Default Editor", "Another Editor"})
				-- 32
				click_button("Another Editor")
				
				-- 33
				delay 6 -- sometimes the system choose app dialog is slow
				dialog_title_is("Log Page > Preferences > Choose App > Editor > Choose Application")
				-- 34
				has_buttons({"Browse", "Cancel", "Choose"})
				-- 35
				click_button("Cancel") -- acts as Back button
				
				-- 36
				dialog_title_is("Log Page > Preferences > Choose App > Editor")
				-- 37
				has_buttons({"Back", "Default Editor", "Another Editor"})
				-- 38
				click_button("Back")
				
				-- 39
				dialog_title_is("Log Page > Preferences > Choose Application")
				-- 40
				has_buttons({"Back", "Text Editor", "File Viewer"})
				-- 41
				text_contains("File Viewer:" & tab & "Safari")
				-- 42
				text_contains("Text Editor:" & tab & "TextEdit")
				-- 43
				click_button("File Viewer")
				
				-- 44
				dialog_title_is("Log Page > Preferences > Choose App > Viewer")
				-- 45
				has_buttons({"Back", "Default App", "Another App"})
				-- 46
				click_button("Default App")
				
				-- 47
				dialog_title_is("Log Page > Preferences > Choose App > Viewer > Default")
				-- 48
				has_buttons({"Back", "Cancel", "Use Default"})
				-- 49
				click_button("Back")
				
				-- 50
				dialog_title_is("Log Page > Preferences > Choose App > Viewer")
				-- 51
				has_buttons({"Back", "Default App", "Another App"})
				-- 52
				click_button("Another App")
				
				-- 53
				delay 6 -- sometimes the system choose app dialog is slow
				dialog_title_is("Log Page > Preferences > Choose App > Viewer > Choose Application")
				-- 54
				has_buttons({"Browse", "Cancel", "Choose"})
				-- 55
				click_button("Cancel") -- acts as Back button
				
				-- 56
				dialog_title_is("Log Page > Preferences > Choose App > Viewer")
				-- 57
				has_buttons({"Back", "Default App", "Another App"})
				-- 58
				click_button("Back")
				
				-- 59
				dialog_title_is("Log Page > Preferences > Choose Application")
				-- 60
				has_buttons({"Back", "Text Editor", "File Viewer"})
				-- 61
				text_contains("File Viewer:" & tab & "Safari")
				-- 62
				text_contains("Text Editor:" & tab & "TextEdit")
				-- 63
				click_button("Back")
				
				-- 64
				dialog_title_is("Log Page > Preferences")
				-- 65
				has_buttons({"File Editor/Viewer", "Log File", "OK"})
				-- 66
				text_contains("Log File:" & tab & tab & model's get_logfile())
				-- 67
				text_contains("File Viewer:" & tab & "Safari")
				-- 68
				text_contains("Text Editor:" & tab & "TextEdit")
				-- 69
				click_button("Log File")
				
				--delay my test_delay
			on error err_msg number err_num
				--error err_msg number err_num -- :DEBUG: terminate immediately
				set did_fail_test to true
			end try
			return {did_fail_test, my _test_count}
		end run_tests
	end script
end run

on _load_lib(script_lib)
	tell application "System Events" to set cur_dir to (path to me)'s container's POSIX path
	set this_lib to cur_dir & "/" & script_lib
	run script POSIX file this_lib
end _load_lib
