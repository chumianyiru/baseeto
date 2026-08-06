import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static Future<String?> getReply({
    required String systemPrompt,
    required List<Map<String, String>> history,
    required String apiKey,
    String model = 'glm-4-flash',
    String baseUrl = 'https://open.bigmodel.cn/api/paas/v4/chat/completions',
  }) async {
    try {
      final messages = <Map<String, String>>[
        if (systemPrompt.isNotEmpty)
          {'role': 'system', 'content': systemPrompt},
        ...history,
      ];

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': 0.8,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
