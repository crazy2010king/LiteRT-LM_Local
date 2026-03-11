#!/bin/bash
# Run all tests

set -e

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

echo "=== Running all tests ==="
echo "Project root: $PROJECT_ROOT"
echo "CUDA available: $HAVE_CUDA"
echo ""

# Run Kotlin tests
"$(dirname "${BASH_SOURCE[0]}")/test_kotlin.sh"
echo ""

# Run C++ tests
"$(dirname "${BASH_SOURCE[0]}")/test_cpp.sh"
echo ""

# Run Python tests
"$(dirname "${BASH_SOURCE[0]}")/test_python.sh"
echo ""

# Final summary
echo "=== All Tests Completed ==="
echo -e "Total Passed: ${GREEN}$PASS${NC}"
echo -e "Total Failed: ${RED}$FAIL${NC}"
echo -e "Total Skipped: ${YELLOW}$SKIP${NC}"

if [ $FAIL -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed!${NC}"
    exit 1
fi
