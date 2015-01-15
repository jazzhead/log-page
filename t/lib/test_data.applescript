(*
 *  This library is specific to testing Log Page data, but could be easily
 *  adapted for other scripts by modifying the `_expected_subdir` value and
 *  the placheholder regex replacement patterns.
 *
 *  This library is meant to be subclassed by the actual test files. It
 *  subclasses the TAP library so that the TAP functions are available to those
 *  test subclasses.
 *)
script
	property name : "TestData"
	property class : "TestData"
	property parent : _load_lib("tap.applescript") -- extends "TAP" (for this class's subclasses)
	property _Util : _load_lib("util.applescript")
	property _model : missing value
	
	
	-- Fetch any data needed from the model
	on init(model)
		set _model to model
		set_test_count(_model's get_test_count()) -- TAP
	end init
	
	
	(* == Private == *)
	
	-- Placeholder replacement patterns
	--
	on _timestamp_pattern() --> string
		quoted form of "s/^(Date  \\| )[0-9]{4}(-[0-9]{2}){2} [0-9]{2}(:[0-9]{2}){2}$/\\1YYYY-MM-DD hh:mm:ss/"
	end _timestamp_pattern
	--
	on _sample_page_pattern() --> string
		quoted form of ("s!^(URL   \\| )\\{SAMPLE_PAGE\\}$!\\1" & _model's get_sample_page_path() & "!")
	end _sample_page_pattern
	--
	on _logfile_pattern() --> string
		quoted form of ("s!\\{BOOKMARKS_FILE\\}!" & _model's get_logfile() & "!")
	end _logfile_pattern
	--
	on _tmpdir_pattern() --> string
		quoted form of ("s!\\{TMP_DIR\\}!" & _model's get_tmp_dir() & "!")
	end _tmpdir_pattern
	
	
	-- Replace all placeholders
	on _replace_placeholders(file_path) --> string
		set s to "LANG=C cat " & file_path & " | sed -E -e " & _timestamp_pattern() & " -e " & _sample_page_pattern() & " -e " & _logfile_pattern() & " -e " & _tmpdir_pattern()
		do shell script s without altering line endings
	end _replace_placeholders
	
	
	(* == Tests == *)
	
	on is_same_file(result_file, expected_file, file_desc) --> void
		script this --> boolean
			property test_desc : file_desc & " result matches expected"
			try
				return _replace_placeholders(result_file) is _replace_placeholders(expected_file)
			on error
				return false
			end try
		end script
		--log "# is_same_file(): result_file = " & result_file
		--log "# is_same_file(): expected_file = " & expected_file
		try_action(this)
	end is_same_file
	
	
	(* == Helpers == *)
	
	on expected_file_path(str)
		_model's get_expected_data_dir() & "/" & _model's get_test_suite() & str as string
	end expected_file_path
	
	
	(* == Getters == *)
	
	on identify() --> string
		return my name
	end identify
end script

on _load_lib(script_lib)
	tell application "System Events" to set cur_dir to (path to me)'s container's POSIX path
	set this_lib to cur_dir & "/" & script_lib
	run script POSIX file this_lib
end _load_lib
