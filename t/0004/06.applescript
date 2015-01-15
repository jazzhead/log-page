on run
	script
		property name : "06"
		property parent : _load_lib("../lib/test_gui.applescript")
		property _total_tests : 11 -- for calculating TAP plan (update as tests are added)
		
		on run_tests(model)
			init(model)
			set did_fail_test to false
			
			try
				--delay my _test_delay -- start with delay for first dialog
				
				-- 1
				click_button("Text Editor")
				
				-- 2
				dialog_title_is("Log Page > Preferences > Choose App > Editor")
				-- 3
				has_buttons({"Back", "Default Editor", "Another Editor"})
				-- 4
				click_button("Default Editor")
				
				-- 5
				dialog_title_is("Log Page > Preferences > Choose App > Editor > Default")
				-- 6
				has_buttons({"Back", "Cancel", "Use Default"})
				-- 7
				click_button("Use Default")
				
				-- 8
				dialog_title_is("Log Page > Preferences > Choose Application")
				-- 9
				has_buttons({"Back", "Text Editor", "File Viewer"})
				-- 10
				text_contains("File Viewer:" & tab & "Safari")
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
