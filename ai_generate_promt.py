# This script uses the Google Gemini 2.5 API to analyze a text file and save the AI's response to a file.
# It requires the 'requests' library and 'python-dotenv', which can be installed with:
# pip install requests python-dotenv
#
# Usage: python image_analyzer.py <input_text_file_path> <output_file_path>
#
# Remember to create a .env file in the same directory with your API key:
# GEMINI_API_KEY="your_api_key_here"

import os
import sys
import requests

# Load the API key from an environment variable.
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

# Your prompt for the AI model.
# Edit this string to change the AI's instructions.
PROMPT = "Read Jenkins console output file and provide a detailed analysis of its" \
" content. Write your analysis in a clear and structured manner. Focus on errors and problems, and find solution to them."

def generate_text(input_path, prompt):
    """
    Sends a text file and a prompt to the Gemini 2.5 API for text generation.
    Returns the AI's text response.
    """
    # 1. Check for the API key.
    if not GEMINI_API_KEY:
        print("GEMINI_API_KEY environment variable not set in the .env file.")
        sys.exit(1)

    # 2. Read the input text file.
    try:
        with open(input_path, "r", encoding="utf-8") as input_file:
            input_text = input_file.read()
    except FileNotFoundError:
        print(f"Error: The input file '{input_path}' was not found.")
        sys.exit(1)

    # 3. Construct the API request payload.
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent?key={GEMINI_API_KEY}"
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
        }
    }

    # 4. Make the API call.
    try:
        response = requests.post(url, json=payload)
        response.raise_for_status()  # Raise an exception for bad status codes
        
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
    # 1. Check for correct command-line arguments.
    if len(sys.argv) != 3:
        print("Usage: python image_analyzer.py <input_text_file_path> <output_file_path>")
        sys.exit(1)

    input_file_path = sys.argv[1]
    output_file_path = sys.argv[2]
    
    # 2. Call the AI model and get the response.
    print("Sending text to Gemini 2.5 for analysis...")
    ai_result = generate_text(input_file_path, PROMPT)
    print("Analysis complete. Writing result to file...")
    
    # 3. Write the response to the output file.
    with open(output_file_path, "w", encoding="utf-8") as output_file:
        output_file.write(ai_result)
    
    print(f"Successfully wrote the AI's analysis to '{output_file_path}'.")

# Run the script
if __name__ == "__main__":
    main()
