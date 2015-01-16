on run
	script
		property name : "16"
		property parent : _load_lib("../lib/test_gui.applescript")
		property _total_tests : 6 -- for calculating TAP plan (update as tests are added)
		
		on run_tests(model)
			init(model)
			set did_fail_test to false
			
			try
				--delay my _test_delay -- start with delay for first dialog
				
				-- 1
				click_button("OK")

				-- 2
				dialog_title_is("Log Page > Title > URL > Category")
				-- 3
				list_has_no_selection()
				-- 4
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 5
				has_similar_list_item_at_index(2, "New Category")
				-- 6
				choose_list_item_containing("Quit", "Next")
				
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
