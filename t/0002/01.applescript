on run
	script
		property name : "01"
		property parent : _load_lib("../lib/test_gui.applescript")
		property _total_tests : 78 -- for calculating TAP plan (update as tests are added)
		
		on run_tests(model)
			init(model)
			set did_fail_test to false
			
			local tmp_logfile
			set tmp_logfile to model's get_tmp_dir() & "/" & model's get_test_suite() & "-test-urls.txt"
			
			try
				delay my _test_delay -- start with delay for first dialog
				
				-- 1
				is_alert_dialog()
				-- 2
				alert_title_is("Log Page")
				-- 3
				alert_message_starts_with("Copyright")
				-- 4
				click_button("OK")
				
				-- 5
				is_alert_dialog()
				-- 6
				alert_title_is("Log Page")
				-- 7
				alert_message_contains("Log File:" & tab & tab & model's get_logfile())
				-- 8
				alert_message_contains("File Viewer:" & tab & "Safari")
				-- 9
				alert_message_contains("Text Editor:" & tab & "TextEdit")
				-- 10
				has_buttons({"Change Settings", "Cancel", "Use Defaults"})
				-- 11
				click_button("Change Settings")
				
				-- 12
				dialog_title_is("Log Page > Preferences")
				-- 13
				has_buttons({"File Editor/Viewer", "Log File", "OK"})
				-- 14
				text_contains("Log File:" & tab & tab & model's get_logfile())
				-- 15
				text_contains("File Viewer:" & tab & "Safari")
				-- 16
				text_contains("Text Editor:" & tab & "TextEdit")
				-- 17
				click_button("File Editor/Viewer")
				
				-- 18
				dialog_title_is("Log Page > Preferences > Choose Application")
				-- 19
				has_buttons({"Back", "Text Editor", "File Viewer"})
				-- 20
				text_contains("File Viewer:" & tab & "Safari")
				-- 21
				text_contains("Text Editor:" & tab & "TextEdit")
				-- 22
				click_button("Text Editor")
				
				-- 23
				dialog_title_is("Log Page > Preferences > Choose App > Editor")
				-- 24
				has_buttons({"Back", "Default Editor", "Another Editor"})
				-- 25
				click_button("Another Editor")
				
				-- 26
				delay 6 -- sometimes the system choose app dialog is slow
				dialog_title_is("Log Page > Preferences > Choose App > Editor > Choose Application")
				-- 27
				has_buttons({"Browse", "Cancel", "Choose"})
				-- 28
				choose_list_item_containing("Safari", "Choose")
				
				-- 29
				dialog_title_is("Log Page > Preferences > Choose Application")
				-- 30
				has_buttons({"Back", "Text Editor", "File Viewer"})
				-- 31
				text_contains("File Viewer:" & tab & "Safari")
				-- 32
				text_contains("Text Editor:" & tab & "Safari")
				-- 33
				click_button("File Viewer")
				
				-- 34
				dialog_title_is("Log Page > Preferences > Choose App > Viewer")
				-- 35
				has_buttons({"Back", "Default App", "Another App"})
				-- 36
				click_button("Another App")
				
				-- 37
				delay 6 -- sometimes the system choose app dialog is slow
				dialog_title_is("Log Page > Preferences > Choose App > Viewer > Choose Application")
				-- 38
				has_buttons({"Browse", "Cancel", "Choose"})
				-- 39
				choose_list_item_containing("TextEdit", "Choose")
				
				-- 40
				dialog_title_is("Log Page > Preferences > Choose Application")
				-- 41
				has_buttons({"Back", "Text Editor", "File Viewer"})
				-- 42
				text_contains("File Viewer:" & tab & "TextEdit")
				-- 43
				text_contains("Text Editor:" & tab & "Safari")
				-- 44
				click_button("Back")
				
				-- 45
				dialog_title_is("Log Page > Preferences")
				-- 46
				has_buttons({"File Editor/Viewer", "Log File", "OK"})
				-- 47
				text_contains("Log File:" & tab & tab & model's get_logfile())
				-- 48
				text_contains("File Viewer:" & tab & "TextEdit")
				-- 49
				text_contains("Text Editor:" & tab & "Safari")
				-- 50
				click_button("Log File")
				
				-- 51
				dialog_title_is("Log Page > Preferences > Choose File")
				-- 52
				has_buttons({"Back", "OK"})
				-- 53
				has_list_items_containing({"Use Default", "Choose Existing", "Create New", "Type in", "Quit"})
				-- 54
				choose_list_item_containing("Type in", "OK")
				
				-- 55
				dialog_title_is("Log Page > Preferences > Choose File > Enter Path")
				-- 56
				has_buttons({"Back", "Cancel", "OK"})
				-- 57
				text_field_is(model's get_logfile())
				-- 58
				model's set_logfile(tmp_logfile)
				set_text_field(model's get_logfile())
				--log "# logfile = " & model's get_logfile()
				-- 59
				click_button("OK")
				delay 6 -- this can be is slow
				
				-- 60
				dialog_title_is("Log Page > Preferences")
				-- 61
				has_buttons({"File Editor/Viewer", "Log File", "OK"})
				-- 62
				text_contains("Log File:" & tab & tab & tmp_logfile)
				-- 63
				text_contains("File Viewer:" & tab & "TextEdit")
				-- 64
				text_contains("Text Editor:" & tab & "Safari")
				-- 65
				click_button("OK")
				
				-- 66
				dialog_title_is("Log Page > Title")
				-- 67
				text_field_is("Log Page Automated Tests")
				-- 68
				click_button("Help")
				
				-- 69
				is_alert_dialog()
				-- 70
				alert_title_is("Log Page Help")
				-- 71
				alert_message_contains("Log File:" & tab & tab & tmp_logfile)
				-- 72
				alert_message_contains("File Viewer:" & tab & "TextEdit")
				-- 73
				alert_message_contains("Text Editor:" & tab & "Safari")
				-- 74
				has_buttons({"Preferences", "Cancel", "OK"})
				-- 75
				click_button("OK")
				
				-- 76
				dialog_title_is("Log Page > Title")
				-- 77
				text_field_is("Log Page Automated Tests")
				-- 78
				click_button("Cancel")
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
