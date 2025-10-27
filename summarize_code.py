import os
import sys
import argparse
# Removed: from google import genai
# Added: Ollama client library
try:
    import ollama
except ImportError:
    print("Ollama library not found. Please run 'pip install ollama'.", file=sys.stderr)
    sys.exit(1)

# --- CONFIGURATION (Customize these) ---
OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "http://localhost:11434")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "llama3")  # Choose a model you have pulled in Ollama (e.g., mistral, llama3)
# ----------------------------------------

def generate_summary(input_file, output_file):
    """Reads code from input_file, summarizes it using Ollama, and writes to output_file."""
    
    # MODIFIED: Removed the GEMINI_API_KEY check, as Ollama runs locally.
    
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            code_content = f.read()
    except Exception as e:
        print(f"Error reading input file: {e}", file=sys.stderr)
        sys.exit(1)

    # --- Ollama API Call ---
    try:
        # Initialize the Ollama Client
        client = ollama.Client(host=OLLAMA_HOST)
        
        # System prompt guides the model's behavior
        system_prompt = ("You are an expert code analyst. Provide a concise, high-level summary (max 100 words) "
                         "of the main class, functions, and data structures defined in the provided C++ code. "
                         "Focus on purpose and external interface, not implementation details.")
                         
        # User message contains the code
        user_prompt = f"--- CODE ---\n{code_content}\n--- END CODE ---"

        # MODIFIED: Use Ollama's chat interface (best practice for instruction-following models)
        response = client.chat(
            model=OLLAMA_MODEL,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            options={
                "temperature": 0.1, # Keep summarization deterministic
                "num_ctx": 4096     # Ensure context window is large enough for code
            }
        )
        
        # Ollama's chat response contains the generated text in the 'message' dictionary
        summary_text = response['message']['content'].strip()
        
    except Exception as e:
        print(f"Error generating summary via Ollama: {e}", file=sys.stderr)
        # Fallback: return the original content if the API call fails
        summary_text = f"SUMMARY FAILED. ORIGINAL CODE INCLUDED:\n{code_content}"


    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(summary_text)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Code Summarization Tool")
    parser.add_argument('input_file', help='Path to the input source code file.')
    parser.add_argument('output_file', help='Path to the output summary file.')
    args = parser.parse_args()
    
    generate_summary(args.input_file, args.output_file)
    