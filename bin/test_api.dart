import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final channelId = 'UCv0j01aAHX9HkHPtRMxPlHg';
  final apiKey = 'AIzaSyBa49iwUgJo_7yMy4emZi9TVLlePj_m-lw';
  final maxResults = 50;

  final uri = Uri.parse(
    'https://www.googleapis.com/youtube/v3/search'
    '?key=$apiKey'
    '&channelId=$channelId'
    '&part=snippet'
    '&type=video'
    '&order=date'
    '&maxResults=$maxResults'
  );

  final response = await http.get(uri);
  print('Status code: ${response.statusCode}');
  print('Body: ${response.body}');
}
