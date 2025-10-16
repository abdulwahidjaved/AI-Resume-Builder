import 'dart:convert';
import 'dart:io' show File; // only used on mobile
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static const base = "http://192.168.1.7:8000/api"; // change for your setup

  // 🧾 Upload Resume (works for both Web and Mobile)
  static Future<Map<String, dynamic>> uploadResume({
    File? file,
    Uint8List? bytes,
    String? filename,
  }) async {
    final uri = Uri.parse("$base/upload_resume/");
    final request = http.MultipartRequest('POST', uri);

    if (kIsWeb) {
      // ✅ Web version
      if (bytes == null || filename == null) {
        throw Exception("Web upload requires bytes and filename");
      }
      request.files.add(http.MultipartFile.fromBytes(
        'pdf',
        bytes,
        filename: filename,
      ));
    } else {
      // ✅ Mobile/Desktop version
      if (file == null) throw Exception("File is required for mobile upload");
      final stream = http.ByteStream(file.openRead());
      final len = await file.length();
      final multipart =
          http.MultipartFile('pdf', stream, len, filename: basename(file.path));
      request.files.add(multipart);
    }

    final resp = await request.send();
    final body = await resp.stream.bytesToString();
    return json.decode(body) as Map<String, dynamic>;
  }

  // 🧠 Start interview
  static Future<Map<String, dynamic>> startInterview(String resumeId) async {
    final resp = await http.post(
      Uri.parse("$base/start_interview/"),
      body: json.encode({"resume_id": resumeId}),
      headers: {"Content-Type": "application/json"},
    );
    return json.decode(resp.body);
  }

  // 💬 Send answer
  static Future<Map<String, dynamic>> answer(
      String sessionId, String answer) async {
    final resp = await http.post(
      Uri.parse("$base/answer/"),
      body: json.encode({"session_id": sessionId, "answer": answer}),
      headers: {"Content-Type": "application/json"},
    );
    return json.decode(resp.body);
  }

  // 🏁 Finish interview
  static Future<Map<String, dynamic>> finish(String sessionId) async {
    final resp = await http.post(
      Uri.parse("$base/finish/"),
      body: json.encode({"session_id": sessionId}),
      headers: {"Content-Type": "application/json"},
    );
    return json.decode(resp.body);
  }
}
