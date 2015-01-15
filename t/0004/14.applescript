on run
	script
		property name : "14"
		property parent : _load_lib("../lib/test_gui.applescript")
		property _total_tests : 14 -- for calculating TAP plan (update as tests are added)
		
		on run_tests(model)
			init(model)
			set did_fail_test to false
			
			try
				--delay my _test_delay -- start with delay for first dialog
				
				-- 1
				click_button("Log File")
				
				-- 2
				dialog_title_is("Log Page > Preferences > Choose File")
				-- 3
				has_buttons({"Back", "OK"})
				-- 4
				has_list_items_containing({"Use Default", "Choose Existing", "Create New", "Type in", "Quit"})
				-- 5
				choose_list_item_containing("Use Default", "OK")
				
				-- 6
				dialog_title_is("Log Page > Preferences > Choose File > Default")
				-- 7
				has_buttons({"Back", "Cancel", "Use Default"})
				-- 8
				text_contains(model's get_default_logfile())
				-- 9
				click_button("Use Default")
				model's set_logfile(model's get_default_logfile())
				delay 6 -- this can be is slow
				
				-- 10
				dialog_title_is("Log Page > Preferences")
				-- 11
				has_buttons({"File Editor/Viewer", "Log File", "OK"})
				-- 12
				text_contains("Log File:" & tab & tab & model's get_logfile())
				-- 13
				text_contains("File Viewer:" & tab & "Safari")
				-- 14
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
