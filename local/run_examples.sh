#!/bin/bash
# Unified script to run all LiteRT-LM examples

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
LOCAL_DIR="$PROJECT_ROOT/local"

# Detect environment
HAVE_CUDA=0
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
    HAVE_CUDA=1
fi

HAVE_BAZEL=0
if command -v bazel >/dev/null 2>&1; then
    HAVE_BAZEL=1
fi

HAVE_GRADLE=0
if [ -f "$PROJECT_ROOT/kotlin/gradlew" ]; then
    HAVE_GRADLE=1
fi

# Print header
print_header() {
    clear
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${BLUE}    LiteRT-LM Examples Runner        ${NC}"
    echo -e "${BLUE}=====================================${NC}"
    echo ""
    echo "Environment:"
    echo "  - CUDA: $(if [ $HAVE_CUDA -eq 1 ]; then echo "${GREEN}Available${NC}"; else echo "${YELLOW}Not available${NC}"; fi)"
    echo "  - Bazel: $(if [ $HAVE_BAZEL -eq 1 ]; then echo "${GREEN}Installed${NC}"; else echo "${YELLOW}Not installed${NC}"; fi)"
    echo "  - Gradle: $(if [ $HAVE_GRADLE -eq 1 ]; then echo "${GREEN}Available${NC}"; else echo "${YELLOW}Not available${NC}"; fi)"
    echo ""
}

# Print help
print_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  --all               Run all examples sequentially"
    echo "  --run=<example>     Run specific example:"
    echo "                        cpp_basic       - C++ basic LLM run"
    echo "                        cpp_advanced    - C++ advanced LLM run"
    echo "                        kotlin_basic    - Kotlin basic example"
    echo "                        kotlin_benchmark - Kotlin performance benchmark"
    echo "                        python_builder  - Python model builder tool"
    echo "                        python_peek     - Python model peek tool"
    echo "  --test              Run all test scripts"
    echo "  --build             Build all examples"
    echo ""
    echo "Interactive mode:"
    echo "  Run without arguments to use interactive menu"
    echo ""
}

# Build all examples
build_all() {
    echo -e "${YELLOW}Building all examples...${NC}"
    echo ""

    # Build C++ examples
    if [ $HAVE_BAZEL -eq 1 ]; then
        echo "Building C++ examples..."
        cd "$PROJECT_ROOT"
        if [ $HAVE_CUDA -eq 1 ]; then
            bazel build //local/examples/cpp:all --config=cuda
        else
            bazel build //local/examples/cpp:all
        fi
        echo -e "${GREEN}C++ examples built successfully${NC}"
    else
        echo -e "${YELLOW}Bazel not available, skipping C++ build${NC}"
    fi

    # Build Kotlin examples
    if [ $HAVE_GRADLE -eq 1 ]; then
        echo "Building Kotlin examples..."
        cd "$PROJECT_ROOT/kotlin"
        ./gradlew assembleDebug --no-daemon
        echo -e "${GREEN}Kotlin examples built successfully${NC}"
    else
        echo -e "${YELLOW}Gradle not available, skipping Kotlin build${NC}"
    fi

    echo ""
    echo -e "${GREEN}Build completed!${NC}"
}

# Run tests
run_tests() {
    echo -e "${YELLOW}Running all tests...${NC}"
    echo ""
    "$LOCAL_DIR/test/test_all.sh"
}

# Run C++ basic example
run_cpp_basic() {
    if [ $HAVE_BAZEL -eq 0 ]; then
        echo -e "${RED}Error: Bazel is required to run C++ examples${NC}"
        return 1
    fi

    echo -e "${YELLOW}Running C++ basic LLM example...${NC}"
    echo ""
    echo "Note: You need to provide a valid model path when prompted."
    echo ""

    local backend="cpu"
    if [ $HAVE_CUDA -eq 1 ]; then
        read -p "Use GPU backend? (y/n, default: y): " use_gpu
        if [ "$use_gpu" != "n" ]; then
            backend="gpu"
        fi
    fi

    read -p "Enter path to LiteRT model file: " model_path
    if [ ! -f "$model_path" ]; then
        echo -e "${RED}Error: Model file not found: $model_path${NC}"
        return 1
    fi

    cd "$PROJECT_ROOT"
    bazel run //local/examples/cpp:basic_llm_run -- --model_path="$model_path" --backend="$backend"
}

