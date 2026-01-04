import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dart_rss/dart_rss.dart';
import 'package:local_auth/local_auth.dart';
import 'package:network_info_plus/network_info_plus.dart';

class SecurityService with ChangeNotifier {
  final String rssUrl = "https://feeds.feedburner.com/TheHackersNews";
  final LocalAuthentication _auth = LocalAuthentication();

  Future<Map<String,double?>> getGeoIPData(String ip) async{
    if(ip=="offline"||ip=="127.0.0.1"){
      return{"lat":null,"lot":null};
    }
    try{
      final response = await http.get(Uri.parse('http://ip-api.com/json/$ip'));
      if(response.statusCode ==200){
        final data = jsonDecode(response.body);
        if(data['status']== 'success'){
          return {
            "lat": data['lat'] as double?,
            "lon": data['lon'] as double?,
          };
        }
      }
    } catch(e){
      debugPrint("GEO IP ERROR $e");
    }
    return{"lat":null,"lot":null};
  }

  Future<List<int>> scanCommonPorts(String ip) async {
    List<int> openPorts = [];
    List<int> portToScan = [21, 22, 23, 80, 443, 8080, 3306,8000];

    for (int port in portToScan) {
      try {

        final socket = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 500));
        openPorts.add(port);
        socket.destroy();
      } catch (e) {

      }
    }
    return openPorts;
  }

  bool _isDuressMode = false;
  bool get isDuressMode => _isDuressMode;

  void triggerDuressMode(){
    _isVaultUnlocked = true;
    _isDuressMode = true;
    notifyListeners();
  }
  // Vault State
  bool _isVaultUnlocked = false;
  bool get isVaultUnlocked => _isVaultUnlocked;

  // --- 1. Biometric Logic ---
  Future<void> authenticate() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Access Encrypted Vault',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      _isVaultUnlocked = didAuthenticate;
      notifyListeners(); // This tells the UI to rebuild
    } catch (e) {
      _isVaultUnlocked = false;
      notifyListeners();
    }
  }

  void lockVault() {
    _isVaultUnlocked = false;
    _isDuressMode = false;
    notifyListeners();
  }

  // --- 2. Existing News/IP/Hardware Logic (Keep your previous methods here) ---
  Future<List<Map<String, String>>> getLiveSecurityNews() async {
    try {
      final response = await http.get(Uri.parse(rssUrl));
      if (response.statusCode == 200) {
        var feed = RssFeed.parse(response.body);
        return feed.items.take(10).map((item) {
          return {
            "title": item.title ?? "Security Alert",
            "desc": item.description?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '') ?? "Details in portal."
          };
        }).toList();
      }
      return [{"title": "Feed Error", "desc": "Could not parse live security data."}];
    } catch (e) { return [{"title": "Connection Offline", "desc": "Check your status."}]; }
  }

  Future<String> getPublicIP() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org?format=json'));
      return jsonDecode(response.body)['ip'];
    } catch (_) { return "Offline"; }
  }

  Future<Map<String, String>> getHardwareAudit() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return {"Model": androidInfo.model, "Version": "Android ${androidInfo.version.release}"};
    }
    return {"Model": "iOS Device", "Version": "Latest"};
  }
}

