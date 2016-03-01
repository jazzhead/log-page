Log Page Development
====================

[Log Page][website] is an object-oriented AppleScript program for Mac OS X
written using Model-View-Controller (MVC) and other design patterns. Although
the primary function of the script is to simply grab a web page title and URL
from a web browser, parse a plain text file, and append data to that file, the
script also handles setting preferences and editing the bookmark data before it
is written, and the user interface is comprised of many different elements
(using AppleScript's basic modal dialogs) with full navigation history between
views. So MVC was a way to get everything under control and keep it
maintainable.

For those not familiar with object-oriented programming in AppleScript,
AppleScript only has limited object-oriented support and it is prototype-based,
not class-based. So that's why you'll see a lot of what appear to be classes
wrapped in constructor functions.

When testing and working on the script, there are some patch files in this
`dev` directory which change some variables so that your usual bookmarks log
file is not altered if you've already been using this script (details below).
Even better, run the script from the command-line using `osascript` and pass in
arguments to configure different variables at runtime such as the bookmarks log
file location, plist file location, and debug level. The automated tests use
such command-line arguments as do the Makefile targets for running those tests.


Command-line Configuration with osascript
-----------------------------------------

During development, Log Page can easily be configured to use an alternate plist
(property list) file and bookmarks log file by running the script from the
command-line and passing in arguments. You'll usually want to set the debug
level as well to enable event logging which is output to the Terminal. The
example below shows how to set the debug level (a level of 2 enables the most
logging), the plist file name (bundle ID) and directory, and the bookmarks log
file location.

Before running the command, first switch to the web browser that you want to
test to bring it to the front. Then switch directly to the Terminal app, `cd`
to the Log Page source code directory, and run:

```bash
$ osascript log_page.applescript \
  DEBUG_LEVEL:2 \
  BUNDLE_ID:LogPage.DEBUG \
  PLIST_DIR:~/Desktop \
  DEFAULT_LOGFILE:~/Desktop/log-page-urls-debug.txt
```


Automated Integration Testing
-----------------------------

There is a full, automated test suite available for Log Page that tests the
graphical user interface as well as generated files. The tests can be run with
`make test` or `make test-quiet`. Details are in the [t/README] file.


Development Debugging Patches
-----------------------------

The patch files in this directory are for applying to the working tree during
development and testing to avoid writing to your usual bookmarks log file and
usual plist preferences file if you've already been using this script. The
patches should always be reversed before making any commits. _(Instead of
applying and reversing these patches and running the script in (Apple)Script
Editor during development, the script can be run from the command-line with
`osascript` where the various configuration settings can be passed in as
arguments without having to change the variables in the actual file. See the
"Command-line Configuration with osascript" section above.)_

### Debugging Patch Descriptions

The `dev/debug.patch` file modifies the `__BUNDLE_ID__` script property so that
the usual plist file (where preference settings are saved) for this program is
not used or modified. Instead, a plist file with `.DEBUG` appended to the file
name is used so different preference settings can be tried without affecting
your usual settings. I use this to select a new or different bookmarks file for
testing so that my usual bookmarks file isn't modified. The patch also
increases the `__DEBUG_LEVEL__` script property so that messages are logged to
the event log.

The `dev/null_io.patch` file alters the `__NULL_IO__` script property so that
changes are never written to your actual bookmarks file even though your usual
bookmarks file and preference settings are used. (Your usual plist file is
still written to though so any preference changes are saved and the last
category used is still updated.)

The `debug+null_io.patch` file applies both patches.

The rest of this file describes applying and reversing the `dev/debug.patch`
file, but the procedure is the same for the other patch files as well.

### Applying the Debugging Patches

Apply the patch:

```bash
$ git apply dev/debug.patch
```

Before applying the patch, you can see a summary of what's in it with:

```bash
$ git apply --stat dev/debug.patch
```

To test the patch without applying it, use:

```bash
$ git apply --check dev/debug.patch
```


Reversing the Debugging Patch
-----------------------------

**Never** commit any of the debugging patch changes. Always either add
interactively to skip the changes, or just apply the patch in reverse before
adding and committing. The latter approach is much quicker and easier if no
changes were made that cause the patch to fail.

### Reverse Patch (Best Method)

To skip the `debug.patch` changes before committing just revert them manually
in the file or apply the patch in reverse:

```bash
$ git apply -R dev/debug.patch
```

This might be the best way since the patch can easily be reapplied after
committing.

### Interactive Add (Alternate Method)

_The other method (reverse patch) is probably better than this one if the patch
still applies cleanly._

Another method is to use `git add -i` to interactively add new changes while
skipping over the changes to `__BUNDLE_ID__`, `__DEBUG_LEVEL_`, and
`__NULL_IO__`. In the interactive session, after skipping over those changes
with `s`, the rest of the changes can be added all at once with `a`.

```bash
$ git add -i log_page.applescript
```

After committing, if the patch changes were the only changes skipped, those
changes can be deleted by running:

```bash
$ git reset --hard HEAD
```

**Only** do that if you don't want to keep any uncommitted changes because it
deletes those changes. If you skipped other changes when you added and
committed and want to keep them without committing them yet, use:

```bash
$ git stash
```

  [website]: http://jazzheaddesign.com/work/code/log-page/
  [t/README]: ../t/README.md
