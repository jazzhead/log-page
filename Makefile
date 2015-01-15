##############################################################################
#
# Makefile for Log Page
#
# Author:  Steve Wheeler
#
##############################################################################

# Version used for distributions (when there is no git repo).
# BEFORE tagging release, update version number.
VERSION = 0.0.0

SHELL   = /bin/sh


# If run from a git repo, then override the version above with
# a version derived from git tags formatted as `v[0-9]*`.
ifneq (,$(wildcard .git))
VERSION := $(subst v,,$(shell git describe --match "v[0-9]*" --dirty --always))
# NOTE: Remove the `--always` option to exit if git can't find a tag
#       instead of falling back to an abbreviated commit hash.
endif


# AppleScript source code file
SOURCE     = log_page.applescript
# AppleScript target compiled file
TARGET     = Log\ Page.scpt

# Set the type (-t) and creator (-c) codes when compiling just like
# AppleScript Editor does. The codes are useful for Spotlight searches.
# If the -t and -c options are omitted, no codes are set.
OSACOMPILE = osacompile -t osas -c ToyS -o

# Tools
RM         = rm -rf
SED        = LANG=C sed
MKDIR      = mkdir -p
PROVE      = prove -f

# Build directory
BUILD     = _build
# Build target
PROG     :=  $(BUILD)/$(TARGET)

prefix    = $(HOME)/Library/Scripts/Applications
# Installation directory
bindir   := $(prefix)/Safari

INSTALL      = install
INSTDIR     := $(bindir)
INSTOPTS     = -pSv     # Don't use -b option; backups show up in script menu
INSTMODE     = -m 0600
INSTDIRMODE  = -m 0700

# Installation directories for alternate browsers
CHROMEDIR   := $(prefix)/Google\ Chrome
FIREFOXDIR  := $(prefix)/Firefox
WEBKITDIR   := $(prefix)/WebKit

# For files or directories that have backslash-escaped spaces, make variables
# without the escapes to use for AppleScript (osascript)
TARGET_AS     := $(subst \,,$(TARGET))
CHROMEDIR_AS  := $(subst \,,$(CHROMEDIR))

TEST_TMP = t/tmp


# ==== TARGETS ===============================================================

# ---- Default rule

all: $(PROG)

# ---- Default install

# The default install command installs the script for Safari and then makes
# aliases of the script for the other browsers

install: install-safari
	@echo "* The 'install' target installs the script for Safari and then"
	@echo "* creates aliases of the script for all the other browsers."
	@$(MKDIR) $(INSTDIRMODE) $(CHROMEDIR) $(FIREFOXDIR) $(WEBKITDIR)
	@echo "--->  Installing aliases for Chrome, Firefox and WebKit..."
	$(call trash-installed,$(CHROMEDIR_AS)/$(TARGET_AS))
	$(call make-alias,$(INSTDIR),$(TARGET_AS),$(CHROMEDIR_AS))
	$(call trash-installed,$(FIREFOXDIR)/$(TARGET_AS))
	$(call make-alias,$(INSTDIR),$(TARGET_AS),$(FIREFOXDIR))
	$(call trash-installed,$(WEBKITDIR)/$(TARGET_AS))
	$(call make-alias,$(INSTDIR),$(TARGET_AS),$(WEBKITDIR))

# ---- Individual installations

install-safari: all
	$(call trash-installed,$(INSTDIR)/$(TARGET_AS))
	@echo "--->  Installing '$(TARGET)' into '$(INSTDIR)'..."
	@$(INSTALL) -dv $(INSTDIRMODE) $(INSTDIR) && \
	$(INSTALL) $(INSTOPTS) $(INSTMODE) $(PROG) $(INSTDIR)

install-chrome: all
	$(call trash-installed,$(CHROMEDIR_AS)/$(TARGET_AS))
	@echo "--->  Installing '$(TARGET)' into '$(CHROMEDIR)'..."
	@$(INSTALL) -dv $(INSTDIRMODE) $(CHROMEDIR) && \
	$(INSTALL) $(INSTOPTS) $(INSTMODE) $(PROG) $(CHROMEDIR)

install-firefox: all
	$(call trash-installed,$(FIREFOXDIR)/$(TARGET_AS))
	@echo "--->  Installing '$(TARGET)' into '$(FIREFOXDIR)'..."
	@$(INSTALL) -dv $(INSTDIRMODE) $(FIREFOXDIR) && \
	$(INSTALL) $(INSTOPTS) $(INSTMODE) $(PROG) $(FIREFOXDIR)

