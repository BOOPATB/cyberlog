import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
// Ensure this file exists in your lib/ folder
import 'settings_page.dart';

void main() {
  // 1. Crucial for Xiaomi/Android stability to prevent engine crashes
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ModernPermApp(),
  ));
}

class BlackboxLogger {
  List<String> logs = [];

  void addEvent(String event) {
    final timestamp = DateTime.now().toString().split('.').first;
    logs.add("[$timestamp] $event");
  }

  Future<String> exportLogs() async {
    try {
      // Use getApplicationDocumentsDirectory for better Android 13+ compatibility
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/system_log.txt');
      String content = logs.join('\n');
      await file.writeAsString(content);
      return "Log saved: ${file.path}";
    } catch (e) {
      return "Export failed: $e";
    }
  }
}

class ModernPermApp extends StatefulWidget {
  const ModernPermApp({super.key});
  @override
  State<ModernPermApp> createState() => _ModernPermAppState();
}

class _ModernPermAppState extends State<ModernPermApp> {
  final BlackboxLogger myLogger = BlackboxLogger();
  bool _isLoading = true;
  Map<String, bool> _permissionStatus = {};

  @override
  void initState() {
    super.initState();
    myLogger.addEvent("App initialized");
    // Small delay ensures the UI is ready before the permission popup appears
    Future.delayed(Duration.zero, () => _requestAllPermissions());
  }

  Future<void> _requestAllPermissions() async {
    myLogger.addEvent("Requesting permissions...");
    if (mounted) setState(() => _isLoading = true);

    // Requesting Camera and Storage
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.storage,
    ].request();

    if (mounted) {
      setState(() {
        _permissionStatus = {
          'Camera': statuses[Permission.camera]!.isGranted,
          'Storage': statuses[Permission.storage]!.isGranted,
        };
        _isLoading = false;
      });
    }

    final isAllGranted = _permissionStatus.values.every((granted) => granted);
    myLogger.addEvent("Result: ${isAllGranted ? 'Access Granted' : 'Access Denied'}");

    if (isAllGranted) {
      _showFeedback("All Systems Optimized", Colors.greenAccent);
    } else {
      _showFeedback("Permissions Required", Colors.orangeAccent);
    }
  }

  void _showFeedback(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _goToSettings() {
    myLogger.addEvent("Navigating to Settings");
    // Direct navigation is safer than named routes to avoid black screens
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  Future<void> _exportLogs() async {
    myLogger.addEvent("Exporting data...");
    String result = await myLogger.exportLogs();
    _showFeedback(result, Colors.blue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeaderIcon(),
                const SizedBox(height: 30),
                const Text("SYSTEM SECURITY",
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w300, letterSpacing: 4)),
                const SizedBox(height: 40),

                // Status Display
                ..._permissionStatus.entries.map((entry) => _buildStatusTile(entry.key, entry.value)),

                const SizedBox(height: 30),
                _buildLogTerminal(),
                const SizedBox(height: 20),

                // Actions
                _buildButton("RETRY PERMISSIONS", Colors.blueAccent, _requestAllPermissions),
                const SizedBox(height: 15),
                _buildButton("EXPORT LOGS", Colors.greenAccent, _exportLogs),
                const SizedBox(height: 15),
                if (_permissionStatus.values.every((v) => v))
                  _buildButton("OPEN DEVICE SETTINGS", Colors.purpleAccent, _goToSettings),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 40, spreadRadius: 5)],
      ),
      child: const Icon(Icons.shield_outlined, size: 100, color: Colors.white),
    );
  }

  Widget _buildStatusTile(String label, bool isGranted) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 40),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isGranted ? Colors.greenAccent.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(isGranted ? Icons.check_circle : Icons.cancel, color: isGranted ? Colors.greenAccent : Colors.redAccent, size: 20),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w400)),
          const Spacer(),
          Text(isGranted ? "ACTIVE" : "OFFLINE", style: TextStyle(color: isGranted ? Colors.greenAccent : Colors.redAccent, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildLogTerminal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 25, bottom: 8),
          child: Text("SYSTEM_LOGS_V1.0", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        Container(
          height: 120,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: SingleChildScrollView(
            reverse: true,
            child: Text(
              myLogger.logs.isEmpty ? "> Initializing..." : myLogger.logs.join('\n'),
              style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: 250,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color.withOpacity(0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
      ),
    );
  }
}