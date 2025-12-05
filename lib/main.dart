import 'package:flutter/material.dart';

void main() {
  runApp(const StringToAsciiApp());
}

class StringToAsciiApp extends StatefulWidget {
  const StringToAsciiApp({super.key});

  @override
  State<StringToAsciiApp> createState() => _StringToAsciiAppState();
}

class _StringToAsciiAppState extends State<StringToAsciiApp> {
  final TextEditingController _controller = TextEditingController();
  String _output = '';

  // Convert a string like "PARTH" to a number by summing character codes
  int _stringToNumber(String input) {
    int sum = 0;
    for (int i = 0; i < input.length; i++) {
      sum += input.codeUnitAt(i); // ASCII/UTF‑16 code of each character
    }
    return sum;
  }

  void _convertAndCheck() {
    String input = _controller.text.trim();

    if (input.isEmpty) {
      setState(() {
        _output = 'Please enter a non‑empty string.';
      });
      return;
    }

    int number = _stringToNumber(input);
    String parity = number % 2 == 0 ? 'even' : 'odd';

    setState(() {
      _output =
      'String: "$input"\nNumber value: $number\nThe number $number is $parity.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'String → Number ',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('String to Number Checker'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Enter any string (e.g. DUDUDU):'),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'MAX VERSTAPPEN',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _convertAndCheck,
                child: const Text('Convert & Check'),
              ),
              const SizedBox(height: 16),
              Text(
                _output,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
