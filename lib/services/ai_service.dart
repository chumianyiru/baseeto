import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static const String _baseUrl = 'https://open.bigmodel.cn/api/paas/v4/chat/completions';

  static Future<String> chat({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) async {
    try {
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt},
        ...history,
      ];

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': 0.8,
          'max_tokens': 500,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content']?.trim() ?? '...';
      }
      return '(AI回复失败: ${response.statusCode})';
    } catch (e) {
      return '(网络错误，请检查网络连接)';
    }
  }
}
