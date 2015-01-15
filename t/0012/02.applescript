on run
	script
		property name : "02"
		property parent : _load_lib("../lib/test_data.applescript")
		property _total_tests : 2 -- for calculating TAP plan (update as tests are added)
		
		on run_tests(model)
			init(model)
			set did_fail_test to false
			
			try
				delay 4 -- give the save time to complete
				
				-- 1
				--log "# logfile = " & model's get_logfile()
				is_same_file(model's get_logfile(), expected_file_path("-urls.txt"), "bookmarks file")
				
				-- 2
				is_same_file(model's get_plist_file(), expected_file_path(".plist"), "plist file")
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
