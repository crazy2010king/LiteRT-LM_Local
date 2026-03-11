#!/bin/bash
# Common functions for test scripts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASS=0
FAIL=0
SKIP=0

# Print info message
info() {
    echo -e "${YELLOW}[INFO] $*${NC}"
}

# Print success message
success() {
    echo -e "${GREEN}[PASS] $*${NC}"
    ((PASS++))
}

# Print failure message
fail() {
    echo -e "${RED}[FAIL] $*${NC}"
    ((FAIL++))
}

# Print skip message
skip() {
    echo -e "${YELLOW}[SKIP] $*${NC}"
    ((SKIP++))
}

# Print test summary
print_summary() {
    echo -e "\n=== Test Summary ==="
    echo -e "Passed: ${GREEN}$PASS${NC}"
    echo -e "Failed: ${RED}$FAIL${NC}"
    echo -e "Skipped: ${YELLOW}$SKIP${NC}"
    echo -e "Total: $((PASS + FAIL + SKIP))"

    if [ $FAIL -eq 0 ]; then
        echo -e "\n${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if file exists
file_exists() {
    [ -f "$1" ]
}

# Check if directory exists
dir_exists() {
    [ -d "$1" ]
}

# Get project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
export PROJECT_ROOT

# Detect CUDA availability
HAVE_CUDA=0
if command_exists nvidia-smi && nvidia-smi >/dev/null 2>&1; then
    HAVE_CUDA=1
fi
export HAVE_CUDA
