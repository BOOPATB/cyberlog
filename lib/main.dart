import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';



class LogProvider extends ChangeNotifier {
  final List<String> _logs = [];
  List<String> get logs => List.unmodifiable(_logs);

  void addLog(String message) {
    final timestamp = DateTime.now().toString().split('.').first;
    _logs.insert(0, '[$timestamp] $message');
    notifyListeners();
  }
}

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

class CyberTipProvider extends ChangeNotifier {
  String _tip = "Loading your daily security tip...";
  bool _isLoading = true;

  String get tip => _tip;
  bool get isLoading => _isLoading;

  CyberTipProvider() {
    fetchTip();
  }

  Future<void> fetchTip() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Fetching from a public API
      final response = await http.get(Uri.parse('https://api.adviceslip.com/advice'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _tip = data['slip']['advice'];
      }
    } catch (e) {
      _tip = "Cyber Awareness: Always verify links before clicking.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}


Route createSlideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;
      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}



void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LogProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CyberTipProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CyberLog App',
      theme: ThemeData(
        brightness: settings.isDarkMode ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: settings.isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F7),
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const RootScreen(),
    );
  }
}



class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    LogsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final titles = ['Dashboard', 'Activity Logs', 'Settings'];

    return Scaffold(
      appBar: AppBar(title: Text(titles[_currentIndex])),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          _animatedBarItem(icon: Icons.dashboard, label: 'Home', index: 0),
          _animatedBarItem(icon: Icons.history, label: 'Logs', index: 1),
          _animatedBarItem(icon: Icons.settings, label: 'Settings', index: 2),
        ],
      ),
    );
  }

  BottomNavigationBarItem _animatedBarItem({required IconData icon, required String label, required int index}) {
    final bool selected = _currentIndex == index;
    return BottomNavigationBarItem(
      label: label,
      icon: Transform.scale(
        scale: selected ? 1.2 : 1.0,
        child: Icon(icon, color: selected ? Colors.teal : Colors.grey),
      ),
    );
  }
}


class CyberTipCard extends StatelessWidget {
  const CyberTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tipProvider = context.watch<CyberTipProvider>();

    return Card(
      elevation: 0,
      color: Colors.teal.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.security, color: Colors.teal, size: 20),
                    SizedBox(width: 8),
                    Text("CYBER TIP OF THE DAY", 
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12, color: Colors.teal)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18, color: Colors.teal),
                  onPressed: () => tipProvider.fetchTip(),
                )
              ],
            ),
            const SizedBox(height: 12),
            tipProvider.isLoading 
              ? const LinearProgressIndicator() 
              : Text(
                  tipProvider.tip,
                  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
          ],
        ),
      ),
    );
  }
}



class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const CyberTipCard(),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Navigation Flow'),
            onPressed: () {
              context.read<LogProvider>().addLog("Started Flow: Entered Screen A");
              Navigator.of(context).push(createSlideRoute(const ScreenA()));
            },
          ),
        ],
      ),
    );
  }
}

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logProvider = context.watch<LogProvider>();

    return logProvider.logs.isEmpty
        ? const Center(child: Text("No activity logged yet."))
        : ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: logProvider.logs.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) => Text(
        logProvider.logs[index],
        style: const TextStyle(fontFamily: 'monospace'),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return ListView(
      children: [
        SwitchListTile(
          title: const Text("Dark Mode"),
          subtitle: const Text("Switch between light and dark themes"),
          secondary: const Icon(Icons.palette),
          value: settings.isDarkMode,
          onChanged: (val) => settings.toggleTheme(),
        ),
      ],
    );
  }
}


class ScreenA extends StatelessWidget {
  const ScreenA({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screen A')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Go to Screen B'),
          onPressed: () {
            context.read<LogProvider>().addLog("Navigated to Screen B");
            Navigator.of(context).push(createSlideRoute(const ScreenB()));
          },
        ),
      ),
    );
  }
}

class ScreenB extends StatelessWidget {
  const ScreenB({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screen B')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Go to Screen C'),
          onPressed: () {
            context.read<LogProvider>().addLog("Navigated to Screen C");
            Navigator.of(context).push(createSlideRoute(const ScreenC()));
          },
        ),
      ),
    );
  }
}

class ScreenC extends StatelessWidget {
  const ScreenC({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screen C')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Finish and Back'),
          onPressed: () {
            context.read<LogProvider>().addLog("Completed Flow: Returned to Home");
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
