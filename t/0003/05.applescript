on run
	script
		property name : "05"
		property parent : _load_lib("../lib/test_gui.applescript")
		property _total_tests : 82 -- for calculating TAP plan (update as tests are added)
		
		on run_tests(model)
			init(model)
			set did_fail_test to false
			
			try
				--delay my _test_delay -- start with delay for first dialog
				
				-- 1
				dialog_title_is("Log Page > Title")
				-- 2
				text_field_is("Log Page Automated Tests")
				-- 3
				click_button("Next")
				
				-- 4
				dialog_title_is("Log Page > Title > URL")
				-- 5
				text_field_starts_with("file:///")
				-- 6
				text_field_ends_with("/t/data/sample.html")
				-- 7
				click_button("Next")
				
				-- 8
				dialog_title_is("Log Page > Title > URL > Category")
				-- 9
				selected_list_item_is("Development")
				-- 10
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 11
				has_similar_list_item_at_index(2, "New Category")
				-- 12
				choose_list_item_containing("Show All Categories", "Next")
				
				-- 13
				dialog_title_is("Log Page > Title > URL > Category")
				-- 14
				selected_list_item_is("Development:AppleScript")
				-- 15
				has_similar_list_item_at_index(1, "Edit Log")
				-- 16
				click_button("Back")
				
				-- 17
				dialog_title_is("Log Page > Title > URL > Category")
				-- 18
				selected_list_item_is("Development")
				-- 19
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 20
				has_similar_list_item_at_index(2, "New Category")
				-- 21
				choose_list_item_containing("New Category", "Next")
				
				-- 22
				dialog_title_is("Log Page > Title > URL > Category")
				-- 23
				text_field_is("Development:AppleScript")
				-- 24
				click_button("Back")
				
				-- 25
				dialog_title_is("Log Page > Title > URL > Category")
				-- 26
				selected_list_item_is("Development")
				-- 27
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 28
				has_similar_list_item_at_index(2, "New Category")
				-- 29
				choose_list_item_containing("Preferences", "Next")
				
				-- 30
				dialog_title_is("Log Page > Preferences")
				-- 31
				has_buttons({"File Editor/Viewer", "Log File", "OK"})
				-- 32
				click_button("OK")
				
				-- 33
				dialog_title_is("Log Page > Title > URL > Category")
				-- 34
				selected_list_item_is("Development")
				-- 35
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 36
				has_similar_list_item_at_index(2, "New Category")
				-- 37
				choose_list_item_containing("About Log page", "Next")
				
				-- 38
				is_alert_dialog()
				-- 39
				alert_title_is("Log Page")
				-- 40
				alert_message_starts_with("Log timestamped, ")
				-- 41
				alert_message_contains("Version")
				-- 42
				alert_message_contains("Copyright")
				-- 43
				has_buttons({"License", "Website", "OK"})
				-- 44
				click_button("OK")
				
				-- 45
				dialog_title_is("Log Page > Title > URL > Category")
				-- 46
				selected_list_item_is("Development")
				-- 47
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 48
				has_similar_list_item_at_index(2, "New Category")
				-- 49
				choose_list_item_containing("About Log Page", "Next")
				
				-- 50
				is_alert_dialog()
				-- 51
				alert_title_is("Log Page")
				-- 52
				alert_message_starts_with("Log timestamped, ")
				-- 53
				alert_message_contains("Version")
				-- 54
				alert_message_contains("Copyright")
				-- 55
				has_buttons({"License", "Website", "OK"})
				-- 56
				click_button("License")
				
				-- 57
				is_alert_dialog()
				-- 58
				alert_title_is("Log Page")
				-- 59
				alert_message_starts_with("Copyright")
				-- 60
				click_button("OK")
				
				-- 61
				dialog_title_is("Log Page > Title > URL > Category")
				-- 62
				selected_list_item_is("Development")
				-- 63
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 64
				has_similar_list_item_at_index(2, "New Category")
				-- 65
				choose_list_item_containing("Help", "Next")
				
				-- 66
				is_alert_dialog()
				-- 67
				alert_title_is("Log Page Help")
				-- 68
				has_buttons({"Preferences", "Cancel", "OK"})
				-- 69
				click_button("OK")
				
				-- 70
				dialog_title_is("Log Page > Title > URL > Category")
				-- 71
				selected_list_item_is("Development")
				-- 72
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 73
				has_similar_list_item_at_index(2, "New Category")
				-- 74
				choose_list_item_containing("Category Help", "Next")
				
				-- 75
				is_alert_dialog()
				-- 76
				alert_title_is("Log Page Category Help")
				-- 77
				click_button("OK")
				
				-- 78
				dialog_title_is("Log Page > Title > URL > Category")
				-- 79
				selected_list_item_is("Development")
				-- 80
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 81
				has_similar_list_item_at_index(2, "New Category")
				-- 82
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
