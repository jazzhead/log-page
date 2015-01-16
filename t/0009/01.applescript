on run
	script
		property name : "01"
		property parent : _load_lib("../lib/test_gui.applescript")
		property _total_tests : 80 -- for calculating TAP plan (update as tests are added)
		
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
				choose_list_item("TEST-2", "Next")
				
				-- 15
				dialog_title_is("Log Page > Title > URL > Category")
				-- 16
				text_field_is("TEST-2")
				-- 17
				has_buttons({"Back", "Cancel", "Next"})
				-- 18
				click_button("Back")
				
				-- 19
				dialog_title_is("Log Page > Title > URL > Category")
				-- 20
				selected_list_item_is("TEST-2")
				-- 21
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 22
				has_similar_list_item_at_index(2, "New Category")
				-- 23
				has_list_item_at_index(-1, "TEST-2")
				-- 24
				has_list_item_at_index(-2, "TEST-1")
				-- 25
				choose_list_item("TEST-1", "Next")
				
				-- 26
				dialog_title_is("Log Page > Title > URL > Category")
				-- 27
				list_has_no_selection()
				-- 28
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 29
				has_similar_list_item_at_index(3, "Edit Log File")
				-- 30
				has_list_item_at_index(-1, "TEST-1:Subcategory 2")
				-- 31
				has_list_item_at_index(-2, "TEST-1:Subcategory 1")
				-- 32
				choose_list_item("TEST-1:Subcategory 1", "Next")
				
				-- 33
				dialog_title_is("Log Page > Title > URL > Category")
				-- 34
				text_field_is("TEST-1:Subcategory 1")
				-- 35
				has_buttons({"Back", "Cancel", "Next"})
				-- 36
				click_button("Back")
				
				-- 37
				dialog_title_is("Log Page > Title > URL > Category")
				-- 38
				selected_list_item_is("TEST-1:Subcategory 1")
				-- 39
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 40
				has_similar_list_item_at_index(3, "Edit Log File")
				-- 41
				has_list_item_at_index(-1, "TEST-1:Subcategory 2")
				-- 42
				has_list_item_at_index(-2, "TEST-1:Subcategory 1")
				-- 43
				choose_list_item_containing("Show All Categories", "Next")
				
				-- 44
				dialog_title_is("Log Page > Title > URL > Category")
				-- 45
				selected_list_item_is("TEST-1:Subcategory 1")
				-- 46
				has_similar_list_item_at_index(1, "Edit Log File")
				-- 47
				has_similar_list_item_at_index(2, "View Log file")
				-- 48
				has_list_item_at_index(-1, "TEST-2")
				-- 49
				has_list_item_at_index(-2, "TEST-1:Subcategory 2")
				-- 50
				has_list_item_at_index(-3, "TEST-1:Subcategory 1")
				-- 51
				click_button("Back")
				
				-- 52
				dialog_title_is("Log Page > Title > URL > Category")
				-- 53
				selected_list_item_is("TEST-1:Subcategory 1")
				-- 54
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 55
				has_similar_list_item_at_index(3, "Edit Log File")
				-- 56
				has_list_item_at_index(-1, "TEST-1:Subcategory 2")
				-- 57
				has_list_item_at_index(-2, "TEST-1:Subcategory 1")
				-- 58
				click_button("Back")
				
				-- 59
				dialog_title_is("Log Page > Title > URL > Category")
				-- 60
				selected_list_item_is("TEST-1")
				-- 61
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 62
				has_similar_list_item_at_index(2, "New Category")
				-- 63
				has_list_item_at_index(-1, "TEST-2")
				-- 64
				has_list_item_at_index(-2, "TEST-1")
				-- 65
				choose_list_item_containing("Show All Categories", "Next")
				
				-- 66
				dialog_title_is("Log Page > Title > URL > Category")
				-- 67
				selected_list_item_is("TEST-1:Subcategory 1")
				-- 68
				has_similar_list_item_at_index(1, "Edit Log File")
				-- 69
				has_similar_list_item_at_index(2, "View Log file")
				-- 70
				has_list_item_at_index(-1, "TEST-2")
				-- 71
				has_list_item_at_index(-2, "TEST-1:Subcategory 2")
				-- 72
				has_list_item_at_index(-3, "TEST-1:Subcategory 1")
				-- 73
				click_button("Back")
				
				-- 74
				dialog_title_is("Log Page > Title > URL > Category")
				-- 75
				selected_list_item_is("TEST-1")
				-- 76
				has_similar_list_item_at_index(1, "Show All Categories")
				-- 77
				has_similar_list_item_at_index(2, "New Category")
				-- 78
				has_list_item_at_index(-1, "TEST-2")
				-- 79
				has_list_item_at_index(-2, "TEST-1")
				-- 80
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
