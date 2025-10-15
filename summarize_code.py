import os
import sys
import argparse
from google import genai

def generate_summary(input_file, output_file):
    """Reads code from input_file, summarizes it using Gemini, and writes to output_file."""
    
    if not os.getenv("GEMINI_API_KEY"):
        print("Error: GEMINI_API_KEY environment variable is not set.", file=sys.stderr)
        sys.exit(1)
        
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            code_content = f.read()
    except Exception as e:
        print(f"Error reading input file: {e}", file=sys.stderr)
        sys.exit(1)

    # --- Gemini API Call ---
    client = genai.Client()
    
    # Use a concise, token-efficient model like gemini-2.5-flash for summarization
    summary_prompt = f"""
        Analyze the following C++ source code. Provide a concise, high-level summary (max 100 words)
        of the main class, function, and data structures defined. Focus on purpose and external interface, 
        not implementation details.

        --- CODE ---
        {code_content}
        --- END CODE ---
    """

    try:
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=summary_prompt,
        )
        summary_text = response.text.strip()
    except Exception as e:
        print(f"Error generating summary: {e}", file=sys.stderr)
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
    