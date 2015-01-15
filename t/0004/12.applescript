on run
	script
		property name : "12"
		property parent : _load_lib("../lib/test_gui.applescript")
		property _total_tests : 20 -- for calculating TAP plan (update as tests are added)
		
		property _Util : _load_lib("../lib/util.applescript")
		
		on run_tests(model)
			init(model)
			set did_fail_test to false
			
			local tmp_logfile
			set tmp_logfile to model's get_tmp_dir() & "/" & model's get_test_suite() & "-test-urls.txt"
			
			try
				--delay my _test_delay -- start with delay for first dialog
				
				-- 1
				dialog_title_is("Log Page > Preferences")
				-- 2
				has_buttons({"File Editor/Viewer", "Log File", "OK"})
				-- 3
				text_contains("Log File:" & tab & tab & model's get_logfile())
				-- 4
				text_contains("File Viewer:" & tab & "Safari")
				-- 5
				text_contains("Text Editor:" & tab & "TextEdit")
				-- 6
				click_button("Log File")
				
				-- 7
				dialog_title_is("Log Page > Preferences > Choose File")
				-- 8
				has_buttons({"Back", "OK"})
				-- 9
				has_list_items_containing({"Use Default", "Choose Existing", "Create New", "Type in", "Quit"})
				-- 10
				choose_list_item_containing("Type in", "OK")
				
				-- 11
				dialog_title_is("Log Page > Preferences > Choose File > Enter Path")
				-- 12
				has_buttons({"Back", "Cancel", "OK"})
				-- 13
				text_field_is(model's get_logfile())
				-- 14
				model's set_logfile(tmp_logfile)
				set_text_field(model's get_logfile())
				--log "# logfile = " & model's get_logfile()
				-- 15
				click_button("OK")
				delay 6 -- this can be is slow
				
				-- 16
				dialog_title_is("Log Page > Preferences")
				-- 17
				has_buttons({"File Editor/Viewer", "Log File", "OK"})
				-- 18
				text_contains("Log File:" & tab & tab & tmp_logfile)
				-- 19
				text_contains("File Viewer:" & tab & "Safari")
				-- 20
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
