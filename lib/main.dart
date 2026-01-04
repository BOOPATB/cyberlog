import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/security_service.dart';
import 'screens/dashboard.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => SecurityService(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Dashboard(),
      ),
    ),
  );
}