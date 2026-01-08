import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For ensureInitialized
import 'package:device_info_plus/device_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _deviceModel = "Loading...";
  String _osVersion = "Loading...";

  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
  }

  Future<void> _getDeviceInfo() async {
    // Required for plugins on app startup [web:9]
    WidgetsFlutterBinding.ensureInitialized();
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        setState(() {
          _deviceModel = androidInfo.model;
          _osVersion = "Android ${androidInfo.version.release}";
        });
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        setState(() {
          _deviceModel = iosInfo.utsname.machine;
          _osVersion = "iOS ${iosInfo.systemVersion}";
        });
      }
    } catch (e) {
      setState(() {
        _deviceModel = "Error loading info";
        _osVersion = "N/A";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: const Text("SETTINGS", style: TextStyle(letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildInfoSection("System Information"),
          _buildInfoTile(Icons.phone_android, "Device Model", _deviceModel),
          _buildInfoTile(Icons.info_outline, "OS Version", _osVersion),
          const Divider(color: Colors.white24, height: 40),
          _buildInfoSection("App Version"),
          _buildInfoTile(Icons.code, "Build", "v1.0.10-release"),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: Colors.blueGrey[200], fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        trailing: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
