(*
 *  IMPORTANT:
 *  SET THE 'name' PROPERTY TO THE FIRST FOUR CHARACTERS (DIGITS) OF THIS FILE
 *  NAME. Also set the 'description' property to a brief description of the
 *  test. Finally, set the parameter to the init() call to true or false. A
 *  setting of false will trigger the target script's first-run dialog.  Most
 *  everything else is just boilerplate that is the same for all test suite
 *  wrappers, but there are a few other things that can be set up for a test
 *  such as providing an initial bookmarks file to test.
 *
 *  This is a controller (although not exactly since it actually subclasses the
 *  model) that is essentially just a wrapper for a group of tests. The actual
 *  test files are in a subdirectory named for the four digits of this script's
 *  `name` property (which is also the first four characters of this script's
 *  file name). This wrapper script subclasses `log_page_test.applescript`
 *  which is the model and provides the methods for running all of the tests.
 *  
 *  Additionally, this wrapper script actually has a wrapper script of its own:
 *  a shell script with the same base name. That is the script that actually
 *  gets run by the `prove` test harness because of an incompatibility between
 *  `prove` and `osascript`. The problem appears to be buffered output by
 *  `osascript` so the shell script wrapper disables buffering when calling
 *  `osascript`.
 *
 *  See the README file in the `t` directory for more info and a sample file
 *  listing with file descriptions.
 *)

on run argv -- argv is for 'run script with parameters' or osascript cli arguments
	script this
		property name : "0014" -- number identifier of this test suite
		property description : "Initially empty bookmarks file, choose new, nonexisting file"
		property parent : _load_lib("lib/log_page_test.applescript") --> extends Model
		
		on main(argv)
			-- Initialize required test settings based on this test's name
			--
			init(true) -- false = trigger first-run by not writing an initial prefs file.
			
			-- Any of the default (required) arguments can be overridden on the
			-- command-line.
			--
			if (count of argv) > 0 then
				set args_with_overrides to get_default_args() & argv
			else
				set args_with_overrides to get_default_args()
			end if
			
			-- Set up an initial bookmarks log file to test (by copying a
			-- sample file from `t/data/initial/`). The full sample file name
			-- and location are determined by the superclass and derived from
			-- this test suite name (the test suite ID is prepended to the
			-- name).
			--
			copy_initial_file("-urls.txt") -- initial bookmarks file (default from `init()`)
			
			-- Run the test suite
			--
			continue main(args_with_overrides)
		end main
	end script
	
	this's main(argv)
end run

on _load_lib(script_lib)
	tell application "System Events" to set cur_dir to (path to me)'s container's POSIX path
	set this_lib to cur_dir & "/" & script_lib
	run script POSIX file this_lib
end _load_lib
