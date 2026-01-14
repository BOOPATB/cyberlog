import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint("Firebase Init Error: $e");
  }

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF050A0E),
      primaryColor: Colors.cyanAccent,
    ),
    home: isLoggedIn ? const ModernPermApp() : const LoginScreen(),
  ));
}

// --- LOGIN SCREEN ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;

  Future<void> _authenticate() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("FIELDS REQUIRED"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Login/Signup with a 10-second timeout to prevent infinite loading
      if (_isSignUp) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ).timeout(const Duration(seconds: 10));
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ).timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      debugPrint("Auth Step Caught: $e");
    } finally {
      // SUCCESS CHECK: If the server says we are logged in, move forward
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        if (mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const ModernPermApp()));
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("AUTH FAILED: CHECK CONNECTION OR DATABASE"), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const Icon(Icons.shield_outlined, size: 80, color: Colors.cyanAccent),
              const SizedBox(height: 20),
              Text(_isSignUp ? "CREATE IDENTITY" : "IDENTITY CHALLENGE",
                  style: const TextStyle(color: Colors.cyanAccent, letterSpacing: 4, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              _buildField(_emailController, "EMAIL_ADDRESS", false),
              const SizedBox(height: 15),
              _buildField(_passwordController, "PASSWORD_HASH", true),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.cyanAccent)
                  : _buildButton(_isSignUp ? "REGISTER" : "LOGIN", _authenticate),
              TextButton(
                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(_isSignUp ? "ALREADY REGISTERED? LOG IN" : "NO IDENTITY? SIGN UP",
                    style: const TextStyle(color: Colors.white24, fontSize: 10)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, bool obscure) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      child: Container(
        width: double.infinity, height: 50,
        decoration: BoxDecoration(border: Border.all(color: Colors.cyanAccent)),
        child: Center(child: Text(text, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
      ),
    );
  }
}

// --- DASHBOARD SCREEN ---
class ModernPermApp extends StatefulWidget {
  const ModernPermApp({super.key});
  @override
  State<ModernPermApp> createState() => _ModernPermAppState();
}

class _ModernPermAppState extends State<ModernPermApp> {
  final TextEditingController _noteController = TextEditingController();
  // Get current user UID for data isolation
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _addNote(String content) async {
    if (uid == null || content.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notes')
          .add({
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'time_label': DateTime.now().toString().substring(11, 16),
      });
      _noteController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("SYNC ERROR: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CYBER_LOG: SYNC_READY", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace')),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: "> ENTRY_DATA...",
                suffixIcon: Icon(Icons.cloud_upload, color: Colors.cyanAccent),
                border: OutlineInputBorder(),
              ),
              onSubmitted: _addNote,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('notes')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  // Handle Error States (Permissions/Network)
                  if (snapshot.hasError) {
                    return Center(child: Text("ERROR: CHECK FIRESTORE RULES", style: const TextStyle(color: Colors.redAccent)));
                  }

                  // Handle Loading State
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                  }

                  // Handle Empty State
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("NO DATA FOUND IN CLOUD", style: TextStyle(color: Colors.white24)));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var data = doc.data() as Map<String, dynamic>;

                      return Card(
                        color: Colors.white.withOpacity(0.05),
                        child: ListTile(
                          title: Text(data['content'] ?? "EMPTY", style: const TextStyle(color: Colors.white)),
                          subtitle: Text("ID: ${doc.id.substring(0, 5)}... | ${data['time_label'] ?? ''}",
                              style: const TextStyle(color: Colors.white24, fontSize: 10)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 18),
                            onPressed: () => doc.reference.delete(),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}