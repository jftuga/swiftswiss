BINARY_NAME = swiftswiss
VERSION := $(shell grep 'static let version' Sources/SwiftSwissLib/SwiftSwiss.swift | sed 's/.*"\(.*\)".*/\1/')
BUILD_DIR = .build
RELEASE_BIN = $(BUILD_DIR)/release/$(BINARY_NAME)
DEBUG_BIN = $(BUILD_DIR)/debug/$(BINARY_NAME)
INSTALL_DIR = /usr/local/bin
DIST_NAME = $(BINARY_NAME)-v$(VERSION)
DIST_DIR = $(DIST_NAME)
ARCHIVE = $(DIST_NAME).tar.xz

.PHONY: all build release test clean install uninstall user-install run dist help

all: build

build:
	swift build

release:
	swift build -c release

test:
	swift test

clean:
	swift package clean
	rm -rf $(BUILD_DIR)

install: release
	install -d $(INSTALL_DIR)
	install -m 755 $(RELEASE_BIN) $(INSTALL_DIR)/$(BINARY_NAME)
	@echo "Installed $(BINARY_NAME) to $(INSTALL_DIR)"

uninstall:
	rm -f $(INSTALL_DIR)/$(BINARY_NAME)
	@echo "Removed $(BINARY_NAME) from $(INSTALL_DIR)"

user-install: release
	cp -f $(RELEASE_BIN) $(HOME)/bin/$(BINARY_NAME)
	@echo "Installed $(BINARY_NAME) to $(HOME)/bin/"

run: build
	$(DEBUG_BIN)

dist: release
	rm -rf $(DIST_DIR) $(ARCHIVE)
	mkdir -p $(DIST_DIR)
	cp $(RELEASE_BIN) $(DIST_DIR)/
	cp README.md $(DIST_DIR)/
	tar cJvf $(ARCHIVE) $(DIST_DIR)
	rm -rf $(DIST_DIR)
	@echo ""
	@echo "Created $(ARCHIVE)"
	@ls -lh $(ARCHIVE)

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build         Build debug binary (default)"
	@echo "  release       Build optimized release binary"
	@echo "  test          Run all tests"
	@echo "  clean         Remove build artifacts"
	@echo "  install       Build release and install to $(INSTALL_DIR)"
	@echo "  uninstall     Remove from $(INSTALL_DIR)"
	@echo "  user-install  Build release and install to $(HOME)/bin/"
	@echo "  run           Build and run (shows usage)"
	@echo "  dist          Build release and create $(ARCHIVE)"
	@echo "  help          Show this help"
