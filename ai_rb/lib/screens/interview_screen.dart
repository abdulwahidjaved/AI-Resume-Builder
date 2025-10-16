import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class InterviewScreen extends StatefulWidget {
  final String resumeId;
  const InterviewScreen({super.key, required this.resumeId});
  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  String? sessionId;
  String currentQuestion = "";
  final TextEditingController answerCtrl = TextEditingController();
  bool loading = false;
  List<Map<String,String>> qna = [];

  @override
  void initState() {
    super.initState();
    startInterview();
  }

  Future<void> startInterview() async {
    setState(() => loading = true);
    final resp = await ApiService.startInterview(widget.resumeId);
    setState(() => loading = false);
    if (resp['status'] == 'success') {
      sessionId = resp['session_id'];
      currentQuestion = resp['question'] ?? "";
    } else {
      showError(resp['message'] ?? "Error starting interview");
    }
  }

  void showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> sendAnswer() async {
    final answer = answerCtrl.text.trim();
    if (answer.isEmpty) return;
    if (answer.toLowerCase() == 'quit') {
      // finish & show result
      final res = await ApiService.finish(sessionId!);
      if (res['status'] == 'success') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResultScreen(evaluation: res['evaluation'], qna: List.from(res['qna']))));
      } else {
        showError(res['message'] ?? "Finish failed");
      }
      return;
    }

    // normal answer
    setState(() => loading = true);
    final resp = await ApiService.answer(sessionId!, answer);
    setState(() => loading = false);
    if (resp['status'] == 'success') {
      qna.add({"q": currentQuestion, "a": answer});
      // ack & next question
      final ack = resp['ack'] ?? "";
      final nextQ = resp['next_question'] ?? "";
      answerCtrl.clear();
      setState(() => currentQuestion = nextQ.isNotEmpty ? nextQ : "No further question — type 'quit' to finish.");
      // optional show ack
      showSnackBar(ack);
    } else {
      showError(resp['message'] ?? "Error");
    }
  }

  void showSnackBar(String text) {
    if (text.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Interview')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Question:", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(currentQuestion, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: answerCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Type your answer here... (or type quit)'),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    ElevatedButton(onPressed: sendAnswer, child: const Text("Send")),
                    const SizedBox(width: 12),
                    OutlinedButton(onPressed: () async {
                      // finish early
                      final res = await ApiService.finish(sessionId!);
                      if (res['status'] == 'success') {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResultScreen(evaluation: res['evaluation'], qna: List.from(res['qna']))));
                      } else showError(res['message'] ?? "Finish failed");
                    }, child: const Text("Finish"))
                  ]),
                  const SizedBox(height: 20),
                  const Text("Previous Q&A:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: qna.length,
                      itemBuilder: (context, i) {
                        final item = qna[i];
                        return ListTile(
                          title: Text(item['q'] ?? ""),
                          subtitle: Text(item['a'] ?? ""),
                        );
                      },
                    ),
                  )
                ],
              ),
      ),
    );
  }
}
