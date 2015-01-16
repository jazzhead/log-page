on run
	script
		property name : "01"
		property parent : _load_lib("../lib/test_gui.applescript")
		property _total_tests : 65 -- for calculating TAP plan (update as tests are added)
		
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
				list_has_no_selection()
				-- 10
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 11
				has_similar_list_item_at_index(2, "New Category")
				-- 12
				has_list_item_at_index(-1, "TEST-2")
				-- 13
				has_list_item_at_index(-2, "TEST-1")
				-- 14
				choose_list_item("TEST-1", "Next")
				
				-- 15
				dialog_title_is("Log Page > Title > URL > Category")
				-- 16
				text_field_is("TEST-1")
				-- 17
				has_buttons({"Back", "Cancel", "Next"})
				-- 18
				click_button("Back")
				
				-- 19
				dialog_title_is("Log Page > Title > URL > Category")
				-- 20
				selected_list_item_is("TEST-1")
				-- 21
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 22
				has_similar_list_item_at_index(2, "New Category")
				-- 23
				has_list_item_at_index(-1, "TEST-2")
				-- 24
				has_list_item_at_index(-2, "TEST-1")
				-- 25
				choose_list_item("TEST-2", "Next")
				
				-- 26
				dialog_title_is("Log Page > Title > URL > Category")
				-- 27
				text_field_is("TEST-2")
				-- 28
				has_buttons({"Back", "Cancel", "Next"})
				-- 29
				click_button("Back")
				
				-- 30
				dialog_title_is("Log Page > Title > URL > Category")
				-- 31
				selected_list_item_is("TEST-2")
				-- 32
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 33
				has_similar_list_item_at_index(2, "New Category")
				-- 34
				has_list_item_at_index(-1, "TEST-2")
				-- 35
				has_list_item_at_index(-2, "TEST-1")
				-- 36
				choose_list_item_containing("Show All Categories", "Next")
				
				-- 37
				dialog_title_is("Log Page > Title > URL > Category")
				-- 38
				selected_list_item_is("TEST-2")
				-- 39
				has_similar_list_item_at_index(1, "Edit Log File")
				-- 40
				has_similar_list_item_at_index(2, "View Log file")
				-- 41
				has_list_item_at_index(-1, "TEST-2")
				-- 42
				has_list_item_at_index(-2, "TEST-1")
				-- 43
				click_button("Next")
				
				-- 44
				dialog_title_is("Log Page > Title > URL > Category")
				-- 45
				text_field_is("TEST-2")
				-- 46
				has_buttons({"Back", "Cancel", "Next"})
				-- 47
				click_button("Back")
				
				-- 48
				dialog_title_is("Log Page > Title > URL > Category")
				-- 49
				selected_list_item_is("TEST-2")
				-- 50
				has_similar_list_item_at_index(1, "Edit Log File")
				-- 51
				has_similar_list_item_at_index(2, "View Log file")
				-- 52
				has_list_item_at_index(-1, "TEST-2")
				-- 53
				has_list_item_at_index(-2, "TEST-1")
				-- 54
				click_button("Back")
				
				-- 55
				dialog_title_is("Log Page > Title > URL > Category")
				-- 56
				selected_list_item_is("TEST-2")
				-- 57
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 58
				has_similar_list_item_at_index(2, "New Category")
				-- 59
				has_list_item_at_index(-1, "TEST-2")
				-- 60
				has_list_item_at_index(-2, "TEST-1")
				-- 61
				click_button("Next")
				
				-- 62
				dialog_title_is("Log Page > Title > URL > Category")
				-- 63
				text_field_is("TEST-2")
				-- 64
				has_buttons({"Back", "Cancel", "Next"})
				-- 65
				click_button("Cancel")
				
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
