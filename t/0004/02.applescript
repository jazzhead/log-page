on run
	script
		property name : "02"
		property parent : _load_lib("../lib/test_gui.applescript")
		property _total_tests : 41 -- for calculating TAP plan (update as tests are added)
		
		on run_tests(model)
			init(model)
			set did_fail_test to false
			
			try
				--delay my _test_delay -- start with delay for first dialog
				
				-- 1
				dialog_title_is("Log Page > Preferences > Choose File")
				-- 2
				has_buttons({"Back", "OK"})
				-- 3
				has_list_items_containing({"Use Default", "Choose Existing", "Create New", "Type in", "Quit"})
				-- 4
				choose_list_item_containing("Use Default", "OK")
				
				-- 5
				dialog_title_is("Log Page > Preferences > Choose File > Default")
				-- 6
				has_buttons({"Back", "Cancel", "Use Default"})
				-- 7
				text_contains(model's get_default_logfile())
				-- 8
				click_button("Back")
				
				-- 9
				dialog_title_is("Log Page > Preferences > Choose File")
				-- 10
				has_buttons({"Back", "OK"})
				-- 11
				has_list_items_containing({"Use Default", "Choose Existing", "Create New", "Type in", "Quit"})
				-- 12
				choose_list_item_containing("Choose Existing", "OK")
				
				-- 13
				delay 6 -- sometimes the system choose file dialog is slow
				dialog_title_is("Choose a File")
				-- 14
				has_buttons({"Cancel", "Choose"})
				-- 15
				click_button("Cancel")
				
				-- 16
				dialog_title_is("Log Page > Preferences > Choose File")
				-- 17
				has_buttons({"Back", "OK"})
				-- 18
				has_list_items_containing({"Use Default", "Choose Existing", "Create New", "Type in", "Quit"})
				-- 19
				choose_list_item_containing("Create New", "OK")
				
				-- 20
				dialog_title_is("Choose File Name")
				-- 21
				has_buttons({"Cancel", "Save"})
				-- 22
				text_field_is(model's get_test_suite() & "-urls.txt")
				-- 23
				click_button("Cancel")
				
				-- 24
				dialog_title_is("Log Page > Preferences > Choose File")
				-- 25
				has_buttons({"Back", "OK"})
				-- 26
				has_list_items_containing({"Use Default", "Choose Existing", "Create New", "Type in", "Quit"})
				-- 27
				choose_list_item_containing("Type in", "OK")
				
				-- 28
				dialog_title_is("Log Page > Preferences > Choose File > Enter Path")
				-- 29
				has_buttons({"Back", "Cancel", "OK"})
				-- 30
				text_field_is(model's get_logfile())
				-- 31
				click_button("Back")
				
				-- 32
				dialog_title_is("Log Page > Preferences > Choose File")
				-- 33
				has_buttons({"Back", "OK"})
				-- 34
				has_list_items_containing({"Use Default", "Choose Existing", "Create New", "Type in", "Quit"})
				-- 35
				click_button("Back")
				
				-- 36
				dialog_title_is("Log Page > Preferences")
				-- 37
				has_buttons({"File Editor/Viewer", "Log File", "OK"})
				-- 38
				text_contains("Log File:" & tab & tab & model's get_logfile())
				-- 39
				text_contains("File Viewer:" & tab & "Safari")
				-- 40
				text_contains("Text Editor:" & tab & "TextEdit")
				-- 41
				click_button("File Editor/Viewer")
				
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
