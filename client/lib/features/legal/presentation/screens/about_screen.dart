import 'package:flutter/material.dart';
import '../../../../core/constants/si_strings.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(SiStrings.aboutTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          SiStrings.aboutBody,
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
      ),
    );
  }
}
