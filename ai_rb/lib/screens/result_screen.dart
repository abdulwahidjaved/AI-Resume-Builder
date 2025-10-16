import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final String evaluation;
  final List qna;
  const ResultScreen({super.key, required this.evaluation, required this.qna});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interview Result')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Evaluation", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(evaluation),
            const SizedBox(height: 18),
            const Text("Transcript", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: qna.length,
                itemBuilder: (context, i) {
                  final item = qna[i];
                  return ListTile(title: Text(item['question'] ?? ""), subtitle: Text(item['answer'] ?? ""));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
