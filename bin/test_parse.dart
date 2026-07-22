import 'dart:convert';
import 'package:http/http.dart' as http;
import '../lib/models/app_models.dart';

/// Dev helper — never hardcode API keys:
///   dart run bin/test_parse.dart --define=YOUTUBE_API_KEY=your_key
void main() async {
  final apiKey = String.fromEnvironment('YOUTUBE_API_KEY', defaultValue: '');
  if (apiKey.isEmpty) {
    print('Set YOUTUBE_API_KEY via --define. Aborting.');
    return;
  }

  final channelId = 'UCv0j01aAHX9HkHPtRMxPlHg';
  final maxResults = 50;
  final hardLimit = 300;

  final List<VideoItem> allVideos = [];
  String? nextPageToken;

  try {
    do {
      final uri = Uri.parse(
        'https://www.googleapis.com/youtube/v3/search'
        '?key=$apiKey'
        '&channelId=$channelId'
        '&part=snippet'
        '&type=video'
        '&order=date'
        '&maxResults=$maxResults'
        '${nextPageToken != null ? '&pageToken=$nextPageToken' : ''}',
      );

      print('Fetching page... nextPageToken: $nextPageToken');
      final response = await http.get(uri);
      print('Status code: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Error body: ${response.body}');
        break;
      }

      final data = jsonDecode(response.body);
      final items = data['items'] as List? ?? [];
      print('Found ${items.length} items in this page.');

      allVideos.addAll(items.map((e) => VideoItem.fromJson(e)));

      nextPageToken = data['nextPageToken'] as String?;

      if (hardLimit > 0 && allVideos.length >= hardLimit) break;
    } while (nextPageToken != null);

    print('Total videos fetched: ${allVideos.length}');
  } catch (e, st) {
    print('Exception: $e\n$st');
  }
}
