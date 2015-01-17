##############################################################################
#
# Makefile for Log Page
#
# Website: http://jazzheaddesign.com/work/code/log-page/
# Author:  Steve Wheeler
#
##############################################################################

# **BEFORE** tagging release, update version number.
#
# Version used for distributions (when there is no git repo).
VERSION       = 0.0.0

SHELL         = /bin/sh

# Make will use the current date when inserting the release date into the
# generated compiled script and README file. To override with a specific
# date, pass a date on the command-line when calling make, i.e.,
# `make RELEASE_DATE=YYYY-MM-DD`
RELEASE_DATE := $(shell date "+%F")


# If run from a git repo, then override the version above with
# a version derived from git tags formatted as `v[0-9]*`.
ifneq (,$(wildcard .git))
VERSION := $(subst v,,$(shell git describe --match "v[0-9]*" --dirty --always))
# NOTE: Remove the `--always` option to exit if git can't find a tag
#       instead of falling back to an abbreviated commit hash.
endif

# Format:  full_month_name day, year
RELEASE_DATE_FULL := $(shell date -j -f "%F" "$(RELEASE_DATE)" "+%B %e, %Y" \
                     | tr -s ' ')

# File names
SOURCE        = log_page.applescript
BASENAME      = Log\ Page
PACKAGE       = log-page

# Locations
prefix        = $(HOME)/Library/Scripts/Applications
bindir       := $(prefix)/Safari
BUILD         = _build
DOC_DIR       = doc
TEST_TMP      = t/tmp

# Installation directories for alternate browsers
CHROMEDIR    := $(prefix)/Google\ Chrome
FIREFOXDIR   := $(prefix)/Firefox
WEBKITDIR    := $(prefix)/WebKit

# Output files
TARGET       := $(BASENAME).scpt
DOC_FILE     := $(BASENAME)\ README.rtfd
# Distribution archive file basename
ARCHIVE      := $(PACKAGE)-$(VERSION)

# Documentation source files (text files in concatenation order)
TEXT_FILES    = readme.md LICENSE
DOC_SRC      := $(patsubst %,$(DOC_DIR)/%,$(TEXT_FILES))
HTML_LAYOUT  := $(DOC_DIR)/layout.erb
# Temporary file
HTML_FILE    := $(DOC_DIR)/readme.html
# ed commands for tweaking RTF formatting
ED_COMMANDS  := $(DOC_DIR)/doc.ed.txt

# Output file paths
PROG         := $(BUILD)/$(TARGET)
DOC_TARGET   := $(BUILD)/$(DOC_FILE)

# For files or directories that have backslash-escaped spaces, make variables
# without the escapes to use for AppleScript (osascript)
TARGET_AS    := $(subst \,,$(TARGET))
CHROMEDIR_AS := $(subst \,,$(CHROMEDIR))

# Tools
RM            = rm -rf
ED            = ed -s
SED           = LANG=C sed
MKDIR         = mkdir -p
MARKDOWN      = kramdown
MARKDOWN_OPT := --no-auto-ids --entity-output :numeric --template $(HTML_LAYOUT)
ARCHIVE_CMD   = ditto -c -k --sequesterRsrc --keepParent
PROVE         = prove -f

# Set the type (-t) and creator (-c) codes when compiling just like
# AppleScript Editor does. The codes are useful for Spotlight searches.
# If the -t and -c options are omitted, no codes are set.
OSACOMPILE = osacompile -t osas -c ToyS -o

# Install tool and options
INSTALL      = install
INSTDIR     := $(bindir)
INSTOPTS     = -pSv     # Don't use -b option; backups show up in script menu
INSTMODE     = -m 0600
INSTDIRMODE  = -m 0700


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
	@echo "--->  Deleting build files..."
	@[ -d "$(BUILD)" ] && $(RM) $(BUILD) || true
	@[ -f "$(HTML_FILE)" ] && $(RM) $(HTML_FILE) || true
	@echo "--->  Deleting distribution files..."
	@[ -d "$(ARCHIVE)" ] && $(RM) $(ARCHIVE) || true
	@$(RM) $(PACKAGE)-*.zip 2>/dev/null || true
	@echo "--->  Deletion complete"

doc: $(DOC_TARGET)

