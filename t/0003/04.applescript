on run
	script
		property name : "04"
		property parent : _load_lib("../lib/test_gui.applescript")
		property _total_tests : 14 -- for calculating TAP plan (update as tests are added)
		
		on run_tests(model)
			init(model)
			set did_fail_test to false
			
			try
				--delay my _test_delay -- start with delay for first dialog
				
				-- 1
				is_alert_dialog()
				-- 2
				alert_title_is("Log Page Help")
				-- 3
				has_buttons({"Preferences", "Cancel", "OK"})
				-- 4
				click_button("OK")
				
				-- 5
				dialog_title_is("Log Page > Title")
				-- 6
				text_field_is("Log Page Automated Tests")
				-- 7
				click_button("Help")
				
				-- 8
				is_alert_dialog()
				-- 9
				alert_title_is("Log Page Help")
				-- 10
				has_buttons({"Preferences", "Cancel", "OK"})
				-- 11
				click_button("Preferences")
				
				-- 12
				dialog_title_is("Log Page > Preferences")
				-- 13
				has_buttons({"File Editor/Viewer", "Log File", "OK"})
				-- 14
				click_button("OK")
				
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
