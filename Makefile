# node modules in executable path
PATH := node_modules/.bin:$(PATH)

# OSX requires this variable exported so that PATH is also exported.
SHELL := /bin/bash

# directories used throught targets
lib_dir             := lib
common_dir          := common
test_dir            := test
public_dir          := public
component_source_dir:= $(common_dir)/components
component_lib_dir   := $(lib_dir)/components
component_test_dir  := $(test_dir)/component

# Get a list by searching for files in given directories
component_source_files := $(shell find $(component_source_dir)/ -type f -name '*.js')

# Get a list by changing the directory of files
component_lib_files := $(component_source_files:$(component_source_dir)/%.js=$(component_lib_dir)/%.js)

# Get all the js files for linting
js_source_files := $(shell find {browser,common,server,lib/components}/ \
	-not \( -path common/components -prune \) \
	-type f -name '*.js')

browser_entry_file := $(shell node -pe 'require("./package.json")["main-browser"]')
server_entry_file := $(shell node -pe 'require("./package.json")["main-server"]')


# These targets don't produce any output
.PHONY: lint test test-components

# first / default target to perform all other targets
all: lint build test

# Other targets rely on this directory being created
libdir:
	@mkdir -p $(component_lib_dir)

# Process the jsx files
components: libdir $(component_lib_dir)
	@jsx $(component_source_dir) $(component_lib_dir)
	@echo "Components Built"

watch-components: components
	@jsx --watch $(component_lib_dir) $(component_source_dir)

watch-css:
	@echo "watch-css rule"

watch-build:
	@./scripts/parallel.sh "make watch-components" "make watch-css"

# Lint the found .js files with eslint
lint: $(js_source_files)
	@eslint $(js_source_files)
	@echo "Source Linted"

$(public_dir)/js/bundle.js: bundle

bundle:
	@browserify $(browser_entry_file) -d > $(public_dir)/js/bundle.js
	@echo "Browser Bundle Built"

test-components: components
	@mocha --recursive $(component_test_dir)

test: test-components

# Clean up after all other targets / start fresh
clean:
	@rm -rf lib
