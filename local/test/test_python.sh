#!/bin/bash
# Test script for Python tools

set -e

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

echo "=== Running Python tests ==="

# Check if python3 exists
if ! command_exists python3; then
    skip "Python 3 not found, skipping Python tests"
    print_summary
fi

# Test 1: Check if model builder exists
info "Checking model builder tool..."
if file_exists "$PROJECT_ROOT/schema/py/litertlm_builder_cli.py"; then
    success "litertlm_builder_cli.py exists"
else
    fail "litertlm_builder_cli.py not found"
fi

# Test 2: Check if model peek tool exists
info "Checking model peek tool..."
if file_exists "$PROJECT_ROOT/schema/py/litertlm_peek_main.py"; then
    success "litertlm_peek_main.py exists"
else
    fail "litertlm_peek_main.py not found"
fi

# Test 3: Check if Python scripts can be imported without errors
info "Testing Python imports..."
if python3 -c "import sys; sys.path.insert(0, '$PROJECT_ROOT/schema/py'); import litertlm_builder_cli" >/dev/null 2>&1; then
    success "litertlm_builder_cli import successful"
else
    fail "litertlm_builder_cli import failed"
fi

if python3 -c "import sys; sys.path.insert(0, '$PROJECT_ROOT/schema/py'); import litertlm_peek_main" >/dev/null 2>&1; then
    success "litertlm_peek_main import successful"
else
    fail "litertlm_peek_main import failed"
fi

# Test 4: Check script help output
info "Testing script help output..."
if python3 "$PROJECT_ROOT/schema/py/litertlm_builder_cli.py" --help >/dev/null 2>&1; then
    success "litertlm_builder_cli --help works"
else
    fail "litertlm_builder_cli --help failed"
fi

if python3 "$PROJECT_ROOT/schema/py/litertlm_peek_main.py" --help >/dev/null 2>&1; then
    success "litertlm_peek_main --help works"
else
    fail "litertlm_peek_main --help failed"
fi

# Print summary
print_summary
