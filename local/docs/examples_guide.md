# LiteRT-LM 示例程序使用指南

## 一、项目架构
LiteRT-LM 是一个轻量级、高性能的端侧大语言模型推理框架，支持 CPU/GPU 双后端，提供 Kotlin/Python/C++ 多语言 API。

```mermaid
graph TD
    A[模型文件(.tflite)] --> B[模型转换器(Python)]
    B --> C[优化后LiteRT模型]
    C --> D[推理引擎]
    D --> E[Kotlin API]
    D --> F[C++ API]
    D --> G[Python API]
    E --> H[Android/桌面端应用]
    F --> I[嵌入式/高性能应用]
    G --> J[工具链/调试工具]
```

## 二、环境配置
### 2.1 系统要求
- CPU: x86_64 (支持AVX2) / ARM64
- GPU: NVIDIA (CUDA >= 12.0) / Mali / Adreno
- 内存: 最低8GB，推荐16GB+
- 显存: 最低4GB，推荐8GB+

### 2.2 依赖安装
```bash
# Ubuntu 22.04
sudo apt install build-essential cmake openjdk-17-jdk python3-pip
pip3 install tensorflow numpy pillow

# CUDA支持（可选）
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
```

## 三、示例程序说明

### 3.1 Kotlin 示例
#### 3.1.1 基础对话示例
**功能**: 实现最基础的大语言模型单轮/多轮对话功能
**核心特性**:
- 支持 CPU/GPU 后端自动切换
- 支持上下文记忆
- 支持流式输出
- 温度、top_p、max_tokens 等参数可调

**使用方法**:
```bash
cd kotlin
./gradlew run --args="--model_path=/path/to/model.tflite --backend=gpu"
```

**核心代码解析**:
```kotlin
// 初始化引擎
val engine = LiteRtLmEngine.create(modelPath, EngineConfig(backend = Backend.GPU))

// 多轮对话
val chatHistory = mutableListOf<ChatMessage>()
chatHistory.add(ChatMessage(role = "user", content = "你好"))
val response = engine.generate(chatHistory, GenerateConfig(maxTokens = 1024))
println(response.content)
```

#### 3.1.2 工具调用示例
**功能**: 实现大语言模型工具调用能力，支持自定义工具函数
**支持工具**:
- 计算器
- 天气查询
- 代码执行
- 知识库检索

#### 3.1.3 性能基准测试
**功能**: 测试模型在当前硬件平台的推理性能
**输出指标**:
- 首Token延迟
- 平均Token生成速度 (tokens/s)
- 内存/显存占用
- CPU/GPU利用率

### 3.2 Python 工具
#### 3.2.1 模型打包工具
**功能**: 将原始 Huggingface 格式模型转换为 LiteRT-LM 支持的格式
**使用方法**:
```bash
python3 litertlm_builder_cli.py \
  --model_path=/path/to/hf_model \
  --output_path=/path/to/output.tflite \
  --quantization=q4_0 \
  --backend=cuda
```

#### 3.2.2 模型文件查看器
**功能**: 查看 LiteRT 模型文件的元信息、结构、参数配置
**使用方法**:
```bash
python3 litertlm_peek_main.py --model_path=/path/to/model.tflite
```

### 3.3 C++ 示例
#### 3.3.1 基础LLM运行示例
**功能**: 基于 C API 实现的极简 LLM 推理示例，适合嵌入式场景
**编译运行**:
```bash
cd local/examples/cpp
bazel build :basic_llm_run
./bazel-bin/basic_llm_run --model_path=/path/to/model.tflite
```

#### 3.3.2 高级LLM运行示例
**功能**: 完整功能的 C++ 推理示例，支持：
- 多轮对话上下文
- 工具调用
- 自定义停止词
- 流式输出回调
- 高级参数配置

## 四、编译指南
### 4.1 Kotlin 示例编译
```bash
cd kotlin
./gradlew assembleRelease
```

### 4.2 C++ 示例编译
```bash
bazel build //local/examples/cpp:all --config=cuda  # 带GPU支持
# 或
bazel build //local/examples/cpp:all  # 仅CPU支持
```

## 五、快速开始
### 5.1 一键运行所有示例
```bash
cd local
./run_examples.sh --all
```

### 5.2 交互式运行
```bash
cd local
./run_examples.sh
```

### 5.3 单独运行特定示例
```bash
# 运行C++基础示例
./run_examples.sh --run=cpp_basic

# 运行Kotlin性能测试
./run_examples.sh --run=kotlin_benchmark

# 运行Python模型转换工具
./run_examples.sh --run=python_builder
```

## 六、常见问题
### Q1: 运行时提示"CUDA_ERROR_OUT_OF_MEMORY"
A: 尝试使用更小的模型，或者降低批次大小，或者切换到CPU后端

### Q2: 模型转换失败
A: 确保原始模型是 Huggingface 格式，且依赖版本匹配，查看日志确认具体错误

### Q3: 推理速度慢
A: 确认是否启用了GPU后端，尝试使用量化程度更高的模型（如q4_0）

## 七、硬件适配性分析
| 硬件平台 | 支持状态 | 推荐后端 | 典型性能 (7B模型 q4_0) |
|---------|----------|----------|------------------------|
| Intel x86_64 CPU | ✅ 完全支持 | CPU | 15-25 tokens/s |
| NVIDIA GPU (CUDA >=12.0) | ✅ 完全支持 | GPU | 50-100 tokens/s |
| ARM64 Android | ✅ 完全支持 | NPU/GPU | 10-30 tokens/s |
| ARM64 Linux | ✅ 完全支持 | CPU/GPU | 8-20 tokens/s |
| Apple Silicon | 🔄 开发中 | ANE | - |
