import 'dart:convert';
import 'package:http/http.dart' as http;

/// Dev helper — pass key via env, never hardcode:
///   set YOUTUBE_API_KEY=your_key
///   dart run bin/test_api.dart
void main() async {
  final apiKey = String.fromEnvironment('YOUTUBE_API_KEY', defaultValue: '');
  if (apiKey.isEmpty) {
    print('Set YOUTUBE_API_KEY via --define or environment. Aborting.');
    return;
  }

  final channelId = 'UCv0j01aAHX9HkHPtRMxPlHg';
  final maxResults = 50;

  final uri = Uri.parse(
    'https://www.googleapis.com/youtube/v3/search'
    '?key=$apiKey'
    '&channelId=$channelId'
    '&part=snippet'
    '&type=video'
    '&order=date'
    '&maxResults=$maxResults',
  );

  final response = await http.get(uri);
  print('Status code: ${response.statusCode}');
  print('Body: ${response.body}');
}
