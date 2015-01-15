on run
	script
		property name : "01"
		property parent : _load_lib("../lib/test_gui.applescript")
		property _total_tests : 45 -- for calculating TAP plan (update as tests are added)
		
		on run_tests(model)
			init(model)
			set did_fail_test to false
			
			local tmp_logfile
			set tmp_logfile to model's get_tmp_dir() & "/" & model's get_test_suite() & "b-urls-chosen.txt"
			
			try
				delay my _test_delay -- start with delay for first dialog
				
				model's hide_browser()
				
				-- 1
				dialog_title_is("Log Page > Title")
				-- 2
				text_field_is("Log Page Automated Tests")
				-- 3
				click_button("Help")
				
				-- 4
				is_alert_dialog()
				-- 5
				alert_title_is("Log Page Help")
				-- 6
				has_buttons({"Preferences", "Cancel", "OK"})
				-- 7
				alert_message_contains("Log File:" & tab & tab & model's get_logfile())
				-- 8
				alert_message_contains("File Viewer:" & tab & "Safari")
				-- 9
				alert_message_contains("Text Editor:" & tab & "TextEdit")
				-- 10
				click_button("Preferences")
				
				-- 11
				dialog_title_is("Log Page > Preferences")
				-- 12
				has_buttons({"File Editor/Viewer", "Log File", "OK"})
				-- 13
				text_contains("Log File:" & tab & tab & model's get_logfile())
				-- 14
				text_contains("File Viewer:" & tab & "Safari")
				-- 15
				text_contains("Text Editor:" & tab & "TextEdit")
				-- 16
				click_button("Log File")
				
				-- 17
				dialog_title_is("Log Page > Preferences > Choose File")
				-- 18
				has_buttons({"Back", "OK"})
				-- 19
				has_list_items_containing({"Use Default", "Choose Existing", "Create New", "Type in", "Quit"})
				-- 20
				choose_list_item_containing("Type in", "OK")
				
				-- 21
				dialog_title_is("Log Page > Preferences > Choose File > Enter Path")
				-- 22
				has_buttons({"Back", "Cancel", "OK"})
				-- 23
				text_field_is(model's get_logfile())
				-- 24
				model's set_logfile(tmp_logfile)
				set_text_field(model's get_logfile())
				--log "# logfile = " & model's get_logfile()
				-- 25
				click_button("OK")
				delay 6 -- this can be is slow
				
				-- 26
				dialog_title_is("Log Page > Preferences")
				-- 27
				has_buttons({"File Editor/Viewer", "Log File", "OK"})
				-- 28
				text_contains("Log File:" & tab & tab & tmp_logfile)
				-- 29
				text_contains("File Viewer:" & tab & "Safari")
				-- 30
				text_contains("Text Editor:" & tab & "TextEdit")
				-- 31
				click_button("OK")
				
				-- 32
				dialog_title_is("Log Page > Title")
				-- 33
				text_field_is("Log Page Automated Tests")
				-- 34
				click_button("Next")
				
				-- 35
				dialog_title_is("Log Page > URL")
				-- 36
				text_field_starts_with("file:///")
				-- 37
				text_field_ends_with("/t/data/sample.html")
				-- 38
				click_button("Next")
				
				-- 39
				dialog_title_is("Log Page > Category")
				-- 40
				text_field_is("")
				-- 42
				set_text_field("TEST")
				-- 42
				click_button("Next")
				
				-- 43
				dialog_title_is("Log Page > Note")
				-- 44
				text_field_is("")
				-- 45
				click_button("Save")
				
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