# Run C++ advanced example
run_cpp_advanced() {
    if [ $HAVE_BAZEL -eq 0 ]; then
        echo -e "${RED}Error: Bazel is required to run C++ examples${NC}"
        return 1
    fi

    echo -e "${YELLOW}Running C++ advanced LLM example...${NC}"
    echo ""
    echo "Note: You need to provide a valid model path when prompted."
    echo ""

    local backend="cpu"
    if [ $HAVE_CUDA -eq 1 ]; then
        read -p "Use GPU backend? (y/n, default: y): " use_gpu
        if [ "$use_gpu" != "n" ]; then
            backend="gpu"
        fi
    fi

    read -p "Enter path to LiteRT model file: " model_path
    if [ ! -f "$model_path" ]; then
        echo -e "${RED}Error: Model file not found: $model_path${NC}"
        return 1
    fi

    read -p "Enable streaming output? (y/n, default: y): " use_stream
    local stream_flag=""
    if [ "$use_stream" != "n" ]; then
        stream_flag="--stream"
    fi

    read -p "Enable multi-turn conversation? (y/n, default: y): " use_multi_turn
    local multi_turn_flag=""
    if [ "$use_multi_turn" != "n" ]; then
        multi_turn_flag="--multi_turn"
    fi

    read -p "Max output tokens (default: 1024): " max_tokens
    max_tokens=${max_tokens:-1024}

    read -p "Temperature (default: 0.7): " temperature
    temperature=${temperature:-0.7}

    cd "$PROJECT_ROOT"
    bazel run //local/examples/cpp:advanced_llm_run -- \
        --model_path="$model_path" \
        --backend="$backend" \
        $stream_flag \
        $multi_turn_flag \
        --max_tokens="$max_tokens" \
        --temperature="$temperature"
}

# Run Kotlin basic example
run_kotlin_basic() {
    if [ $HAVE_GRADLE -eq 0 ]; then
        echo -e "${RED}Error: Gradle is required to run Kotlin examples${NC}"
        return 1
    fi

    echo -e "${YELLOW}Running Kotlin basic example...${NC}"
    echo ""

    local backend="cpu"
    if [ $HAVE_CUDA -eq 1 ]; then
        read -p "Use GPU backend? (y/n, default: y): " use_gpu
        if [ "$use_gpu" != "n" ]; then
            backend="gpu"
        fi
    fi

    read -p "Enter path to LiteRT model file: " model_path
    if [ ! -f "$model_path" ]; then
        echo -e "${RED}Error: Model file not found: $model_path${NC}"
        return 1
    fi

    cd "$PROJECT_ROOT/kotlin"
    ./gradlew run --args="--model_path=$model_path --backend=$backend" --no-daemon
}

# Run Kotlin benchmark
run_kotlin_benchmark() {
    if [ $HAVE_GRADLE -eq 0 ]; then
        echo -e "${RED}Error: Gradle is required to run Kotlin examples${NC}"
        return 1
    fi

    echo -e "${YELLOW}Running Kotlin performance benchmark...${NC}"
    echo ""

    local backend="cpu"
    if [ $HAVE_CUDA -eq 1 ]; then
        read -p "Use GPU backend? (y/n, default: y): " use_gpu
        if [ "$use_gpu" != "n" ]; then
            backend="gpu"
        fi
    fi

    read -p "Enter path to LiteRT model file: " model_path
    if [ ! -f "$model_path" ]; then
        echo -e "${RED}Error: Model file not found: $model_path${NC}"
        return 1
    fi

    cd "$PROJECT_ROOT/kotlin"
    ./gradlew run --args="--model_path=$model_path --backend=$backend --benchmark" --no-daemon
}

# Run Python model builder
run_python_builder() {
    echo -e "${YELLOW}Running Python model builder tool...${NC}"
    echo ""
    python3 "$PROJECT_ROOT/schema/py/litertlm_builder_cli.py" --help
    echo ""
    echo "Example usage:"
    echo "  python3 $PROJECT_ROOT/schema/py/litertlm_builder_cli.py \\"
    echo "    --model_path=/path/to/huggingface/model \\"
    echo "    --output_path=model.tflite \\"
    echo "    --quantization=q4_0"
}

