import 'package:flutter/material.dart';

void main() {
  runApp(const CyberLogApp());
}


class Log {
  final String action;
  final DateTime timestamp;
  final String status;

  Log(this.action, this.timestamp, this.status);

  String formatted() {
    return '$action at ${timestamp.toLocal()} (status: $status)';
  }
}

class CyberLogApp extends StatelessWidget {
  const CyberLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Log> logs = [
      Log('App started', DateTime.now().subtract(const Duration(minutes: 10)), 'success'),
      Log('User logged in', DateTime.now().subtract(const Duration(minutes: 5)), 'success'),
      Log('API call: /check-status', DateTime.now().subtract(const Duration(minutes: 2)), 'pending'),
      Log('Error loading profile', DateTime.now(), 'error'),
    ];

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Cyberlog – Logs Demo'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: logs
                .map(
                  (log) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  log.formatted(),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            )
                .toList(),
          ),
        ),
      ),
    );
  }
}
