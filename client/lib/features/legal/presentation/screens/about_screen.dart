import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          'About this application.',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
      ),
    );
  }
}
