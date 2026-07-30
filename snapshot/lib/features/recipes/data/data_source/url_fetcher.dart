import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class UrlFetcher {
  static final _log = Logger('UrlFetcher');
  static const _timeout = Duration(seconds: 15);
  static const _maxChars = 10000;

  static Future<String> fetch(String url) async {
    _log.fine('Fetching URL: $url');

    final response = await http.get(Uri.parse(url)).timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch URL ($url): ${response.statusCode}');
    }

    var html = response.body;

    // Strip script and style tags
    html = html.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '');
    html = html.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '');

    // Strip HTML tags to get text content (but preserve some structure)
    html = html.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    html = html.replaceAll(RegExp(r'</(p|div|li|h[1-6])>'), '\n');
    html = html.replaceAll(RegExp(r'<[^>]+>'), ' ');

    // Collapse whitespace
    html = html.replaceAll(RegExp(r'[ \t]+'), ' ');
    html = html.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    html = html.trim();

    // Truncate
    if (html.length > _maxChars) {
      html = html.substring(0, _maxChars);
    }

    _log.fine('Fetched and cleaned: ${html.length} chars');
    return html;
  }
}
