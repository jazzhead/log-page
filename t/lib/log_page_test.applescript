(*
 *  Log Page Test - Includes GUI testing for AppleScript dialogs
 *
 *  This is the main testing class for Log Page and should be subclassed by
 *  test suite wrappers.  Those short test suite wrappers are essentially
 *  controllers that basically just provide an identifier (the script's 'name'
 *  property) that allows this superclass to find all related test scripts for
 *  the suite. They also do any other configuration necessary before running
 *  the tests. Additionally, they serve as a file to easily feed to the 'prove'
 *  test harness. (Actually, those AppleScript wrappers have to be called from
 *  a shell script wrapper that disables output buffering and those shell
 *  scripts are the scripts fed to 'prove').
 *
 *  The subclasses call this class's `main()` method passing any command-line
 *  arguments as parameters. The `main()` method then launches the target
 *  script being tested (configuring it if any args were provided) and then
 *  sets up and runs all the tests that it finds (based on the name/identifier
 *  of the calling subclass).
 *
 *  @date   2015-01-14 Last modified
 *  @date   2015-01-03 First version
 *  @author Steve Wheeler
 *)

script
	property name : "LogPageTest"
	property class : "LogPageTest"
	property description : "Run test suites for subclasses"
	property _Util : _load_lib("util.applescript")
	
	property _target_script : "log_page.applescript" -- relative to project root directory
	property _sample_page_name : "sample.html"
	property _expected_data_dir : "/data/expected" -- relative to test directory
	property _initial_data_dir : "/data/initial" -- relative to test directory
	
	property _sample_page : missing value -- full location
	property _process_id : missing value
	property _unix_id : missing value
	property _tmp_dir : missing value
	property _test_dir : missing value
	property _test_count : missing value -- updated during each test run
	property _test_suite : missing value
	property _plist_file : missing value
	property _logfile : missing value -- the bookmarks log file to write to
	
	property _footer_boilerplate : missing value
	property _s_test : missing value -- either an "s" or "" (for indicating plural)
	
	-- Target Script Defaults (CLI configurable)
	--
	-- Required defaults to supply to the target script being tested. They are
	-- configured by the subclass calling script with the init() method and can
	-- be overridden with command-line arguments. See _parse_arg() for the
	-- command-line arg format.
	--
	property __BUNDLE_ID__ : missing value
	property __PLIST_DIR__ : missing value
	property __DEFAULT_LOGFILE__ : missing value
	
	-- Test Suite Defaults (CLI configurable)
	--
	-- Default values for the test suite that can be modified from the
	-- command-line by passing arguments to osascript. See _parse_args() for
	-- the arg format.
	--
	property __TEST_DELAY__ : 1 -- for viewing dialogs during testing
	property __INFO_DELAY__ : 20 -- for viewing the test description and results
	property __SKIP_INFO__ : false -- show test info before & after tests or not
	property __TARGET_BROWSER__ : "Safari"
	
	
	(*
	 *  Initialize required test settings based on a test's name
	 *
	 *  To trigger the target script's first-run setup, don't write an initial
	 *  preferences file.
	 *
	 *  @param (boolean) Should an initial preferences file be written.
	 *)
	on init(should_write_prefs) --> void
		set _test_suite to my name
		set __BUNDLE_ID__ to _test_suite & "-net.jazzhead.scpt.LogPage"
		set _test_dir to _Util's get_cur_dir()
		
		set _tmp_dir to _Util's shorten_home_path(_test_dir & "/tmp")
		set _plist_file to _tmp_dir & "/" & __BUNDLE_ID__ & ".plist"
		
		set __PLIST_DIR__ to _tmp_dir
		set __DEFAULT_LOGFILE__ to _Util's shorten_home_path(_tmp_dir & "/" & _test_suite & "-urls.txt")
		
		set _logfile to __DEFAULT_LOGFILE__ -- initially same as default (can be changed during test run)
		
		_set_sample_page(_test_dir & "/data")
		
		_set_footer_boilerplate()
		
		-- Delete any leftover test files from previous tests
		try -- in case there are no previous files
			do shell script "rm" & space & _tmp_dir & "/" & _test_suite & "*"
		end try
		
		if should_write_prefs then
			--
			-- Target script defaults written to a custom plist file for this
			-- test. To trigger the target script's first-run setup, skip
			-- writing any of these three preference settings. The target
			-- script can still be configured for these tests by passing
			-- arguments to the run_tests() method.
			--
			_Util's write_pref(_plist_file, "logFile", __DEFAULT_LOGFILE__)
			_Util's write_pref(_plist_file, "textEditor", "TextEdit")
			_Util's write_pref(_plist_file, "fileViewer", "Safari")
		end if
	end init
	
	
	(*
	 *  This is the primary function that sets up and runs all of the tests for
	 *  a given test suite. Called from a subclass (the test suite). It uses
	 *  the 'name' property of the subclass to determine which individual test
	 *  files to load and run.
	 *)
	on main(argv) --> void
		local test_groups_passed, test_file_count
		set test_groups_passed to {}
		set test_file_count to 0
		
		set _test_count to 0
		
		-- This is needed when running from Script Editor to bring this
		-- script's dialog to the front after launching the target script with
		-- its dialog.  When running this script from the command-line with
		-- osascript, it makes no difference.
		--
		tell application "System Events"
			set current_process to first process where it is frontmost
		end tell
		
		-- Process any arguments passed in from osascript to modify this
		-- script's associated properties and to pass on args meant for the
		-- target script.
		--
		set target_args to _parse_args(argv)
		
		-- Open the sample HTML page in the target browser
		--
		tell application (__TARGET_BROWSER__) to activate
		set s to "open -a " & __TARGET_BROWSER__ & space & _sample_page
		do shell script s
		delay 4 -- Give the browser time to activate and load the page; increase if necessary
		
		-- Launch the target script to test (and put it in the background so
		-- this test script can continue)
		--
		_launch_target_script(target_args)
		
		-- Show the test info (can be skipped by passing 'SKIP_INFO:true' CLI
		-- arg)
		--
		_show_test_info(current_process)
		
		-- Set up GUI
		--
		tell application "System Events"
			--
			-- The specific process id must be targeted because when running
			-- the tests from the command-line, there will be at least two
			-- osascript processes, so targetting by name or reference will not
			-- work. The process id is captured in a variable so that it can be
			-- accessed by any other handlers that need it.
			--
			set _process_id to id of first process whose unix id is _unix_id
			tell process id _process_id
				set frontmost to true
				delay 1
				--UI elements -- : DEBUG:
			end tell
		end tell
		
		-- Run the tests to interact with the target script's dialogs.
		-- XXX: One of the model's methods probably shouldn't be calling other
		-- controllers, but this is like a combination model/controller so
		-- that's what's happening here.
		--
		set {test_groups_passed, test_file_count, did_fail_test} to _run_test_files(test_groups_passed, test_file_count)
		
		-- Report back (can be skipped by passing 'SKIP_INFO:true' CLI arg)
		--
		_show_report(current_process, test_groups_passed, did_fail_test)
		
		return -- don't pollute TAP output
	end main
	
	
	(* == Setters == *)
	
	on set_logfile(str) --> void
		set _logfile to str
	end set_logfile
	
	
	(* == Getters == *)
	
	on get_process_id() --> int
		return _process_id
	end get_process_id
	
	---
	
	on get_test_delay() --> int
		return __TEST_DELAY__
	end get_test_delay
	
	on get_test_count() --> int
		return _test_count
	end get_test_count
	
	on get_test_suite() --> string
		return _test_suite
	end get_test_suite
	
	on get_default_args() --> string
		return {"BUNDLE_ID:" & __BUNDLE_ID__, "PLIST_DIR:" & __PLIST_DIR__, "DEFAULT_LOGFILE:" & __DEFAULT_LOGFILE__}
	end get_default_args
	
	---
	
	on get_logfile() --> string
		return _logfile
	end get_logfile
	
	on get_default_logfile() --> string
		return __DEFAULT_LOGFILE__
	end get_default_logfile
	
	on get_plist_file() --> string
		return _plist_file
	end get_plist_file
	
	on get_sample_page_path() --> string
		return _sample_page
	end get_sample_page_path
	
	---
	
	on get_test_dir() --> string
		return _test_dir
	end get_test_dir
	
	on get_tmp_dir() --> string
		return _tmp_dir
	end get_tmp_dir
	
	on get_expected_data_dir() --> string
		return _test_dir & _expected_data_dir
	end get_expected_data_dir
	
	on get_initial_data_dir() --> string
		return _test_dir & _initial_data_dir
	end get_initial_data_dir
	
	
	(* == Helpers == *)
	
	(*
	 *  Copy a file from the initial data directory to the test tmp directory.
	 *
	 *  The test suite ID is automatically prepended to the name, so just
	 *  supply the rest of the file name including the file extension.
	 *
	 *  @param Name+extension of file to copy (w/o test suite ID)
	 *)
	on copy_initial_file(file_name) --> void
		local from_path, s
		set from_path to (get_initial_data_dir() & "/" & _test_suite & file_name)
		set s to "cp" & space & from_path & space & _tmp_dir
		do shell script s
	end copy_initial_file
	
	on hide_browser()
		-- So the TAP results can be viewed in real time in the Terminal. Don't
		-- call before the page title dialog has be displayed for the first
		-- time.
		tell application "System Events"
			set visible of process __TARGET_BROWSER__ to false
		end tell
	end hide_browser
	
	
	(* == Private == *)
	
	(*
	 *  Parse Command-Line Arguments (from osascript)
	 *
	 *  Configuration settings stored in script properties can be modified on
	 *  start-up by passing in command arguments from `osascript`. The arguments
	 *  will need both a key and a value in the format "key:value".  The keys
	 *  are then parsed to assign the right value to the right property. See the
	 *  handler's conditional statements for available keys (which need to be
	 *  hard-coded because of AppleScript limitations).
	 *
	 *  Any arguments meant for the target script are reassembled as a text
	 *  string and returned to pass on to the target script.
	 *
	 *  @param argv Array of arguments in "key:value" format.
	 *  @return Modifies script properties. Returns string w/args for target script.
	 *)
	on _parse_args(argv) --> string
		local args, k, v, target_args
		
		if (count of argv) = 0 then return ""
		
		-- Parse arguments into key/value pairs
		set args to {}
		repeat with i from 1 to count argv
			if argv's item i's class is in {string, text, number} then
				set {k, v} to _Util's split_text(argv's item i, ":")
				set end of args to {key:k, val:v}
			end if
		end repeat
		
		-- Modify this script's property values for matching keys and pass back
		-- any args meant for the target script instead
		set target_args to {}
		repeat with this_arg in args
			if this_arg's key is "TEST_DELAY" then
				set __TEST_DELAY__ to this_arg's val
			else if this_arg's key is "INFO_DELAY" then
				set __INFO_DELAY__ to this_arg's val
			else if this_arg's key is "SKIP_INFO" then
				set __SKIP_INFO__ to this_arg's val as boolean
			else if this_arg's key is "TARGET_BROWSER" then
				set __TARGET_BROWSER__ to this_arg's val
			else if this_arg's key is in {"BUNDLE_ID", "PLIST_DIR", "DEFAULT_LOGFILE", "DEBUG_LEVEL", "NULL_IO"} then
				-- These args are meant for the target script so reassemble them
				-- to pass along
				set end of target_args to (this_arg's key & ":" & this_arg's val)
			end if
		end repeat
		return _Util's join_list(target_args, space)
	end _parse_args
	
	on _set_sample_page(sample_path) --> void
		if sample_path's last character is not "/" then set sample_path to sample_path & "/"
		set _sample_page to "file://" & sample_path & _sample_page_name
	end _set_sample_page
	
	on _set_footer_boilerplate()
		local s
		if not __SKIP_INFO__ then
			-- singular or plural for info dialogs
			if __TEST_DELAY__ > 1 then
				set _s_test to "s"
			else
				set _s_test to ""
			end if
			if __INFO_DELAY__ > 1 then
				set s to "s"
			else
				set s to ""
			end if
			
			set _footer_boilerplate to "(This dialog will dismiss automatically after " & __INFO_DELAY__ & " second" & s & ". It can be skipped by passing a 'SKIP_INFO:true' argument on the command-line.)"
		end if
	end _set_footer_boilerplate
	
	on _launch_target_script(target_args) --> void
		set proj_dir to do shell script "dirname " & _test_dir
		set target_script_path to proj_dir & "/" & _target_script
		
		-- This shell script runs the target script using `osascript` and sends
		-- the process to the background. The `sh` special variable `$!` is the
		-- ID of the most recent background command. That ID is echoed so it
		-- can be captured in a variable which will be used for finding the GUI
		-- process.
		--
		set s to "osascript " & target_script_path & space & target_args & " >/dev/null 2>&1 & echo $!"
		--set s to "osascript " & target_script_path & space & target_args & " 2>&1 & echo $!" -- :DEBUG: for seeing the target script's debugging messages
		set _unix_id to do shell script s
		
		delay 2
	end _launch_target_script
	
	on _cancel_target_script() --> void
		tell application "System Events"
			--return properties of every process whose name is "osascript" -- :DEBUG:
			tell process id (id of first process whose unix id is _unix_id) -- the target script
				set frontmost to true
				delay 1
				tell window 1 -- target by index; dialog titles could vary
					try
						--log "Trying to click the cancel button in target script dialog."
						-- (alternate way to 'click button'; just for reference)
						tell button "Cancel" to perform action "AXPress"
						-- :DEBUG: there might not be a cancel button
						--tell button "FOO" to perform action "AXPress"
					on error
						--log "Target script dialog didn't have a cancel button. Killing the process."
						tell me to do shell script "kill " & _unix_id
					end try
				end tell
			end tell
		end tell
	end _cancel_target_script
	
	on _run_test_files(test_groups_passed, test_file_count) --> array (array, int, boolean)
		set these_tests to _get_test_scripts()
		set total_tests to my _get_test_total(these_tests)
		
		log "" -- XXX: for prove/osascript funkiness
		log "1.." & total_tests -- TAP plan
		log "#############################" -- TAP diagnostic
		log "# Test Suite " & my name & " - " & my description & " (" & total_tests & " tests)" -- TAP diagnostic
		
		if these_tests's length > 0 then
			repeat with this_test in these_tests
				set test_group to this_test's identify()
				
				log "###" -- TAP diagnostic
				log "# test group " & my name & "/" & test_group & " (" & this_test's get_test_total() & " tests)" -- TAP diagnostic
				log "###" -- TAP diagnostic
				
				-- Run the test, passing it the model
				set {did_fail_test, test_num} to this_test's run_tests(me)
				
				if did_fail_test then
					-- Don't terminate script yet so results can be shown first
					set group_count to this_test's get_group_count()
					exit repeat
				end if
				set _test_count to _test_count + (this_test's get_test_total())
				set test_file_count to test_file_count + 1
				set end of test_groups_passed to "(" & this_test's get_group_count() & ") " & my name & "/" & test_group
			end repeat
		else
			return {{}, 0, false}
		end if
		
		return {test_groups_passed, test_file_count, did_fail_test}
	end _run_test_files
	
	on _get_test_scripts() --> array (of script objects)
		try
			set test_scripts to paragraphs of (do shell script "ls -1 " & _test_dir & "/" & my name & "/[0-9][0-9]*.applescript")
		on error
			set test_scripts to {}
		end try
		
		set these_tests to {}
		repeat with test_file in test_scripts
			set end of these_tests to run script POSIX file test_file
		end repeat
		return these_tests
	end _get_test_scripts
	
	on _get_test_total(these_tests) --> int
		local total_tests
		set total_tests to 0
		repeat with this_test in these_tests
			set total_tests to total_tests + (this_test's get_test_total())
		end repeat
		return total_tests
	end _get_test_total
	
	on _format_group_list(group_list) --> string
		local group_list
		repeat with i from 1 to count group_list
			set group_list's item i to "    " & group_list's item i
		end repeat
		_Util's join_list(group_list, return)
	end _format_group_list
	
	on _show_test_info(current_process) --> string
		if not __SKIP_INFO__ then
			set t to "Test " & my name
			set m to "Running test " & my name & " with a viewing delay of " & __TEST_DELAY__ & " second" & _s_test & "."
			set b to {"Cancel", "Run Tests"}
			set footer to "After clicking " & b's item 2 & ", don't click on any other dialogs until testing is complete. The test script will handle all dialog interaction." & return & return & _footer_boilerplate
			set m to m & return & return & footer
			
			tell application "System Events" to set frontmost of current_process to true
			
			try
				display alert t message m buttons b default button 2 cancel button 1 giving up after __INFO_DELAY__
			on error
				-- Cancel target script being tested
				log "# Canceling target script"
				my _cancel_target_script()
				-- Finish canceling this script
				log "# Canceling test script"
				error "User canceled." number -128
			end try
			
			delay 1
		end if
	end _show_test_info
	
	on _show_report(current_process, test_groups_passed, did_fail_test) --> void
		if did_fail_test then
			try
				do shell script "kill " & _unix_id
			on error err_msg number err_num
				log "# " & err_msg & " (" & err_num & ")"
			end try
			if not __SKIP_INFO__ then
				set m to "Test number " & test_num & " failed (test " & group_count & " of test group " & my name & "/" & test_group & "). The rest of the tests were not run." & return & return & Â
					"Tests passed:" & return & return Â
					& my _format_group_list(test_groups_passed)
				set alert_type to critical
			end if
		else
			if not __SKIP_INFO__ then
				set m to "All " & _test_count & " tests passed successfully." & return & return & Â
					"Tests passed (by group):" & return & return Â
					& my _format_group_list(test_groups_passed)
				set alert_type to informational
			end if
		end if
		if not __SKIP_INFO__ then
			set t to "Test " & my name
			set footer to _footer_boilerplate
			set m to m & return & return & footer
			tell application "System Events" to set frontmost of current_process to true
			display alert t message m giving up after __INFO_DELAY__ as alert_type
		end if
	end _show_report
end script

on _load_lib(script_lib)
	tell application "System Events" to set cur_dir to (path to me)'s container's POSIX path
	set this_lib to cur_dir & "/" & script_lib
	run script POSIX file this_lib
end _load_lib
