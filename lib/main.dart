import 'package:flutter/material.dart';

void main() {
  runApp(const DashboardApp());
}

class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Cyberlog Dashboard'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // 2-column GridView with 4 placeholder cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,          // two columns
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 4 / 3,    // tweak height
                  children: const [
                    _DashboardCard(
                      title: 'Daily Log',
                      icon: Icons.today,
                      bgColor: Color(0xFFE3F2FD),  // light blue
                      iconColor: Color(0xFF1976D2),
                    ),
                    _DashboardCard(
                      title: 'Cyber Tips',
                      icon: Icons.shield_outlined,
                      bgColor: Color(0xFFE8F5E9),  // light green
                      iconColor: Color(0xFF2E7D32),
                    ),
                    _DashboardCard(
                      title: 'Device Security',
                      icon: Icons.security,
                      bgColor: Color(0xFFFFF3E0),  // light orange
                      iconColor: Color(0xFFF57C00),
                    ),
                    _DashboardCard(
                      title: 'Notes',
                      icon: Icons.note_alt_outlined,
                      bgColor: Color(0xFFF3E5F5),  // light purple
                      iconColor: Color(0xFF7B1FA2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable card widget with Container + BoxDecoration
class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16), // smooth corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'View details',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

