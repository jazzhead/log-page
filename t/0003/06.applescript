on run
	script
		property name : "06"
		property parent : _load_lib("../lib/test_gui.applescript")
		property _total_tests : 51 -- for calculating TAP plan (update as tests are added)
		
		on run_tests(model)
			init(model)
			set did_fail_test to false
			
			try
				--delay my _test_delay -- start with delay for first dialog
				
				-- 1
				dialog_title_is("Log Page > Title > URL > Category")
				-- 2
				selected_list_item_is("Development:AppleScript")
				-- 3
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 4
				has_similar_list_item_at_index(3, "Edit Log File")
				-- 5
				choose_list_item_containing("Show All Categories", "Next")
				
				-- 6
				dialog_title_is("Log Page > Title > URL > Category")
				-- 7
				selected_list_item_is("Development:AppleScript")
				-- 8
				has_similar_list_item_at_index(1, "Edit Log")
				-- 9
				click_button("Back")
				
				-- 10
				dialog_title_is("Log Page > Title > URL > Category")
				-- 11
				selected_list_item_is("Development:AppleScript")
				-- 12
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 13
				has_similar_list_item_at_index(3, "Edit Log File")
				-- 14
				choose_list_item_containing("Preferences", "Next")
				
				-- 15
				dialog_title_is("Log Page > Preferences")
				-- 16
				has_buttons({"File Editor/Viewer", "Log File", "OK"})
				-- 17
				click_button("OK")
				
				-- 18
				dialog_title_is("Log Page > Title > URL > Category")
				-- 19
				selected_list_item_is("Development:AppleScript")
				-- 20
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 21
				has_similar_list_item_at_index(3, "Edit Log File")
				-- 22
				choose_list_item_containing("About Log Page", "Next")
				
				-- 23
				is_alert_dialog()
				-- 24
				alert_title_is("Log Page")
				-- 25
				alert_message_starts_with("Log timestamped, ")
				-- 26
				alert_message_contains("Version")
				-- 27
				alert_message_contains("Copyright")
				-- 28
				has_buttons({"License", "Website", "OK"})
				-- 29
				click_button("OK")
				
				-- 30
				dialog_title_is("Log Page > Title > URL > Category")
				-- 31
				selected_list_item_is("Development:AppleScript")
				-- 32
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 33
				has_similar_list_item_at_index(3, "Edit Log File")
				-- 34
				choose_list_item_containing("Help", "Next")
				
				-- 35
				is_alert_dialog()
				-- 36
				alert_title_is("Log Page Help")
				-- 37
				has_buttons({"Preferences", "Cancel", "OK"})
				-- 38
				click_button("OK")
				
				-- 39
				dialog_title_is("Log Page > Title > URL > Category")
				-- 40
				selected_list_item_is("Development:AppleScript")
				-- 41
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 42
				has_similar_list_item_at_index(3, "Edit Log File")
				-- 43
				choose_list_item_containing("Category Help", "Next")
				
				-- 44
				is_alert_dialog()
				-- 45
				alert_title_is("Log Page Category Help")
				-- 46
				click_button("OK")
				
				-- 47
				dialog_title_is("Log Page > Title > URL > Category")
				-- 48
				selected_list_item_is("Development:AppleScript")
				-- 49
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 50
				has_similar_list_item_at_index(3, "Edit Log File")
				-- 51
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
