import 'dart:io';
import 'dart:convert';

void main() async {
  final url = Uri.parse('https://pftjlvtdzokbzuioqfug.supabase.co/rest/v1/');
  final apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDg0NjgsImV4cCI6MjA5NDE4NDQ2OH0.3ujKn2bxihvFfhfeIXPVNDjxjfqpWsXJq4bpaPNsQOM';

  final client = HttpClient();
  try {
    final request = await client.getUrl(url);
    request.headers.set('apikey', apiKey);
    request.headers.set('Authorization', 'Bearer $apiKey');

    final response = await request.close();
    if (response.statusCode != 200) {
      print('HTTP error: ${response.statusCode}');
      return;
    }

    final responseBody = await response.transform(utf8.decoder).join();
    final data = json.decode(responseBody) as Map<String, dynamic>;

    final dbInfo = <String, dynamic>{};
    if (data.containsKey('definitions')) {
      final definitions = data['definitions'] as Map<String, dynamic>;
      definitions.forEach((tableName, definition) {
        final defMap = definition as Map<String, dynamic>;
        final properties = defMap['properties'] as Map<String, dynamic>? ?? {};
        final requiredFields = defMap['required'] as List<dynamic>? ?? [];
        dbInfo[tableName] = {
          'properties': properties.keys.toList(),
          'required': requiredFields,
        };
      });
    }

    final outputPath = r'C:\Users\IRAQ SOFT\.gemini\antigravity-ide\brain\902d27e9-fc34-4416-9228-5125357f2bed\scratch\schema_result.json';
    final file = File(outputPath);
    await file.writeAsString(JsonEncoder.withIndent('  ').convert(dbInfo));
    print('Success! Schema written to schema_result.json');
  } catch (e) {
    print('Error fetching schema: $e');
  } finally {
    client.close();
  }
}
