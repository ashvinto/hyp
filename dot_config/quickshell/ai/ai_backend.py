import sys
import os
import json
import urllib.request

# Simple OpenAI-compatible client using standard library (no pip install needed for basic usage)
def chat(prompt, api_key, model="gpt-3.5-turbo"):
    url = "https://api.openai.com/v1/chat/completions"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}"
    }
    data = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}]
    }
    
    try:
        req = urllib.request.Request(url, json.dumps(data).encode(), headers)
        with urllib.request.urlopen(req) as response:
            res_body = response.read()
            res_json = json.loads(res_body)
            content = res_json['choices'][0]['message']['content']
            # Print response for QML to capture
            print(json.dumps({"status": "success", "content": content}), flush=True)
    except Exception as e:
        print(json.dumps({"status": "error", "content": str(e)}), flush=True)

if __name__ == "__main__":
    # Read input from arguments
    if len(sys.argv) < 3:
        print(json.dumps({"status": "error", "content": "Missing args"}), flush=True)
        sys.exit(1)
        
    api_key = sys.argv[1]
    prompt = sys.argv[2]
    chat(prompt, api_key)