dist: all doc
	@echo "--->  Making a release..."
	@[ -d "$(ARCHIVE)" ] && $(RM) $(ARCHIVE) || true
	@[ -f "$(ARCHIVE).zip" ] && $(RM) $(ARCHIVE).zip || true
	@$(MKDIR) $(ARCHIVE)
	@cp -a $(BUILD)/* $(ARCHIVE)
	@find $(ARCHIVE) -name .DS_Store -print0 | xargs -0 $(RM)
	@$(ARCHIVE_CMD) $(ARCHIVE) $(ARCHIVE).zip
	@$(RM) $(ARCHIVE)
	@echo "--->  Release distribution archive created"

test:
	@echo "--->  Running Log Page tests on source script..."
	$(PROVE) -v ./t/[0-9][0-9][0-9][0-9]-*.sh :: SKIP_INFO:true
	@echo "--->  Deleting temporary test files in '$(TEST_TMP)'..."
	@$(RM) $(TEST_TMP)

test-quiet:
	@echo "--->  Running Log Page tests on source script..."
	$(PROVE) ./t/[0-9][0-9][0-9][0-9]-*.sh :: SKIP_INFO:true
	@echo "--->  Deleting temporary test files in '$(TEST_TMP)'..."
	@$(RM) $(TEST_TMP)

test-compiled: all
	@echo "--->  Running Log Page tests on compiled script..."
	$(PROVE) -v ./t/[0-9][0-9][0-9][0-9]-*.sh :: SKIP_INFO:true TEST_COMPILED:true
	@echo "--->  Deleting temporary test files in '$(TEST_TMP)'..."
	@$(RM) $(TEST_TMP)

test-compiled-quiet: all
	@echo "--->  Running Log Page tests on compiled script..."
	$(PROVE) ./t/[0-9][0-9][0-9][0-9]-*.sh :: SKIP_INFO:true TEST_COMPILED:true
	@echo "--->  Deleting temporary test files in '$(TEST_TMP)'..."
	@$(RM) $(TEST_TMP)

check: test

check-quiet: test-quiet

check-compiled: test-compiled

check-compiled-quiet: test-compiled-quiet

help:
	@echo "$$HELPTEXT"

.PHONY: all install uninstall clean doc dist help \
        test test-quiet check check-quiet \
        install-safari install-chrome install-firefox install-webkit


# ==== DEPENDENCIES ==========================================================

$(PROG): $(SOURCE)
	@[ -d $(BUILD) ] || {                              \
		echo "--->  Creating directory '$(BUILD)'..."; \
		$(MKDIR) $(INSTDIRMODE) $(BUILD);              \
	}
	@if [ 0 = $$(grep -cm1 '@@VERSION@@' $<) ]; then                        \
		echo "--->  Stripping debug lines and compiling '$@' from '$<'..."; \
		$(call strip-debug,"$<") | $(OSACOMPILE) "$@";                      \
	else                                                                    \
		echo "--->  Stripping debug statements, inserting VERSION number,"; \
		echo "--->    and compiling '$@' from '$<'...";                     \
		$(call insert-version,"$<") | $(OSACOMPILE) "$@";                   \
	fi
	@touch -r "$<" "$@"

$(DOC_TARGET): $(HTML_FILE)
	@echo "--->  Generating RTFD file from HTML..."
	@[ -d $(DOC_TARGET) ] && $(RM) $(DOC_TARGET) || true
	@[ -d $(BUILD) ] || $(MKDIR) $(BUILD)
	@textutil -format html -convert rtfd -output "$@" $<
	@echo "--->  Removing temporary HTML file..."
	@$(RM) $<
	@echo "--->  Tweaking RTF documentation formatting with 'ed' commands..."
	@$(ED) $(DOC_TARGET)/TXT.rtf < $(ED_COMMANDS) >/dev/null 2>&1
	@touch -r "$(DOC_DIR)/readme.md" "$@"
	@touch -r "$(DOC_DIR)/readme.md" $(DOC_TARGET)/TXT.rtf

$(HTML_FILE): $(DOC_SRC)
	@echo "--->  Concatenating Markdown files and generating temp HTML file..."
	@if ! which $(MARKDOWN) >/dev/null; then \
		echo "Can't find '$(MARKDOWN)' in PATH, needed for Markdown to HTML."; \
		false; \
	fi
	@# Make substitutions (version, etc.) before passing to Markdown parser
	@cat $^ | $(SED) -e 's/@@VERSION@@/$(VERSION)/g' -e 's/ (c) / \&copy; /g' \
		-e 's/[[:<:]]\(20[0-9][0-9]\)-\(20[0-9][0-9]\)[[:>:]]/\1--\2/g' \
		-e 's/@@RELEASE_DATE@@/$(RELEASE_DATE_FULL)/g' \
		| $(MARKDOWN) $(MARKDOWN_OPT) > $@
	@# Center the images since textutil ignores CSS margin auto on p > img
	@printf "%s\n" H \
	    'g/^\(<p\)\(><img \)/s//\1 style="text-align:center"\2/' . w | \
	    $(ED) $@ >/dev/null 2>&1


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
	$(call strip-debug,"$1") | $(SED) -e 's/@@VERSION@@/$(VERSION)/g' \
		-e 's/@@RELEASE_DATE@@/$(RELEASE_DATE)/g'
endef


# ==== TEXT VARIABLES ========================================================

define HELPTEXT

Make Commands for Log Page
--------------------------

make
make all
    Compile the script to the build directory, performing any
    substitutions such as inserting the version number and stripping
    debug statements.

make install
    Install the compiled script for all supported web browsers (Safari,
    Firefox, Google Chrome, WebKit Nightly). Only one actual copy of the
    script is installed -- for Safari. Aliases are created to that
    script for the other browsers.

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

make test-compiled
    Test the compiled, final script instead of the source script which
    is tested by default.

make test-compiled-quiet
    Same as 'test-compiled' except without verbose output.

make doc
    Generate the RTFD documentation file for the distribution.

make dist
    Make a release distribution archive consisting of the compiled
    AppleScript program and the RTFD documentation file.

make clean
    Delete all build files and distribution files.

make help
    Display this help.

endef
export HELPTEXT

