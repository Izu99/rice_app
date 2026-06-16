import 'package:flutter/material.dart';

class DataDeletionScreen extends StatelessWidget {
  const DataDeletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Deletion')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          'Data deletion request instructions will appear here.',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
      ),
    );
  }
}
