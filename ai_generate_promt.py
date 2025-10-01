import os
import sys
import json
import base64
import time
import requests

def get_gemini_api_key():
    """Retrieves the Gemini API key from environment variables."""
    return os.environ.get('GEMINI_API_KEY', '')

def generate_content(prompt, api_key):
    """Calls the Gemini API to generate text content."""
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent?key={api_key}"
    headers = {
        'Content-Type': 'application/json',
    }
    payload = {
        'contents': [
            {
                'parts': [
                    {'text': prompt}
                ]
            }
        ]
    }
    
    # Use exponential backoff to handle potential rate-limiting.
    for i in range(5):
        try:
            response = requests.post(url, headers=headers, data=json.dumps(payload))
            response.raise_for_status() # Raise an exception for bad status codes
            return response.json()
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 429: # Too Many Requests
                sleep_time = 2 ** i # Exponential backoff
                print(f"Rate limit exceeded. Retrying in {sleep_time} seconds...")
                time.sleep(sleep_time)
            else:
                print(f"HTTP Error: {e.response.status_code} - {e.response.text}")
                return None
        except Exception as e:
            print(f"An unexpected error occurred: {e}")
            return None
    return None

def write_to_file(file_path, content):
    """Writes the generated content to a file."""
    try:
        with open(file_path, 'w') as f:
            f.write(content)
        print(f"Content successfully written to {file_path}")
    except IOError as e:
        print(f"Error writing to file {file_path}: {e}")

if __name__ == '__main__':
    # Assume the arguments are passed as: prompt_base64, context_file, output_file
    if len(sys.argv) < 4:
        print("Usage: ai_generate_promt.py <prompt_base64> <context_file> <output_file>")
        sys.exit(1)

    # Decode the Base64 prompt argument
    prompt_base64 = sys.argv[1]
    try:
        decoded_bytes = base64.b64decode(prompt_base64)
        prompt = decoded_bytes.decode('utf-8')
    except Exception as e:
        # Handle the error if decoding fails (e.g., if a wrong argument is passed)
        print(f"Error decoding prompt: {e}")
        sys.exit(1)

    log_path = sys.argv[2]
    output_path = sys.argv[3]
    api_key = get_gemini_api_key()

    if not api_key:
        print("API key not found. Please set the GEMINI_API_KEY environment variable.")
        sys.exit(1)

    # Note: The prompt itself contains the necessary context.
    # The log_path and other parameters are not currently used in this version.
    # If the AI needs context from the log, the prompt must be constructed to include it.

    # Call the AI to generate content based on the prompt
    response_data = generate_content(prompt, api_key)

    if response_data and 'candidates' in response_data and len(response_data['candidates']) > 0:
        generated_text = response_data['candidates'][0]['content']['parts'][0]['text']
        write_to_file(output_path, generated_text)
    else:
        print("Failed to get a valid response from the Gemini API.")

