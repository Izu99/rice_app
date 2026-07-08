import 'package:flutter/material.dart';
import '../../../../core/constants/si_strings.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(SiStrings.termsTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          SiStrings.termsBody,
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
      ),
    );
  }
}
