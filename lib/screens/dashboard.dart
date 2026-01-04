import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import '../services/security_service.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}
final TextEditingController _ipController = TextEditingController();
class _DashboardState extends State<Dashboard> {
  int _currentIndex = 0;
  late Future<List<dynamic>> _securityData;

  // Network Scanner State
  List<int> _foundPorts = [];
  bool _isScanning = false;

  // Password Strength State
  double _entropyBits = 0;
  String _strengthLabel = "VOID";
  Color _strengthColor = Colors.redAccent;

  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notesController.addListener(_auditPasswordStrength);
    Future.microtask(() => _refreshData());
  }

  @override
  void dispose() {
    _notesController.removeListener(_auditPasswordStrength);
    _notesController.dispose();
    super.dispose();
  }

  void _auditPasswordStrength() {
    final text = _notesController.text;
    if (text.isEmpty) {
      setState(() { _entropyBits = 0; _strengthLabel = "VOID"; });
      return;
    }
    int poolSize = 0;
    if (RegExp(r'[a-z]').hasMatch(text)) poolSize += 26;
    if (RegExp(r'[A-Z]').hasMatch(text)) poolSize += 26;
    if (RegExp(r'[0-9]').hasMatch(text)) poolSize += 10;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(text)) poolSize += 32;

    double entropy = text.length * (log(poolSize) / log(2));
    setState(() {
      _entropyBits = entropy;
      if (entropy < 45) {
        _strengthLabel = "VULNERABLE";
        _strengthColor = Colors.redAccent;
      } else if (entropy < 80) {
        _strengthLabel = "SECURE";
        _strengthColor = Colors.orangeAccent;
      } else {
        _strengthLabel = "QUANTUM-RESISTANT";
        _strengthColor = Colors.greenAccent;
      }
    });
  }

  void _refreshData() {
    final security = Provider.of<SecurityService>(context, listen: false);
    setState(() {
      _securityData = Future.wait<dynamic>([
        security.getPublicIP(),
        security.getHardwareAudit(),
        security.getLiveSecurityNews(),
        security.getPublicIP().then((ip) => security.getGeoIPData(ip)),
      ]);
    });
  }


  void _startNetworkAudit() async {

    String targetIP = _ipController.text.trim();


    if (targetIP.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter the Target IPv4 (Your Computer's IP)"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    var status = await Permission.location.request();

    if (status.isGranted) {
      setState(() {
        _isScanning = true;
        _foundPorts = [];
      });

      debugPrint("NETWORK_LOG: Probing Target -> $targetIP");

      final security = Provider.of<SecurityService>(context, listen: false);

      try {
        final results = await security.scanCommonPorts(targetIP);

        setState(() {
          _foundPorts = results;
          _isScanning = false;
        });


        HapticFeedback.lightImpact();

      } catch (e) {
        debugPrint("SCAN_ERROR: $e");
        _handleScanError("Audit Failed: $e");
      }
    } else {
      _handleScanError("Location permission required for network discovery.");
    }
  }

  void _handleScanError(String message) {
    setState(() => _isScanning = false);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent)
    );
  }

  @override
  Widget build(BuildContext context) {
    final security = Provider.of<SecurityService>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: _currentIndex == 0 ? _buildMonitorView() : _buildVaultView(security),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.white54,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.radar), label: "Monitor"),
          BottomNavigationBarItem(icon: Icon(Icons.enhanced_encryption), label: "Vault"),
        ],
      ),
    );
  }

  Widget _buildMonitorView() {
    return FutureBuilder(
      future: _securityData,
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
        }

        final String ip = snapshot.data?[0] ?? "Offline";
        final Map<String, String> hardware = snapshot.data?[1] ?? {"Model": "Unknown", "Version": "N/A"};
        final List<Map<String, String>> news = List<Map<String, String>>.from(snapshot.data?[2] ?? []);
        final Map<String, double?> geoIP = snapshot.data?[3] ?? {"lat": null, "lon": null};

        return ListView(
          children: [
            _buildInfoCard(ip, hardware),
            _buildGeoIPMapCard(geoIP, ip),
            _buildPortScannerUI(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text("LIVE THREAT FEED", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            ...news.map((n) => _buildNewsItem(n)).toList(),
          ],
        );
      },
    );
  }


  Widget _buildVaultView(SecurityService security) {
    if (!security.isVaultUnlocked) return _buildLockedLayout(security);
    if (security.isDuressMode) return _buildFakeVaultLayout(security);
    return _buildUnlockedLayout(security);
  }

  Widget _buildLockedLayout(SecurityService security) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onLongPress: () { HapticFeedback.vibrate(); security.triggerDuressMode(); },
            child: const Icon(Icons.lock_outline, size: 100, color: Colors.redAccent),
          ),
          const SizedBox(height: 20),
          const Text("VAULT LOCKED", style: TextStyle(color: Colors.white, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () => security.authenticate(),
            icon: const Icon(Icons.fingerprint),
            label: const Text("UNLOCK VAULT"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  // FIX: Added the Lock Icon to the Fake Vault
  Widget _buildFakeVaultLayout(SecurityService security) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("PERSONAL MEMOS", style: TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
                icon: const Icon(Icons.lock_reset, color: Colors.redAccent),
                onPressed: () => security.lockVault() // This lets you lock it back!
            )
          ],
        ),
        const Divider(color: Colors.blueAccent),
        _buildFakeNoteCard("Grocery List", "Milk, Eggs, Bread, Chicken breast."),
        _buildFakeNoteCard("Gym Routine", "Mon: Legs, Wed: Push, Fri: Pull."),
        _buildFakeNoteCard("Work", "Submit weekly report by 5 PM."),
      ],
    );
  }

  Widget _buildUnlockedLayout(SecurityService security) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("SECURE ENCLAVE", style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.lock_open, color: Colors.red), onPressed: () => security.lockVault())
          ],
        ),
        const Divider(color: Colors.greenAccent),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("AUDIT: $_strengthLabel", style: TextStyle(color: _strengthColor, fontSize: 10, fontWeight: FontWeight.bold)),
            Text("${_entropyBits.toStringAsFixed(1)} BITS", style: const TextStyle(color: Colors.white24, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(value: (_entropyBits / 128).clamp(0.0, 1.0), backgroundColor: Colors.white10, color: _strengthColor),
        const SizedBox(height: 20),
        TextField(
          controller: _notesController,
          maxLines: 10,
          style: const TextStyle(color: Colors.orangeAccent, fontFamily: 'monospace'),
          decoration: const InputDecoration(filled: true, fillColor: Color(0xFF111111), border: OutlineInputBorder()),
        ),
      ],
    );
  }


  Widget _buildGeoIPMapCard(Map<String, double?> geoIP, String ip) {
    final lat = geoIP["lat"];
    final lon = geoIP["lon"];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      color: Colors.grey[900],
      child: Column(
        children: [
          ListTile(title: Text("PUBLIC IP: $ip", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
          if (lat != null && lon != null)
            SizedBox(
              height: 180,
              child: FlutterMap(
                options: MapOptions(initialCenter: LatLng(lat, lon), initialZoom: 5.0),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.cyberlog.app'),
                  MarkerLayer(markers: [Marker(point: LatLng(lat, lon), child: const Icon(Icons.location_on, color: Colors.red, size: 30))]),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPortScannerUI() {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IP INPUT FIELD
            TextField(
              controller: _ipController,
              style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: "TARGET IP (e.g. 192.168.1.9)",
                hintStyle: TextStyle(color: Colors.white24),
                prefixIcon: Icon(Icons.lan, color: Colors.greenAccent, size: 18),
                border: InputBorder.none,
              ),
            ),
            const Divider(color: Colors.white10),

            // 2. SCAN BUTTON & STATUS
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("NETWORK PROBE",
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              subtitle: Text(_isScanning ? "Probing common ports..." : "Enter IP and initialize scan",
                  style: const TextStyle(color: Colors.white54, fontSize: 10)),
              trailing: _isScanning
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orangeAccent))
                  : IconButton(
                  icon: const Icon(Icons.play_circle_fill, color: Colors.greenAccent, size: 30),
                  onPressed: _startNetworkAudit
              ),
            ),

            //3. RESULTS DISPLAY
            if (!_isScanning && _foundPorts.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("AUDIT SUCCESS", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      "OPEN: ${_foundPorts.join(', ')}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 14),
                    ),
                  ],
                ),
              )
            else if (!_isScanning && _foundPorts.isEmpty && _ipController.text.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text("! NO OPEN PORTS DETECTED", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(backgroundColor: Colors.black, centerTitle: true, title: const Text("CYBER_LOG", style: TextStyle(fontWeight: FontWeight.bold)));
  Widget _buildInfoCard(String ip, Map<String, String> hardware) => Card(margin: const EdgeInsets.all(16), color: Colors.grey[900], child: ListTile(leading: const Icon(Icons.lan, color: Colors.greenAccent), title: Text("NODE: $ip", style: const TextStyle(color: Colors.white)), subtitle: Text("${hardware['Model']}", style: const TextStyle(color: Colors.white70))));
  Widget _buildNewsItem(Map<String, String> item) => Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), color: Colors.white.withOpacity(0.05), child: ListTile(title: Text(item['title']!, style: const TextStyle(color: Colors.white, fontSize: 12)), subtitle: Text(item['desc']!, style: const TextStyle(color: Colors.white54, fontSize: 10), maxLines: 1)));
  Widget _buildFakeNoteCard(String title, String content) => Card(color: Colors.black26, margin: const EdgeInsets.only(top: 10), child: ListTile(title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)), subtitle: Text(content, style: const TextStyle(color: Colors.white60, fontSize: 12))));
}