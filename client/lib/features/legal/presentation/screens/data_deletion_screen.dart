import 'package:flutter/material.dart';
import '../../../../core/constants/si_strings.dart';

class DataDeletionScreen extends StatelessWidget {
  const DataDeletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(SiStrings.dataDeletionTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          SiStrings.dataDeletionBody,
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
      ),
    );
  }
}
