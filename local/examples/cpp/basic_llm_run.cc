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
#include "c/engine.h"

void print_usage() {
    std::cout << "Usage: basic_llm_run --model_path=<path_to_model> [--backend=cpu|gpu]" << std::endl;
    std::cout << "Example: basic_llm_run --model_path=/path/to/model.tflite --backend=gpu" << std::endl;
}

int main(int argc, char** argv) {
    std::string model_path;
    std::string backend = "cpu";

    // Parse command line arguments
    for (int i = 1; i < argc; i++) {
        if (strncmp(argv[i], "--model_path=", 13) == 0) {
            model_path = argv[i] + 13;
        } else if (strncmp(argv[i], "--backend=", 10) == 0) {
            backend = argv[i] + 10;
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

    // Set log level to INFO
    litert_lm_set_min_log_level(0);

    // Create engine settings
    LiteRtLmEngineSettings* settings = litert_lm_engine_settings_create(
        model_path.c_str(), backend.c_str(), nullptr, nullptr);

    if (!settings) {
        std::cerr << "Failed to create engine settings" << std::endl;
        return 1;
    }

    // Set max tokens
    litert_lm_engine_settings_set_max_num_tokens(settings, 2048);

    // Create engine
    LiteRtLmEngine* engine = litert_lm_engine_create(settings);
    if (!engine) {
        std::cerr << "Failed to create engine with model: " << model_path << std::endl;
        litert_lm_engine_settings_delete(settings);
        return 1;
    }

    // Create session with default config
    LiteRtLmSession* session = litert_lm_engine_create_session(engine, nullptr);
    if (!session) {
        std::cerr << "Failed to create session" << std::endl;
        litert_lm_engine_delete(engine);
        litert_lm_engine_settings_delete(settings);
        return 1;
    }

    std::cout << "=== LiteRT-LM Basic LLM Run Example ===" << std::endl;
    std::cout << "Model: " << model_path << std::endl;
    std::cout << "Backend: " << backend << std::endl;
    std::cout << "Enter your prompt (type 'exit' to quit):" << std::endl;

    std::string prompt;
    while (true) {
        std::cout << "\n> ";
        std::getline(std::cin, prompt);

        if (prompt == "exit") {
            break;
        }

        if (prompt.empty()) {
            continue;
        }

        // Prepare input data
        InputData input;
        input.type = kInputText;
        input.data = prompt.c_str();
        input.size = prompt.size();

        // Generate response
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

        // Get and print the first response
        const char* response_text = litert_lm_responses_get_response_text_at(responses, 0);
        if (response_text) {
            std::cout << "\nResponse: " << response_text << std::endl;
        } else {
            std::cerr << "Failed to get response text" << std::endl;
        }

        litert_lm_responses_delete(responses);
    }

    // Cleanup
    litert_lm_session_delete(session);
    litert_lm_engine_delete(engine);
    litert_lm_engine_settings_delete(settings);

    std::cout << "\nExiting..." << std::endl;
    return 0;
}
