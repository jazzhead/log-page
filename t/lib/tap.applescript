script
	property name : "TAP"
	property class : "TAP"
	
	-- Properties used by subclasses
	property _test_count : missing value -- incremented as tests are run
	property _group_count : 0 -- internal group test count
	
	
	(* == Private == *)
	
	on _format_test_desc(test_desc) --> string -- PRIVATE
		return my _test_count & " - " & test_desc
	end _format_test_desc
	
	on _ok(test_desc) --> string -- PRIVATE
		return "ok " & my _format_test_desc(test_desc)
	end _ok
	
	on _not_ok(test_desc) --> string -- PRIVATE
		return "not ok " & my _format_test_desc(test_desc)
	end _not_ok
	
	on _inc_test_count() --> void -- PRIVATE
		set my _test_count to (my _test_count) + 1
		set my _group_count to (my _group_count) + 1
	end _inc_test_count
	
	
	(* == TAP Functions == *)
	
	on ok(test_desc) --> void
		_inc_test_count()
		log _ok(test_desc)
	end ok
	
	on not_ok(test_desc) --> void
		_inc_test_count()
		log _not_ok(test_desc)
	end not_ok
	
	on skip_ok(test_desc, skip_desc) --> void
		_inc_test_count()
		log _ok(test_desc) & " # SKIP " & skip_desc
	end skip_ok
	
	on skip_not_ok(test_desc, skip_desc) --> void
		_inc_test_count()
		log _not_ok(test_desc) & " # SKIP " & skip_desc
	end skip_not_ok
	
	on todo_ok(test_desc, todo_desc) --> void
		_inc_test_count()
		log _ok(test_desc) & " # TODO " & todo_desc
	end todo_ok
	
	on todo_not_ok(test_desc, todo_desc) --> void
		_inc_test_count()
		log _not_ok(test_desc) & " # TODO " & todo_desc
	end todo_not_ok
	
	on bail_out(bail_desc) --> void
		log "Bail out! " & bail_desc
		error bail_desc
	end bail_out
	
	
	(* == Helpers == *)
	
	on try_action(this_action) --> void
		try
			set ret_val to run this_action -- a script object
			if not ret_val then error "Test failed"
			my ok(this_action's test_desc)
		on error err_msg number err_num
			log "# Error: " & err_msg & " (" & err_num & ")"
			my not_ok(this_action's test_desc)
			my bail_out("Can't continue testing.")
		end try
	end try_action
	
	
	(* == Setters == *)
	
	on set_test_count(cur_count) --> void
		set my _test_count to cur_count
	end set_test_count
	
	
	(* == Getters == *)
	
	on get_test_count() --> int
		return my _test_count
	end get_test_count
	
	on get_test_total() --> int
		return my _total_tests
	end get_test_total
	
	on get_group_count() --> int
		return my _group_count
	end get_group_count
end script

on _load_lib(script_lib)
	tell application "System Events" to set cur_dir to (path to me)'s container's POSIX path
	set this_lib to cur_dir & "/" & script_lib
	run script POSIX file this_lib
end _load_lib
