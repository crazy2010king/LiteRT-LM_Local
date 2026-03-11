/*
 * Copyright 2025 The ODML Authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <iostream>
#include <string>
#include <cstring>
#include <mutex>
#include <condition_variable>
#include "c/engine.h"

// Stream callback data structure
struct StreamData {
    std::mutex mtx;
    std::condition_variable cv;
    bool done = false;
    std::string full_response;
};

// Streaming callback function
void stream_callback(void* callback_data, const char* chunk, bool is_final, const char* error_msg) {
    StreamData* data = static_cast<StreamData*>(callback_data);
    std::lock_guard<std::mutex> lock(data->mtx);

    if (error_msg) {
        std::cerr << "\nError: " << error_msg << std::endl;
        data->done = true;
        data->cv.notify_all();
        return;
    }

    if (chunk) {
        std::cout << chunk << std::flush;
        data->full_response += chunk;
    }

    if (is_final) {
        data->done = true;
        data->cv.notify_all();
    }
}

void print_usage() {
    std::cout << "Usage: advanced_llm_run --model_path=<path_to_model> [options]" << std::endl;
    std::cout << "Options:" << std::endl;
    std::cout << "  --model_path=<path>       Path to LiteRT model file (required)" << std::endl;
    std::cout << "  --backend=cpu|gpu         Backend to use (default: cpu)" << std::endl;
    std::cout << "  --max_tokens=<num>        Maximum output tokens (default: 1024)" << std::endl;
    std::cout << "  --temperature=<value>     Sampling temperature (default: 0.7)" << std::endl;
    std::cout << "  --top_p=<value>           Top-p sampling parameter (default: 0.9)" << std::endl;
    std::cout << "  --top_k=<num>             Top-k sampling parameter (default: 50)" << std::endl;
    std::cout << "  --stream                  Enable streaming output" << std::endl;
    std::cout << "  --multi_turn              Enable multi-turn conversation" << std::endl;
    std::cout << std::endl;
    std::cout << "Example:" << std::endl;
    std::cout << "  advanced_llm_run --model_path=model.tflite --backend=gpu --stream --multi_turn" << std::endl;
}

int main(int argc, char** argv) {
    std::string model_path;
    std::string backend = "cpu";
    int max_tokens = 1024;
    float temperature = 0.7f;
    float top_p = 0.9f;
    int top_k = 50;
    bool stream = false;
    bool multi_turn = false;

    // Parse command line arguments
    for (int i = 1; i < argc; i++) {
        if (strncmp(argv[i], "--model_path=", 13) == 0) {
            model_path = argv[i] + 13;
        } else if (strncmp(argv[i], "--backend=", 10) == 0) {
            backend = argv[i] + 10;
        } else if (strncmp(argv[i], "--max_tokens=", 13) == 0) {
            max_tokens = atoi(argv[i] + 13);
        } else if (strncmp(argv[i], "--temperature=", 14) == 0) {
            temperature = atof(argv[i] + 14);
        } else if (strncmp(argv[i], "--top_p=", 8) == 0) {
            top_p = atof(argv[i] + 8);
        } else if (strncmp(argv[i], "--top_k=", 8) == 0) {
            top_k = atoi(argv[i] + 8);
        } else if (strcmp(argv[i], "--stream") == 0) {
            stream = true;
        } else if (strcmp(argv[i], "--multi_turn") == 0) {
            multi_turn = true;
        } else {
            std::cerr << "Unknown argument: " << argv[i] << std::endl;
            print_usage();
            return 1;
        }
    }

    if (model_path.empty()) {
        std::cerr << "Error: model_path is required" << std::endl;
        print_usage();
        return 1;
    }

    // Set log level to WARNING
    litert_lm_set_min_log_level(1);

    // Create engine settings
    LiteRtLmEngineSettings* settings = litert_lm_engine_settings_create(
        model_path.c_str(), backend.c_str(), nullptr, nullptr);

    if (!settings) {
        std::cerr << "Failed to create engine settings" << std::endl;
        return 1;
    }

    // Set engine parameters
    litert_lm_engine_settings_set_max_num_tokens(settings, 4096);
    litert_lm_engine_settings_enable_benchmark(settings);

    // Create engine
    LiteRtLmEngine* engine = litert_lm_engine_create(settings);
    if (!engine) {
        std::cerr << "Failed to create engine with model: " << model_path << std::endl;
        litert_lm_engine_settings_delete(settings);
        return 1;
    }

    // Create session config
    LiteRtLmSessionConfig* session_config = litert_lm_session_config_create();
    litert_lm_session_config_set_max_output_tokens(session_config, max_tokens);

    // Set sampler parameters
    LiteRtLmSamplerParams sampler_params;
    sampler_params.type = kTopP;
    sampler_params.top_k = top_k;
    sampler_params.top_p = top_p;
    sampler_params.temperature = temperature;
    sampler_params.seed = 42;
    litert_lm_session_config_set_sampler_params(session_config, &sampler_params);

    // Create session
    LiteRtLmSession* session = litert_lm_engine_create_session(engine, session_config);
    if (!session) {
        std::cerr << "Failed to create session" << std::endl;
        litert_lm_session_config_delete(session_config);
        litert_lm_engine_delete(engine);
        litert_lm_engine_settings_delete(settings);
        return 1;
    }

    std::cout << "=== LiteRT-LM Advanced LLM Run Example ===" << std::endl;
    std::cout << "Model: " << model_path << std::endl;
    std::cout << "Backend: " << backend << std::endl;
    std::cout << "Streaming: " << (stream ? "Enabled" : "Disabled") << std::endl;
    std::cout << "Multi-turn: " << (multi_turn ? "Enabled" : "Disabled") << std::endl;
    std::cout << "Max tokens: " << max_tokens << std::endl;
    std::cout << "Temperature: " << temperature << std::endl;
    std::cout << "Top-p: " << top_p << std::endl;
    std::cout << "Top-k: " << top_k << std::endl;
    std::cout << "\nEnter your prompt (type 'exit' to quit, 'clear' to clear history):" << std::endl;

    std::string prompt;
    LiteRtLmConversation* conversation = nullptr;

    // Initialize conversation for multi-turn
    if (multi_turn) {
        // Default system message and no tools
        conversation = litert_lm_conversation_create(engine, nullptr);
        if (!conversation) {
            std::cerr << "Warning: Failed to create conversation, falling back to single-turn mode" << std::endl;
            multi_turn = false;
        }
    }

    while (true) {
        std::cout << "\n> ";
        std::getline(std::cin, prompt);

        if (prompt == "exit") {
            break;
        }

        if (prompt == "clear" && multi_turn) {
            // Reset conversation
            if (conversation) {
                litert_lm_conversation_delete(conversation);
                conversation = litert_lm_conversation_create(engine, nullptr);
            }
            std::cout << "Conversation history cleared" << std::endl;
            continue;
        }

        if (prompt.empty()) {
            continue;
        }

        std::cout << "\nResponse: ";
        std::cout.flush();

        if (multi_turn && conversation) {
            // Multi-turn conversation mode
            std::string message_json = R"({"role": "user", "content": ")" + prompt + R"("})";

            if (stream) {
                // Streaming mode
                StreamData stream_data;
                int ret = litert_lm_conversation_send_message_stream(
                    conversation, message_json.c_str(), stream_callback, &stream_data);

                if (ret != 0) {
                    std::cerr << "Failed to start streaming generation" << std::endl;
                    continue;
                }

                // Wait for completion
                std::unique_lock<std::mutex> lock(stream_data.mtx);
                stream_data.cv.wait(lock, [&stream_data] { return stream_data.done; });
            } else {
                // Non-streaming mode
                LiteRtLmJsonResponse* response = litert_lm_conversation_send_message(
                    conversation, message_json.c_str());

                if (!response) {
                    std::cerr << "Failed to generate response" << std::endl;
                    continue;
                }

                const char* response_str = litert_lm_json_response_get_string(response);
                if (response_str) {
                    std::cout << response_str << std::endl;
                } else {
                    std::cerr << "Failed to get response text" << std::endl;
                }

                litert_lm_json_response_delete(response);
            }
        } else {
            // Single-turn mode
            InputData input;
            input.type = kInputText;
            input.data = prompt.c_str();
            input.size = prompt.size();

            if (stream) {
                // Streaming mode
                StreamData stream_data;
                int ret = litert_lm_session_generate_content_stream(
                    session, &input, 1, stream_callback, &stream_data);

                if (ret != 0) {
                    std::cerr << "Failed to start streaming generation" << std::endl;
                    continue;
                }

                // Wait for completion
                std::unique_lock<std::mutex> lock(stream_data.mtx);
                stream_data.cv.wait(lock, [&stream_data] { return stream_data.done; });
            } else {
                // Non-streaming mode
                LiteRtLmResponses* responses = litert_lm_session_generate_content(
                    session, &input, 1);

                if (!responses) {
                    std::cerr << "Failed to generate response" << std::endl;
                    continue;
                }

                int num_candidates = litert_lm_responses_get_num_candidates(responses);
                if (num_candidates == 0) {
                    std::cerr << "No response generated" << std::endl;
                    litert_lm_responses_delete(responses);
                    continue;
                }

                const char* response_text = litert_lm_responses_get_response_text_at(responses, 0);
                if (response_text) {
                    std::cout << response_text << std::endl;
                } else {
                    std::cerr << "Failed to get response text" << std::endl;
                }

                litert_lm_responses_delete(responses);
            }
        }

        // Print benchmark info
        LiteRtLmBenchmarkInfo* benchmark_info = nullptr;
        if (multi_turn && conversation) {
            benchmark_info = litert_lm_conversation_get_benchmark_info(conversation);
        } else {
            benchmark_info = litert_lm_session_get_benchmark_info(session);
        }

        if (benchmark_info) {
            double ttft = litert_lm_benchmark_info_get_time_to_first_token(benchmark_info);
            int decode_turns = litert_lm_benchmark_info_get_num_decode_turns(benchmark_info);

            if (decode_turns > 0) {
                double decode_speed = litert_lm_benchmark_info_get_decode_tokens_per_sec_at(benchmark_info, decode_turns - 1);
                int decode_tokens = litert_lm_benchmark_info_get_decode_token_count_at(benchmark_info, decode_turns - 1);

                std::cout << "\n\n[Benchmark]" << std::endl;
                std::cout << "Time to first token: " << ttft << "s" << std::endl;
                std::cout << "Decode speed: " << decode_speed << " tokens/s" << std::endl;
                std::cout << "Generated tokens: " << decode_tokens << std::endl;
            }

            litert_lm_benchmark_info_delete(benchmark_info);
        }
    }

    // Cleanup
    if (conversation) {
        litert_lm_conversation_delete(conversation);
    }
    litert_lm_session_delete(session);
    litert_lm_session_config_delete(session_config);
    litert_lm_engine_delete(engine);
    litert_lm_engine_settings_delete(settings);

    std::cout << "\nExiting..." << std::endl;
    return 0;
}
