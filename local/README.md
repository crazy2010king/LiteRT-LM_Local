# LiteRT-LM 示例程序

本目录包含 LiteRT-LM 完整的示例程序、文档和测试脚本。

## 目录结构

```
local/
├── README.md                    # 本说明文件
├── docs/
│   └── examples_guide.md        # 详细的示例使用指南（含架构图、API说明、常见问题）
├── examples/
│   ├── kotlin/                  # Kotlin 示例（复用项目原有代码）
│   ├── cpp/                     # C++ 示例实现
│   │   ├── basic_llm_run.cc     # 基础 LLM 运行示例
│   │   ├── advanced_llm_run.cc  # 高级 LLM 运行示例（支持流式输出、多轮对话、工具调用）
│   │   └── BUILD                # Bazel 构建配置
│   └── python/                  # Python 工具（复用项目原有代码）
├── test/                        # 自动化测试脚本
│   ├── common.sh                # 通用工具函数
│   ├── test_kotlin.sh           # Kotlin 示例测试
│   ├── test_cpp.sh              # C++ 示例测试
│   ├── test_python.sh           # Python 工具测试
│   └── test_all.sh              # 全量测试入口
└── run_examples.sh              # 统一调度脚本（支持交互式菜单和命令行参数）
```

## 快速开始

### 1. 交互式运行（推荐）
```bash
cd local
./run_examples.sh
```

### 2. 一键运行所有测试
```bash
cd local
./run_examples.sh --test
```

### 3. 编译所有示例
```bash
cd local
./run_examples.sh --build
```

### 4. 运行指定示例
```bash
# 运行 C++ 高级示例
./run_examples.sh --run=cpp_advanced

# 运行 Python 模型转换工具
./run_examples.sh --run=python_builder
```

## 硬件适配性

| 硬件平台 | 支持状态 | 推荐后端 | 典型性能 (7B模型 q4_0) |
|---------|----------|----------|------------------------|
| Intel x86_64 CPU | ✅ 完全支持 | CPU | 15-25 tokens/s |
| NVIDIA GPU (CUDA >=12.0) | ✅ 完全支持 | GPU | 50-100 tokens/s |
| ARM64 Android | ✅ 完全支持 | NPU/GPU | 10-30 tokens/s |
| ARM64 Linux | ✅ 完全支持 | CPU/GPU | 8-20 tokens/s |

## 详细文档

请查看 [docs/examples_guide.md](docs/examples_guide.md) 获取完整的使用说明、API 参考和常见问题解答。
