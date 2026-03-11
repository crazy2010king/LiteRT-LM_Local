#!/bin/bash
# Test script for C++ examples

set -e

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

echo "=== Running C++ tests ==="

# Check if bazel exists
if ! command_exists bazel; then
    skip "Bazel not found, skipping C++ tests"
    print_summary
fi

# Change to project root
cd "$PROJECT_ROOT" || exit 1

# Test 1: Check if basic_llm_run can be built
info "Building basic_llm_run..."
if bazel build //local/examples/cpp:basic_llm_run >/dev/null 2>&1; then
    success "basic_llm_run build successful"
else
    fail "basic_llm_run build failed"
fi

# Test 2: Check if advanced_llm_run can be built
info "Building advanced_llm_run..."
if bazel build //local/examples/cpp:advanced_llm_run >/dev/null 2>&1; then
    success "advanced_llm_run build successful"
else
    fail "advanced_llm_run build failed"
fi

# Test 3: Check if build artifacts exist
info "Checking build artifacts..."
if file_exists "bazel-bin/local/examples/cpp/basic_llm_run"; then
    success "basic_llm_run binary exists"
else
    fail "basic_llm_run binary not found"
fi

if file_exists "bazel-bin/local/examples/cpp/advanced_llm_run"; then
    success "advanced_llm_run binary exists"
else
    fail "advanced_llm_run binary not found"
fi

# Print summary
print_summary
