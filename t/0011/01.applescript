on run
	script
		property name : "01"
		property parent : _load_lib("../lib/test_gui.applescript")
		property _total_tests : 38 -- for calculating TAP plan (update as tests are added)
		
		on run_tests(model)
			init(model)
			set did_fail_test to false
			
			set all_sample_categories to paragraphs of "Apple:Mac OS X
Apple:iOS
Career
Design
Development
Development:AppleScript
Development:AppleScript:Mail
Education
General
Health
Health:Diet
Health:Fitness
Productivity:GTD"
			
			set root_sample_categories to paragraphs of "Apple
Career
Design
Development
Education
General
Health
Productivity"
			
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
				-- 19 (11 + 8)
				set idx to -(count root_sample_categories) -- = 8
				repeat with this_cat in root_sample_categories
					--log "# " & idx & space & this_cat
					has_list_item_at_index(idx, this_cat)
					set idx to idx + 1
				end repeat
				-- 20
				choose_list_item_containing("Show All Categories", "Next")
				
				-- 21
				dialog_title_is("Log Page > Title > URL > Category")
				-- 22
				list_has_no_selection()
				-- 23
				has_similar_list_item_at_index(1, "Edit Log File")
				-- 24
				has_similar_list_item_at_index(2, "View Log file")
				-- 37 (24 + 13)
				set idx to -(count all_sample_categories) -- = 13
				repeat with this_cat in all_sample_categories
					--log "# " & idx & space & this_cat
					has_list_item_at_index(idx, this_cat)
					set idx to idx + 1
				end repeat
				-- 38
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
