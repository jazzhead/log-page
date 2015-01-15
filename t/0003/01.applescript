on run
	script
		property name : "01"
		property parent : _load_lib("../lib/test_gui.applescript")
		property _total_tests : 20 -- for calculating TAP plan (update as tests are added)
		
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
				dialog_title_is("Log Page > URL")
				-- 5
				text_field_starts_with("file:///")
				-- 6
				text_field_ends_with("/t/data/sample.html")
				-- 7
				click_button("Next")
				
				-- 8
				dialog_title_is("Log Page > Category")
				-- 9
				list_has_no_selection()
				-- 10
				choose_list_item("Development", "Next")
				
				-- 11
				dialog_title_is("Log Page > Category")
				-- 12
				list_has_no_selection()
				-- 13
				choose_list_item("Development:AppleScript", "Next")
				
				-- 14
				dialog_title_is("Log Page > Category")
				-- 15
				text_field_is("Development:AppleScript")
				-- 16
				click_button("Next")
				
				-- 17
				dialog_title_is("Log Page > Note")
				-- 18
				text_field_is("")
				-- 19
				set_text_field("Automated test")
				-- 20
				click_button("Back")
				
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
