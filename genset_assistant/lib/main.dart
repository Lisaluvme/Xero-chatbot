import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'providers/genset_provider.dart' as gp;
import 'widgets/main_app_wrapper.dart';
import 'config/config_manager.dart';

// Development flag for testing watch functionality without authentication
const bool DEVELOPER_MODE_SKIP_AUTH = true; // Set to false for production

// Cache clearing function to prevent app hanging
Future<void> _clearAppCache() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Clear cached genset data that might cause hanging
    await prefs.remove('latestGensetData');
    // Clear any other cached async operations
    await prefs.remove('cached_provider_state');
    print('🧹 Cache cleared successfully');
  } catch (e) {
    print('⚠️ Cache clear failed, but continuing: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load();
  } catch (e) {
    print('⚠️ .env loading failed, using defaults: $e');
  }

  // Initialize configuration (use production for Netlify backend)
  ConfigManager.setupProduction();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    // Continue without Firebase for now, though authentication will be limited
  }

  print('🚀 Starting Genset Assistant App...');

  // Clear any cached data that might cause hanging
  await _clearAppCache();

  //await NotificationService().initialize();
  runApp(const GensetAssistantApp());
}

class GensetAssistantApp extends StatefulWidget {
  const GensetAssistantApp({super.key});

  @override
  State<GensetAssistantApp> createState() => _GensetAssistantAppState();
}

class _GensetAssistantAppState extends State<GensetAssistantApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Clear chat history when app is closed
    if (state == AppLifecycleState.detached) {
      _clearChatHistoryOnAppClose();
    }
  }

  Future<void> _clearChatHistoryOnAppClose() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_history');
      await prefs.remove('chat_language');
      print("DEBUG: Chat history cleared when app was closed");
    } catch (e) {
      print("Error clearing chat history on app close: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => gp.GensetProvider(),
      child: MaterialApp(
        title: 'Mega Genset 99',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1A3C6E),
            onPrimary: Color(0xFFFFFFFF),
            secondary: Color(0xFF2563EB),
            onSecondary: Color(0xFFFFFFFF),
            surface: Color(0xFFFFFFFF),
            onSurface: Color(0xFF0F172A),
            background: Color(0xFFF3F6FB),
            onBackground: Color(0xFF0F172A),
            error: Color(0xFFF59E0B),
            onError: Color(0xFFFFFFFF),
            tertiary: Color(0xFF38BDF8),
            onTertiary: Color(0xFFFFFFFF),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF3F6FB),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A3C6E),
            elevation: 2,
            shadowColor: Color(0xFF1A3C6E),
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
          ),
        ),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            print('🔄 Auth State Changed: ${snapshot.connectionState} - Has Data: ${snapshot.hasData}');
            if (snapshot.hasData) {
              print('✅ User is signed in: ${snapshot.data?.email}');
            } else {
              print('❌ No user signed in');
            }

            // Show brief loading only while auth state is determining
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Always show main app - authentication handled within individual features
            return const MainAppWrapper();
          },
        ),
      ),
    );
  }
}
