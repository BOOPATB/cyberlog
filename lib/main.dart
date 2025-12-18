import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ================== PROVIDERS ==================

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

// ================== CUSTOM ROUTE ==================

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

// ================== MAIN APP ==================

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LogProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
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
      title: 'Provider Nav App',
      theme: ThemeData(
        brightness: settings.isDarkMode ? Brightness.dark : Brightness.light,
        // FIXED: Corrected hex code from 0密 to 0xFF
        scaffoldBackgroundColor: settings.isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F7),
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const RootScreen(),
    );
  }
}

// ================== ROOT SCREEN ==================

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
    final titles = ['Home', 'Activity Logs', 'Settings'];

    return Scaffold(
      appBar: AppBar(title: Text(titles[_currentIndex])),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          _animatedBarItem(icon: Icons.home, label: 'Home', index: 0),
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

// ================== TAB PAGES ==================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Navigation Flow'),
        onPressed: () {
          context.read<LogProvider>().addLog("Started Flow: Entered Screen A");
          Navigator.of(context).push(createSlideRoute(const ScreenA()));
        },
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

// ================== SLIDE SCREENS ==================

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