# Run Python model peek
run_python_peek() {
    echo -e "${YELLOW}Running Python model peek tool...${NC}"
    echo ""
    read -p "Enter path to LiteRT model file: " model_path
    if [ ! -f "$model_path" ]; then
        echo -e "${RED}Error: Model file not found: $model_path${NC}"
        return 1
    fi

    python3 "$PROJECT_ROOT/schema/py/litertlm_peek_main.py" --model_path="$model_path"
}

# Run all examples
run_all() {
    echo -e "${YELLOW}Running all examples...${NC}"
    echo ""

    echo "=== C++ Basic Example ==="
    run_cpp_basic
    echo ""

    echo "=== C++ Advanced Example ==="
    run_cpp_advanced
    echo ""

    echo "=== Kotlin Basic Example ==="
    run_kotlin_basic
    echo ""

    echo "=== Kotlin Benchmark ==="
    run_kotlin_benchmark
    echo ""

    echo "=== Python Builder Tool ==="
    run_python_builder
    echo ""

    echo "=== Python Peek Tool ==="
    run_python_peek
    echo ""

    echo -e "${GREEN}All examples completed!${NC}"
}

# Interactive menu
show_menu() {
    while true; do
        print_header
        echo "Please select an option:"
        echo ""
        echo "  1. 🚀 Run all examples"
        echo "  2. 🔨 Build all examples"
        echo "  3. 🧪 Run all tests"
        echo "  4. 💻 Run C++ basic example"
        echo "  5. ⚡ Run C++ advanced example"
        echo "  6. 🤖 Run Kotlin basic example"
        echo "  7. ⏱️  Run Kotlin performance benchmark"
        echo "  8. 📦 Run Python model builder tool"
        echo "  9. 🔍 Run Python model peek tool"
        echo " 10. 📖 Open documentation"
        echo "  0. ❌ Exit"
        echo ""
        read -p "Enter your choice [0-10]: " choice

        case $choice in
            1)
                run_all
                read -p "Press enter to continue..."
                ;;
            2)
                build_all
                read -p "Press enter to continue..."
                ;;
            3)
                run_tests
                read -p "Press enter to continue..."
                ;;
            4)
                run_cpp_basic
                read -p "Press enter to continue..."
                ;;
            5)
                run_cpp_advanced
                read -p "Press enter to continue..."
                ;;
            6)
                run_kotlin_basic
                read -p "Press enter to continue..."
                ;;
            7)
                run_kotlin_benchmark
                read -p "Press enter to continue..."
                ;;
            8)
                run_python_builder
                read -p "Press enter to continue..."
                ;;
            9)
                run_python_peek
                read -p "Press enter to continue..."
                ;;
            10)
                echo "Opening documentation..."
                if command -v xdg-open >/dev/null 2>&1; then
                    xdg-open "$LOCAL_DIR/docs/examples_guide.md"
                elif command -v open >/dev/null 2>&1; then
                    open "$LOCAL_DIR/docs/examples_guide.md"
                else
                    echo "Documentation is at: $LOCAL_DIR/docs/examples_guide.md"
                fi
                read -p "Press enter to continue..."
                ;;
            0)
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice, please try again${NC}"
                sleep 1
                ;;
        esac
    done
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    # Interactive mode
    show_menu
else
    # Command line mode
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                print_help
                exit 0
                ;;
            --all)
                run_all
                shift
                ;;
            --run=*)
                example="${1#*=}"
                case "$example" in
                    cpp_basic) run_cpp_basic ;;
                    cpp_advanced) run_cpp_advanced ;;
                    kotlin_basic) run_kotlin_basic ;;
                    kotlin_benchmark) run_kotlin_benchmark ;;
                    python_builder) run_python_builder ;;
                    python_peek) run_python_peek ;;
                    *) echo -e "${RED}Error: Unknown example: $example${NC}"; exit 1 ;;
                esac
                shift
                ;;
            --test)
                run_tests
                shift
                ;;
            --build)
                build_all
                shift
                ;;
            *)
                echo -e "${RED}Error: Unknown option: $1${NC}"
                print_help
                exit 1
                ;;
        esac
    done
fi
