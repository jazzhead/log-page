on run
	script
		property name : "02"
		property parent : _load_lib("../lib/test_gui.applescript")
		property _total_tests : 16 -- for calculating TAP plan (update as tests are added)
		
		on run_tests(model)
			init(model)
			set did_fail_test to false
			
			try
				--delay my _test_delay -- start with delay for first dialog
				
				-- 1
				dialog_title_is("Log Page > Title > URL > Category")
				-- 2
				text_field_is("Development:AppleScript")
				-- 3
				set_text_field("Development:AppleScript:TEST")
				-- 4
				click_button("Next")
				
				-- 5
				dialog_title_is("Log Page > Title > URL > Category > Note")
				-- 6
				text_field_is("")
				-- 7
				click_button("Back")
				
				-- 8
				dialog_title_is("Log Page > Title > URL > Category")
				-- 9
				text_field_is("Development:AppleScript:TEST")
				-- 10
				click_button("Back")
				
				-- 11
				dialog_title_is("Log Page > Title > URL > Category")
				-- 12
				list_has_no_selection()
				-- 13
				click_button("Back")
				
				-- 14
				dialog_title_is("Log Page > Title > URL > Category")
				-- 15
				selected_list_item_is("Development")
				-- 16
				click_button("Next")
				
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
