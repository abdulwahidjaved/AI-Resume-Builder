import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ai_rb/services/api_service.dart';
import 'package:ai_rb/screens/interview_screen.dart';

class UploadResumeWidget extends StatefulWidget {
  final VoidCallback onUpload;
  const UploadResumeWidget({super.key, required this.onUpload});

  @override
  State<UploadResumeWidget> createState() => _UploadResumeWidgetState();
}

class _UploadResumeWidgetState extends State<UploadResumeWidget> {
  bool loading = false;
  String? resumeId;

  Future<void> pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;

    setState(() => loading = true);

    try {
      Map<String, dynamic> resp;

      if (kIsWeb) {
        final bytes = result.files.single.bytes!;
        final filename = result.files.single.name;
        resp = await ApiService.uploadResume(bytes: bytes, filename: filename);
      } else {
        final file = File(result.files.single.path!);
        resp = await ApiService.uploadResume(file: file);
      }

      if (resp['status'] == 'success') {
        resumeId = resp['resume_id'];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InterviewScreen(resumeId: resumeId!),
          ),
        );
      } else {
        showError(resp['message'] ?? "Upload failed");
      }
    } catch (e) {
      showError(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: pickAndUpload,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueGrey, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : const Icon(Icons.upload, size: 60, color: Colors.blueGrey),
      ),
    );
  }
}
