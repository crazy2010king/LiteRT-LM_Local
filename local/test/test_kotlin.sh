#!/bin/bash
# Test script for Kotlin examples

set -e

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

echo "=== Running Kotlin tests ==="

# Check if gradle exists
if ! command_exists ./gradlew; then
    skip "Gradle wrapper not found, skipping Kotlin tests"
    print_summary
fi

# Change to kotlin directory
cd "$PROJECT_ROOT/kotlin" || exit 1

# Test 1: Check if build is possible
info "Testing Kotlin build..."
if ./gradlew compileKotlin --no-daemon >/dev/null 2>&1; then
    success "Kotlin build successful"
else
    fail "Kotlin build failed"
fi

# Test 2: Check if Main class exists
info "Checking Main class..."
if file_exists "java/com/google/ai/edge/litertlm/example/Main.kt"; then
    success "Main.kt exists"
else
    fail "Main.kt not found"
fi

# Test 3: Check if example app can be built
info "Testing example app build..."
if ./gradlew :example:assembleDebug --no-daemon >/dev/null 2>&1; then
    success "Example app build successful"
else
    fail "Example app build failed"
fi

# Print summary
print_summary
