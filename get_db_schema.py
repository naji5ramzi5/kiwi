import urllib.request
import json

url = 'https://pftjlvtdzokbzuioqfug.supabase.co/rest/v1/'
apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDg0NjgsImV4cCI6MjA5NDE4NDQ2OH0.3ujKn2bxihvFfhfeIXPVNDjxjfqpWsXJq4bpaPNsQOM'

headers = {
    'apikey': apiKey,
    'Authorization': f'Bearer {apiKey}'
}

req = urllib.request.Request(url, headers=headers)

try:
    with urllib.request.urlopen(req) as response:
        html = response.read()
        data = json.loads(html.decode('utf-8'))
        
        db_info = {}
        if 'definitions' in data:
            for table_name, definition in data['definitions'].items():
                db_info[table_name] = {
                    'properties': list(definition.get('properties', {}).keys()),
                    'required': definition.get('required', [])
                }
        
        output_path = r'C:\Users\IRAQ SOFT\.gemini\antigravity-ide\brain\902d27e9-fc34-4416-9228-5125357f2bed\scratch\schema_result.json'
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(db_info, f, ensure_ascii=False, indent=2)
        print("Success! Schema written to schema_result.json")
except Exception as e:
    print(f"Error fetching schema: {e}")
