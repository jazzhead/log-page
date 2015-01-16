on run
	script
		property name : "07"
		property parent : _load_lib("../lib/test_gui.applescript")
		property _total_tests : 8 -- for calculating TAP plan (update as tests are added)
		
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
				set_text_field("Automated test")
				-- 8
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
