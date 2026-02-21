import 'package:flutter/material.dart';

class DutyStatusScreen extends StatelessWidget {
  const DutyStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duty Status')),
      body: const Center(
        child: Text('Duty Status Screen'),
      ),
    );
  }
}
