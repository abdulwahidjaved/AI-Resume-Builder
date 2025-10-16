import 'package:ai_rb/widgets/loading_screen_widget.dart';
import 'package:ai_rb/widgets/upload_resume_widget.dart';
import 'package:flutter/material.dart';

class Intro extends StatefulWidget {
  const Intro({super.key});

  @override
  State<Intro> createState() => IntroState();
}

class IntroState extends State<Intro> {
  bool isSubmitted = false;

  void handleUpload() {
    setState(() {
      isSubmitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background content
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Upload Your\nResume",
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Upload resume widget
                  UploadResumeWidget(onUpload: () {  },),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (isSubmitted)
            Positioned.fill(
              child: LoadingScreenWidget(),
            ),
        ],
      ),
    );
  }
}
