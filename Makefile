SHELL := /bin/bash

SCHEME ?= Topliner
BUNDLE_ID ?= com.schoi80.topliner
SIMULATOR ?= iPhone 17 Pro
DERIVED_DATA ?= .build/Xcode
APP_PATH := $(DERIVED_DATA)/Build/Products/Debug-iphonesimulator/$(SCHEME).app

SANITIZED_ENV := env -i HOME="$(HOME)" USER="$(USER)" LOGNAME="$(LOGNAME)" TMPDIR="$(TMPDIR)" PATH="/usr/bin:/bin:/usr/sbin:/sbin:/Applications/Xcode.app/Contents/Developer/usr/bin:/opt/homebrew/bin"
XCODE_ENV := $(SANITIZED_ENV) DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

.PHONY: help check-tools status test generate build verify open boot-sim build-sim install-sim launch-sim run-sim clean smoke-doc

help: ## Show available make targets.
	@awk 'BEGIN {FS = ":.*##"; printf "Topliner tasks\n\n"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  %-14s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

check-tools: ## Confirm required tools are available.
	@command -v swift >/dev/null || { echo "swift not found"; exit 1; }
	@command -v xcodebuild >/dev/null || { echo "xcodebuild not found"; exit 1; }
	@command -v xcodegen >/dev/null || { echo "xcodegen not found; install with: brew install xcodegen"; exit 1; }
	@xcodebuild -version | sed -n '1,2p'
	@xcodegen --version

status: ## Show git branch/status and recent commits.
	@git status --short --branch
	@git log --oneline --decorate -5

test: ## Run the SwiftPM core test suite.
	swift test

generate: check-tools ## Regenerate Topliner.xcodeproj from project.yml.
	$(SANITIZED_ENV) xcodegen generate

build: generate ## Build the app with the generic iOS Simulator compile gate.
	$(XCODE_ENV) xcodebuild -scheme $(SCHEME) -destination 'generic/platform=iOS Simulator' -jobs 1 -quiet build

verify: test ## Run tests, diff hygiene, regenerate project, and compile the app.
	git diff --check
	$(SANITIZED_ENV) xcodegen generate >/dev/null
	$(XCODE_ENV) xcodebuild -scheme $(SCHEME) -destination 'generic/platform=iOS Simulator' -jobs 1 -quiet build

open: generate ## Open the generated Xcode project.
	open $(SCHEME).xcodeproj

boot-sim: ## Boot the configured simulator and open Simulator.app.
	xcrun simctl boot "$(SIMULATOR)" 2>/dev/null || true
	open -a Simulator

build-sim: generate ## Build the app for the configured simulator name.
	$(XCODE_ENV) xcodebuild -scheme $(SCHEME) -destination 'platform=iOS Simulator,name=$(SIMULATOR)' -derivedDataPath $(DERIVED_DATA) -jobs 1 -quiet build

install-sim: build-sim boot-sim ## Install the simulator build onto the booted simulator.
	xcrun simctl install booted "$(APP_PATH)"

launch-sim: ## Launch the app on the booted simulator.
	xcrun simctl launch booted $(BUNDLE_ID)

run-sim: install-sim launch-sim ## Build, install, and launch on the configured simulator.

clean: ## Remove SwiftPM and Xcode derived build artifacts.
	rm -rf .build $(DERIVED_DATA)

smoke-doc: ## Print the manual MVP smoke test checklist path.
	@echo "docs/testing/mvp-smoke-test.md"
