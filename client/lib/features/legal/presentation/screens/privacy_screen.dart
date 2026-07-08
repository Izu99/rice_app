import 'package:flutter/material.dart';
import '../../../../core/constants/si_strings.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(SiStrings.privacyTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          SiStrings.privacyBody,
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
      ),
    );
  }
}