install-webkit: all
	$(call trash-installed,$(WEBKITDIR)/$(TARGET_AS))
	@echo "--->  Installing '$(TARGET)' into '$(WEBKITDIR)'..."
	@$(INSTALL) -dv $(INSTDIRMODE) $(WEBKITDIR) && \
	$(INSTALL) $(INSTOPTS) $(INSTMODE) $(PROG) $(WEBKITDIR)

# ----

uninstall:
	@echo "--->  Uninstalling '$(TARGET)' from all locations..."
	$(call trash-installed,$(INSTDIR)/$(TARGET_AS))
	$(call trash-installed,$(CHROMEDIR_AS)/$(TARGET_AS))
	$(call trash-installed,$(FIREFOXDIR)/$(TARGET_AS))
	$(call trash-installed,$(WEBKITDIR)/$(TARGET_AS))

clean:
	@echo "--->  Deleting '$(BUILD)' directory..."
	@$(RM) -v $(BUILD)
	@echo "--->  '$(BUILD)' directory deletion complete"

test:
	@echo "--->  ** Running Log Page tests..."
	$(PROVE) -v ./t/[0-9][0-9][0-9][0-9]-*.sh :: SKIP_INFO:true
	@echo "--->  Deleting temporary test files in '$(TEST_TMP)'..."
	@$(RM) $(TEST_TMP)

test-quiet:
	@echo "--->  ** Running Log Page tests..."
	$(PROVE) ./t/[0-9][0-9][0-9][0-9]-*.sh :: SKIP_INFO:true
	@echo "--->  Deleting temporary test files in '$(TEST_TMP)'..."
	@$(RM) $(TEST_TMP)

check: test

check-quiet: test-quiet

help:
	@echo "$$HELPTEXT"

.PHONY: all test test-quiet check check-quiet clean install uninstall help \
        install-safari install-chrome install-firefox install-webkit


# ==== FUNCTIONS =============================================================

define trash-installed
	@echo "--->  Deleting installed script: '$1'"
	@osascript                                  \
	-e "tell application \"Finder\""            \
	-e "	if exists (POSIX file \"$1\") then" \
	-e "		delete (POSIX file \"$1\")"     \
	-e "	end if"                             \
	-e "end tell" >/dev/null
endef

define make-alias
	@echo "--->  Making alias to '$1/$2' at '$3'"
	@osascript                                                            \
	-e "tell application \"Finder\""                                      \
	-e '	make new alias file to POSIX file "$1/$2" at POSIX file "$3"' \
	-e "end tell" >/dev/null
endef

define strip-debug
	$(SED) -e '/^[[:space:]]*\(my \)\{0,1\}debug_log(/d' "$1"
endef

define insert-version
	$(call strip-debug,"$1") | $(SED) -e 's/@@VERSION@@/$(VERSION)/g'
endef


# ==== DEPENDENCIES ==========================================================

$(PROG): $(SOURCE)
	@[ -d $(BUILD) ] || {                            \
		echo "--->  Creating directory '$(BUILD)'..."; \
		$(MKDIR) $(INSTDIRMODE) $(BUILD);                     \
	}
	@if [ 0 = $$(grep -cm1 '@@VERSION@@' $<) ]; then                        \
		echo "--->  Stripping debug lines and compiling '$@' from '$<'..."; \
		$(call strip-debug,"$<") | $(OSACOMPILE) "$@";                      \
	else                                                                    \
		echo "--->  Stripping debug statements, inserting VERSION number";  \
		echo "--->  and compiling '$@' from '$<'...";                       \
		$(call insert-version,"$<") | $(OSACOMPILE) "$@";                   \
	fi


# ==== TEXT VARIABLES ========================================================

define HELPTEXT

Make Commands for Log Page
--------------------------

make
make all
    Compile the script to the build directory, performing
    any substitutions such as inserting the version number
    and stripping debug statements.

make install
    Install the compiled script for all supported web browsers
    (Safari, Firefox, Google Chrome, WebKit Nightly). Only one
    actual copy of the script is installed -- for Safari. Aliases
    are created to that script for the other browsers.

make install-safari
make install-chrome
make install-firefox
make install-webkit
    Install the compiled script for only a specific web browser.

make uninstall
    Uninstall the script from all web browsers.

make test
    Run tests using the 'prove' command. There are over a thousand tests
    and it can take over ten minutes to run them all. Most of the tests
    are for the user interface (GUI windows), but the resulting data is
    also checked.

make test-quiet
    Run tests quietly (without the verbose flag to 'prove').

make clean
    Delete all build files.

make help
    Display this help.

endef
export HELPTEXT

