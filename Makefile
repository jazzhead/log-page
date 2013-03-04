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

OSACOMPILE = osacompile -o

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

# ----------------------------------------------------------------------------

.PHONY: all clean install uninstall \
        install-safari install-chrome install-firefox install-webkit

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

# ---- Default rule

all: $(PROG)

# ---- Default install

# The default install command installs the script for Safari and then makes
# aliases of the script for the other browsers

install: install-safari
	@echo "* The 'install' target installs the script for Safari and then"
	@echo "* creates aliases of the script for all the other browsers."
	@mkdir -pv $(INSTDIRMODE) $(CHROMEDIR) $(FIREFOXDIR) $(WEBKITDIR)
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
	@srm -vsr $(BUILD)/*
	@echo "--->  Deleted all files from '$(BUILD)' directory"

# ----------------------------------------------------------------------------


define strip-debug
	LANG=C sed -e '/^[[:space:]]*\(my \)\{0,1\}debug_log(/d' "$1"
endef

define insert-version
	$(call strip-debug,"$1") | LANG=C sed -e 's/@@VERSION@@/$(VERSION)/g'
endef


$(PROG): $(SOURCE)
	@[ -d $(BUILD) ] || {                            \
		echo "--->  Creating directory '$(BUILD)'..."; \
		mkdir -pvm0700 $(BUILD);                     \
	}
	@if [ 0 = $$(grep -cm1 '@@VERSION@@' $<) ]; then                        \
		echo "--->  Stripping debug lines and compiling '$@' from '$<'..."; \
		$(call strip-debug,"$<") | $(OSACOMPILE) "$@";                      \
	else                                                                    \
		echo "--->  Stripping debug statements, inserting VERSION number";  \
		echo "--->  and compiling '$@' from '$<'...";                       \
		$(call insert-version,"$<") | $(OSACOMPILE) "$@";                   \
	fi

