# This script uses the Google Gemini 2.5 API to analyze a text file and save the AI's response to a file.
# It requires the 'requests' library, which can be installed with:
# pip install requests
#
# Usage: python3 ai_generate_promt.py <input_text_file_path> <output_file_path>

import os
import sys
import requests
import json

# Your prompt for the AI model.
# Edit this string to change the AI's instructions.
""" PROMPT = "Read Jenkins console output file and provide a detailed analysis of its" \
" content. Write your analysis in a clear and structured manner. In addition," \
" check coverage issues and write test case source code to improve code coverage" \
" in the same style as in test_number_to_string.cpp file." """

PROMPT = "Read Jenkins console output file and check coverage issues and write " \
" test case source code to output_file to improve code coverage" \
" in the same style as in test_number_to_string.cpp file."

def generate_text(input_path, prompt, gemini_api_key):
    """
    Sends a text file and a prompt to the Gemini 2.5 API for text generation.
    Returns the AI's text response.
    """
    if not gemini_api_key:
        print("Error: GEMINI_API_KEY environment variable not set.")
        sys.exit(1)

    # 2. Read the input text file.
    try:
        with open(input_path, "r", encoding="utf-8") as input_file:
            input_text = input_file.read()
    except FileNotFoundError:
        print(f"Error: The input file '{input_path}' was not found.")
        sys.exit(1)

    # 3. Construct the API request payload.
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent?key={gemini_api_key}"
    payload = {
        "contents": [
            {
                "parts": [
                    {"text": prompt + "\n\n" + input_text}
                ]
            }
        ],
        "generationConfig": {
            "responseMimeType": "text/plain"
        },
        "tools": [{"google_search": {}}]
    }

    # 4. Make the API call.
    try:
        response = requests.post(url, json=payload)
        response.raise_for_status()
        
        result = response.json()
        candidate = result.get('candidates', [{}])[0]
        text_response = candidate.get('content', {}).get('parts', [{}])[0].get('text', 'No response found.')
        
        return text_response
        
    except requests.exceptions.RequestException as e:
        print(f"API request failed: {e}")
        sys.exit(1)

def main():
    """
    Main function to handle command-line arguments and script execution.
    """
    if len(sys.argv) != 3:
        print("Usage: python3 ai_generate_promt.py <input_text_file_path> <output_file_path>")
        sys.exit(1)

    # Load the API key from an environment variable.
    gemini_api_key = os.getenv("GEMINI_API_KEY")

    input_file_path = sys.argv[1]
    output_file_path = sys.argv[2]
    
    print("Sending text to Gemini 2.5 for analysis...")
    ai_result = generate_text(input_file_path, PROMPT, gemini_api_key)
    print("Analysis complete. Writing result to file...")
    
    with open(output_file_path, "w", encoding="utf-8") as output_file:
        output_file.write(ai_result)
    
    print(f"Successfully wrote the AI's analysis to '{output_file_path}'.")

if __name__ == "__main__":
    main()
