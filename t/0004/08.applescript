on run
	script
		property name : "08"
		property parent : _load_lib("../lib/test_gui.applescript")
		property _total_tests : 11 -- for calculating TAP plan (update as tests are added)
		
		on run_tests(model)
			init(model)
			set did_fail_test to false
			
			try
				--delay my _test_delay -- start with delay for first dialog
				
				-- 1
				click_button("File Viewer")
				
				-- 2
				dialog_title_is("Log Page > Preferences > Choose App > Viewer")
				-- 3
				has_buttons({"Back", "Default App", "Another App"})
				-- 4
				click_button("Another App")
				
				-- 5
				delay 6 -- sometimes the system choose app dialog is slow
				dialog_title_is("Log Page > Preferences > Choose App > Viewer > Choose Application")
				-- 6
				has_buttons({"Browse", "Cancel", "Choose"})
				-- 7
				choose_list_item_containing("TextEdit", "Choose")
				
				-- 8
				dialog_title_is("Log Page > Preferences > Choose Application")
				-- 9
				has_buttons({"Back", "Text Editor", "File Viewer"})
				-- 10
				text_contains("File Viewer:" & tab & "TextEdit")
				-- 11
				text_contains("Text Editor:" & tab & "TextEdit")
				
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
