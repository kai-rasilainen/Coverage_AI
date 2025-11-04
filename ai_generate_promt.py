import os
import sys
import time
import argparse
from typing import Optional

try:
    import ollama
    import requests
except ImportError:
    print("Ollama or requests library not found. Please run 'pip install ollama requests'.", file=sys.stderr)
    sys.exit(1)

# --- CONFIGURATION ---
OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "http://localhost:11434")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "llama3")
MAX_RETRIES = 5

def generate_content(prompt: str) -> Optional[str]:
    """Calls the Ollama API to generate text content using exponential backoff."""
    client = ollama.Client(host=OLLAMA_HOST)

    sys_msg = (
        "You are an expert C++ unit test developer. "
        "Return ONLY valid C++ GoogleTest code when asked for tests. "
        "Rules: 1) Include necessary headers, 2) Each test is a separate TEST macro, "
        "3) No nested TESTs, 4) Proper braces, 5) No markdown."
    )
    messages = [
        {"role": "system", "content": sys_msg},
        {"role": "user", "content": prompt},
    ]

    for i in range(MAX_RETRIES):
        try:
            resp = client.chat(
                model=OLLAMA_MODEL,
                messages=messages,
                options={"temperature": 0.1, "num_ctx": 4096},
            )
            if resp and 'message' in resp and 'content' in resp['message']:
                out = resp['message']['content']
                return out.replace('```cpp', '').replace('```', '').strip()
            return None
        except requests.exceptions.ConnectionError:
            backoff = 2 ** i
            print(f"Ollama connection error. Retrying in {backoff}s...", file=sys.stderr)
            time.sleep(backoff)
        except Exception as e:
            print(f"Error during Ollama API call: {e}", file=sys.stderr)
            return None
    return None

def write_to_file(path: str, content: str) -> None:
    """Writes the generated content to a file."""
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

def main():
    parser = argparse.ArgumentParser(description="Generate text or C++ tests via Ollama.")
    parser.add_argument("--prompt-file", required=True, help="File containing the prompt")
    parser.add_argument("--output-file", required=True, help="Output file for generated content")
    parser.add_argument("--requirements-file", help="Optional requirements to append to the prompt")
    args = parser.parse_args()

    try:
        with open(args.prompt_file, "r", encoding="utf-8") as f:
            prompt = f.read()
    except Exception as e:
        print(f"Failed to read prompt file: {e}", file=sys.stderr)
        sys.exit(1)

    if args.requirements_file and os.path.exists(args.requirements_file):
        try:
            with open(args.requirements_file, "r", encoding="utf-8") as f:
                reqs = f.read()
            prompt = f"{prompt}\n\nRequirements:\n{reqs}"
        except Exception as e:
            print(f"Warning: failed to read requirements file: {e}", file=sys.stderr)

    generated = generate_content(prompt)
    if not generated:
        write_to_file(args.output_file, "// Error: generation failed\n")
        sys.exit(1)

    # If generating tests, ensure headers exist
    if '#include "number_to_string.h"' not in generated and 'TEST(' in generated:
        generated = '#include "number_to_string.h"\n#include "gtest/gtest.h"\n\n' + generated

    write_to_file(args.output_file, generated)

if __name__ == "__main__":
    main()