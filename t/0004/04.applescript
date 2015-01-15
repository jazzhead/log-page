on run
	script
		property name : "04"
		property parent : _load_lib("../lib/test_gui.applescript")
		property _total_tests : 15 -- for calculating TAP plan (update as tests are added)
		
		on run_tests(model)
			init(model)
			set did_fail_test to false
			
			try
				--delay my _test_delay -- start with delay for first dialog
				
				-- 1
				dialog_title_is("Log Page > Preferences > Choose Application")
				-- 2
				has_buttons({"Back", "Text Editor", "File Viewer"})
				-- 3
				text_contains("File Viewer:" & tab & "Safari")
				-- 4
				text_contains("Text Editor:" & tab & "TextEdit")
				-- 5
				click_button("Text Editor")
				
				-- 6
				dialog_title_is("Log Page > Preferences > Choose App > Editor")
				-- 7
				has_buttons({"Back", "Default Editor", "Another Editor"})
				-- 8
				click_button("Another Editor")
				
				-- 9
				delay 6 -- sometimes the system choose app dialog is slow
				dialog_title_is("Log Page > Preferences > Choose App > Editor > Choose Application")
				-- 10
				has_buttons({"Browse", "Cancel", "Choose"})
				-- 11
				choose_list_item_containing("Safari", "Choose")
				
				-- 12
				dialog_title_is("Log Page > Preferences > Choose Application")
				-- 13
				has_buttons({"Back", "Text Editor", "File Viewer"})
				-- 14
				text_contains("File Viewer:" & tab & "Safari")
				-- 15
				text_contains("Text Editor:" & tab & "Safari")
				
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
