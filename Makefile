# Makefile for CleanMyMac

.PHONY: all build clean install run help

help:
	@echo "Available targets:"
	@echo "  make build    - Build the app (using Swift script)"
	@echo "  make clean    - Clean build directory"
	@echo "  make install  - Build and copy app to current directory"
	@echo "  make run      - Build and run the app"
	@echo "  make help     - Show this help message"
	@echo ""
	@echo "You can also use:"
	@echo "  swift Build.swift [command]"
	@echo "  ./build.sh [command]"

all: build

build:
	@swift Build.swift build

clean:
	@swift Build.swift clean

install: build
	@swift Build.swift install

run: build
	@swift Build.swift run

