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

  /// Upload a medical report file (PDF/image, max 5 MB).
  /// Returns a status message string from the server.
  static Future<String> uploadReport(PlatformFile file) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_base/upload-report'))
      ..headers['X-App-Key'] = _appKey
      ..headers['Accept'] = 'application/json';
    if (_token != null) req.headers['Authorization'] = 'Bearer $_token';

    req.files.add(http.MultipartFile.fromBytes(
      'file',
      file.bytes!,
      filename: file.name,
    ));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    final body = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw Exception((body as Map)['detail'] ?? 'Upload failed (${res.statusCode})');
    }
    return (body as Map)['message'] ?? 'Report uploaded successfully';
  }

  static Map<String, dynamic> _parse(http.Response res) {
    final body = jsonDecode(res.body);
    if (body is List) return {'_list': body};
    if (res.statusCode >= 400) {
      throw Exception((body as Map)['detail'] ?? 'Request failed (${res.statusCode})');
    }
    return body as Map<String, dynamic>;
  }
}
