on run
	script
		property name : "03"
		property parent : _load_lib("../lib/test_gui.applescript")
		property _total_tests : 26 -- for calculating TAP plan (update as tests are added)
		
		on run_tests(model)
			init(model)
			set did_fail_test to false
			
			try
				--delay my _test_delay -- start with delay for first dialog
				
				-- 1
				dialog_title_is("Log Page > Category")
				-- 2
				list_has_no_selection()
				-- 3
				choose_list_item("Development:AppleScript", "Next")
				
				-- 4
				dialog_title_is("Log Page > Category")
				-- 5
				text_field_is("Development:AppleScript")
				-- 6
				click_button("Next")
				
				-- 7
				dialog_title_is("Log Page > Note")
				-- 8
				text_field_is("")
				-- 9
				set_text_field("Automated test")
				-- 10
				click_button("Back")
				
				-- 11
				dialog_title_is("Log Page > Category")
				-- 12
				text_field_is("Development:AppleScript")
				-- 13
				click_button("Back")
				
				-- 14
				dialog_title_is("Log Page > Category")
				-- 15
				selected_list_item_is("Development:AppleScript")
				-- 16
				click_button("Back")
				
				-- 17
				dialog_title_is("Log Page > Category")
				-- 18
				selected_list_item_is("Development")
				-- 19
				click_button("Back")
				
				-- 20
				dialog_title_is("Log Page > URL")
				-- 21
				text_field_starts_with("file:///")
				-- 22
				text_field_ends_with("/t/data/sample.html")
				-- 23
				click_button("Back")
				
				-- 24
				dialog_title_is("Log Page > Title")
				-- 25
				text_field_is("Log Page Automated Tests")
				-- 26
				click_button("Help")
				
				
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
