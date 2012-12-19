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

prefix    = $(HOME)
# Installation directory
bindir   := $(prefix)/Library/Scripts/Applications/Safari

INSTALL      = install
INSTDIR     := $(bindir)
INSTOPTS     = -bpSv
INSTMODE     = -m 0600
INSTDIRMODE  = -m 0700

# ----------------------------------------------------------------------------

.PHONY: all clean install uninstall

# Default rule:
all: $(PROG)

install: all
	@echo "--->  Installing $(TARGET) into $(INSTDIR)..."
	@$(INSTALL) -dv $(INSTDIRMODE) $(INSTDIR) && \
	$(INSTALL) $(INSTOPTS) $(INSTMODE) $(PROG) $(INSTDIR)

uninstall:
	@echo "--->  Uninstalling $(TARGET) from $(INSTDIR)..."
	@if [ -f $(INSTDIR)/$(TARGET).old ]; then                 \
		echo "--->  Restoring previous version...";           \
		mv -vi $(INSTDIR)/$(TARGET).old $(INSTDIR)/$(TARGET); \
	elif [ ! -f $(INSTDIR)/$(TARGET) ]; then                  \
		echo "--->  No file to uninstall. Aborting...";       \
	else                                                      \
		srm -vi $(INSTDIR)/$(TARGET);                         \
	fi

clean:
	@srm -vsr $(BUILD)/*
	@echo "--->  Deleted all files from $(BUILD) directory"

# ----------------------------------------------------------------------------

$(PROG): $(SOURCE)
	@[ -d $(BUILD) ] || {                            \
		echo "--->  Creating directory $(BUILD)..."; \
		mkdir -pvm0700 $(BUILD);                     \
	}
	@if [ 0 = $$(grep -cm1 '@@VERSION@@' $<) ]; then                       \
		echo "--->  Compiling $@ from $<...";                              \
		$(OSACOMPILE) "$@" $<;                                             \
	else                                                                   \
		echo "--->  Inserting VERSION number and compiling $@ from $<..."; \
		sed -e 's/@@VERSION@@/$(VERSION)/g' $< | $(OSACOMPILE) "$@";       \
	fi

