import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

const String _base   = 'https://vitapulse-band.web.app';
const String _appKey = 'vp-a8f3c2e1d4b7';

class ApiService {
  static String? _token;
  static String? _username;
  static String? get token    => _token;
  static String? get username => _username;
  static void setToken(String t)    => _token    = t;
  static void setUsername(String u) => _username = u;
  static void clearToken() { _token = null; _username = null; }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-App-Key': _appKey,
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> register(String username, String password) async {
    final res = await http.post(Uri.parse('$_base/auth/register'), headers: _headers,
        body: jsonEncode({'username': username, 'password': password}));
    return _parse(res);
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(Uri.parse('$_base/auth/login'), headers: _headers,
        body: jsonEncode({'username': username, 'password': password}));
    return _parse(res);
  }

  // ── Symptom & Recommend ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>> symptomCheck(
      List<String> symptoms, Map<String, bool> followUpAnswers) async {
    final res = await http.post(Uri.parse('$_base/symptom-check'), headers: _headers,
        body: jsonEncode({'symptoms': symptoms, 'follow_up_answers': followUpAnswers}));
    return _parse(res);
  }

  static Future<Map<String, dynamic>> recommend(Map<String, dynamic> payload) async {
    final endpoint = _token != null ? '/recommend/save' : '/recommend';
    final res = await http.post(Uri.parse('$_base$endpoint'), headers: _headers,
        body: jsonEncode(payload));
    return _parse(res);
  }

  static Future<List<dynamic>> history({int limit = 10}) async {
    final res = await http.get(Uri.parse('$_base/history?limit=$limit'), headers: _headers);
    final data = _parse(res);
    if (data.containsKey('_list')) return data['_list'] as List;
    return [];
  }

  static Future<String> uploadReport(PlatformFile file) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_base/upload-report'))
      ..headers['X-App-Key'] = _appKey
      ..headers['Accept'] = 'application/json';
    if (_token != null) req.headers['Authorization'] = 'Bearer $_token';
    if (file.bytes == null) throw Exception('Could not read file bytes');
    req.files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    final body = jsonDecode(res.body);
    if (res.statusCode >= 400) throw Exception((body as Map)['detail'] ?? 'Upload failed');
    return (body as Map)['message'] ?? 'Report uploaded successfully';
  }

  // ── Content Hub ───────────────────────────────────────────────────────────

  static Future<List<dynamic>> getArticles({String? category, String? tag}) async {
    final params = <String, String>{};
    if (category != null) params['category'] = category;
    if (tag != null) params['tag'] = tag;
    final uri = Uri.parse('$_base/content/articles').replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers);
    return _parse(res)['_list'] as List? ?? [];
  }

  static Future<Map<String, dynamic>> getArticle(String id) async {
    final res = await http.get(Uri.parse('$_base/content/articles/$id'), headers: _headers);
    return _parse(res);
  }

  static Future<List<dynamic>> getVideos({String? category}) async {
    final params = category != null ? {'category': category} : <String, String>{};
    final uri = Uri.parse('$_base/content/videos').replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers);
    return _parse(res)['_list'] as List? ?? [];
  }

  static Future<Map<String, dynamic>> searchContent(String q) async {
    final res = await http.get(
        Uri.parse('$_base/content/search').replace(queryParameters: {'q': q}),
        headers: _headers);
    return _parse(res);
  }

  // ── Forum ─────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getForumPosts({String? category}) async {
    final params = category != null ? {'category': category} : <String, String>{};
    final uri = Uri.parse('$_base/forum/posts').replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers);
    return _parse(res)['_list'] as List? ?? [];
  }

  static Future<Map<String, dynamic>> createForumPost(
      String title, String body, String category) async {
    final res = await http.post(Uri.parse('$_base/forum/posts'), headers: _headers,
        body: jsonEncode({'title': title, 'body': body, 'category': category}));
    return _parse(res);
  }

  static Future<List<dynamic>> getForumReplies(int postId) async {
    final res = await http.get(Uri.parse('$_base/forum/posts/$postId/replies'), headers: _headers);
    return _parse(res)['_list'] as List? ?? [];
  }

  static Future<Map<String, dynamic>> createForumReply(int postId, String body) async {
    final res = await http.post(Uri.parse('$_base/forum/posts/$postId/replies'),
        headers: _headers, body: jsonEncode({'body': body}));
    return _parse(res);
  }

  // ── Gamification ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getGamification() async {
    final res = await http.get(Uri.parse('$_base/gamification'), headers: _headers);
    return _parse(res);
  }

  // ── Profile / Goals ───────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(Uri.parse('$_base/profile'), headers: _headers);
    return _parse(res);
  }

  static Future<Map<String, dynamic>> updateGoals(Map<String, dynamic> goals) async {
    final res = await http.put(Uri.parse('$_base/profile/goals'), headers: _headers,
        body: jsonEncode(goals));
    return _parse(res);
  }

  // ── Provider Locator ──────────────────────────────────────────────────────

  static Future<List<dynamic>> searchProviders(
      double lat, double lon, String type, {double radiusKm = 50}) async {
    final res = await http.post(Uri.parse('$_base/providers/search'), headers: _headers,
        body: jsonEncode({'latitude': lat, 'longitude': lon, 'type': type, 'radius_km': radiusKm}));
    return _parse(res)['_list'] as List? ?? [];
  }

  // ── Edge Notifications ────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> edgeNotify(Map<String, dynamic> payload) async {
    final res = await http.post(Uri.parse('$_base/edge/notify'), headers: _headers,
        body: jsonEncode(payload));
    return _parse(res);
  }

  // ── PDF Report ────────────────────────────────────────────────────────────

  static Future<List<int>> downloadReport({int limit = 5}) async {
    final res = await http.get(
        Uri.parse('$_base/report/pdf?limit=$limit'), headers: _headers);
    if (res.statusCode >= 400) {
      final body = jsonDecode(res.body);
      throw Exception((body as Map)['detail'] ?? 'Download failed');
    }
    return res.bodyBytes;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Map<String, dynamic> _parse(http.Response res) {
    final body = jsonDecode(res.body);
    if (body is List) return {'_list': body};
    if (res.statusCode >= 400) {
      throw Exception((body as Map)['detail'] ?? 'Request failed (${res.statusCode})');
    }
    return body as Map<String, dynamic>;
  }
}
