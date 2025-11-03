import os
import sys
import json
import time
import argparse
from typing import Dict, Optional

try:
    import ollama
    import requests
except ImportError:
    print("Ollama or requests library not found. Please run 'pip install ollama requests'.", file=sys.stderr)
    sys.exit(1)

# --- CONFIGURATION ---
OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "http://192.168.1.107:11434")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "llama3")
MAX_RETRIES = 5

def generate_content(prompt: str) -> Optional[str]:
    """Calls the Ollama API to generate text content using exponential backoff."""
    client = ollama.Client(host=OLLAMA_HOST)

    messages = [
        {
            'role': 'system', 
            'content': """You are an expert C++ unit test developer. Generate ONLY valid C++ Google Test code.
Follow these rules:
1. Include necessary headers
2. Each test must be a separate TEST macro
3. No nested tests
4. Proper opening and closing braces
5. No markdown formatting or explanations"""
        },
        {
            'role': 'user', 
            'content': prompt
        }
    ]
    
    for i in range(MAX_RETRIES):
        try:
            response = client.chat(
                model=OLLAMA_MODEL,
                messages=messages,
                options={
                    "temperature": 0.1,
                    "num_ctx": 4096
                }
            )
            
            if response and 'message' in response:
                # Clean up the response
                generated_code = response['message']['content']
                # Remove any markdown code blocks if present
                generated_code = generated_code.replace('```cpp', '').replace('```', '').strip()
                return generated_code
            return None
            
        except requests.exceptions.ConnectionError:
            sleep_time = 2 ** i
            print(f"Ollama connection error. Retrying in {sleep_time} seconds...", file=sys.stderr)
            if i + 1 == MAX_RETRIES:
                print("Failed to connect to Ollama after multiple retries.", file=sys.stderr)
                return None
            time.sleep(sleep_time)
            
        except Exception as e:
            print(f"Error during Ollama API call: {e}", file=sys.stderr)
            return None
            
    return None

def write_to_file(file_path: str, content: str):
    """Writes the generated content to a file."""
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Content written to {file_path}")
    except IOError as e:
        print(f"Error writing to file {file_path}: {e}", file=sys.stderr)
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Generate C++ test cases using Ollama.")
    parser.add_argument('--prompt-file', required=True, help='File containing the prompt')
    parser.add_argument('--output-file', required=True, help='File to write the generated test code')
    parser.add_argument('--requirements-file', help='Optional requirements file', default=None)
    
    args = parser.parse_args()
    
    try:
        with open(args.prompt_file, 'r', encoding='utf-8') as f:
            prompt = f.read()
            
        # Optionally read requirements if provided
        if args.requirements_file and os.path.exists(args.requirements_file):
            with open(args.requirements_file, 'r', encoding='utf-8') as f:
                requirements = f.read()
                prompt = f"{prompt}\n\nRequirements:\n{requirements}"
    except FileNotFoundError as e:
        print(f"Error: File not found: {e.filename}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error reading files: {e}", file=sys.stderr)
        sys.exit(1)

    generated_code = generate_content(prompt)
    
    if generated_code:
        if '#include "number_to_string.h"' not in generated_code:
            generated_code = '#include "number_to_string.h"\n#include "gtest/gtest.h"\n\n' + generated_code
        write_to_file(args.output_file, generated_code)
    else:
        error_msg = "// Error: Failed to generate test code\n"
        write_to_file(args.output_file, error_msg)
        sys.exit(1)

if __name__ == '__main__':
    main()