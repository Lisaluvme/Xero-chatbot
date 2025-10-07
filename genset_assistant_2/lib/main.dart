import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'features/learn/learn_page.dart';
import 'features/maintenance/maintenance_page.dart';
import 'features/troubleshooting/troubleshooting_page.dart';
import 'features/service_records/service_records_page.dart';
import 'features/live_status/live_status_page.dart';
import 'features/contact/contact_page.dart';
import 'features/products/products_page.dart';
import 'features/ai_chat/ai_chat_page.dart';
import 'features/auth/login_page.dart';
import 'services/notification_service.dart';
import 'widgets/home_page.dart' show HomePageWidget;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().initialize();
  runApp(const GensetAssistantApp());
}

class GensetAssistantApp extends StatelessWidget {
  const GensetAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Genset Assistant 2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1A3C6E), // Primary Blue
          onPrimary: Color(0xFFFFFFFF), // White
          secondary: Color(0xFF2563EB), // Accent Blue
          onSecondary: Color(0xFFFFFFFF), // White
          surface: Color(0xFFFFFFFF), // White
          onSurface: Color(0xFF0F172A), // Text Color
          background: Color(0xFFF3F6FB), // Background
          onBackground: Color(0xFF0F172A), // Text Color
          error: Color(0xFFF59E0B), // Warning orange - for alerts only
          onError: Color(0xFFFFFFFF), // White
          tertiary: Color(0xFF38BDF8), // Highlight Color
          onTertiary: Color(0xFFFFFFFF), // White
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3F6FB), // Background
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A3C6E), // Primary Blue
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
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF0F172A)), // Text Color
          bodyMedium: TextStyle(color: Color(0xFF6B7280)),
          bodySmall: TextStyle(color: Color(0xFF6B7280)),
          headlineLarge: TextStyle(color: Color(0xFF0F172A)), // Text Color
          headlineMedium: TextStyle(color: Color(0xFF0F172A)), // Text Color
          headlineSmall: TextStyle(color: Color(0xFF0F172A)), // Text Color
          titleLarge: TextStyle(color: Color(0xFF0F172A)), // Text Color
          titleMedium: TextStyle(color: Color(0xFF0F172A)), // Text Color
          titleSmall: TextStyle(color: Color(0xFF0F172A)), // Text Color
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB), // Accent Blue
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: const Color(0xFF2563EB).withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          shadowColor: Colors.black.withOpacity(0.1),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const HomePage();
          }
          return const LoginPage();
        },
      ),
    );
  }
}



class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(
          '$title Screen\nComing Soon!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  // Static method to show chat shortcut from anywhere in the app
  static void showChatShortcut() {
    final state = _homePageKey.currentState;
    if (state != null) {
      state._showChatShortcutButton();
    }
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

// Global key to access HomePage state
final GlobalKey<_HomePageState> _homePageKey = GlobalKey<_HomePageState>();

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _showChatShortcut = false;

  static const List<Widget> _pages = <Widget>[
    HomePageWidget(),
    ProductsScreen(initialCategory: 0),
    LearnPage(),
    ServiceRecordsPage(),
    LiveStatusPage(),
    ContactPage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _showChatShortcutButton() {
    setState(() => _showChatShortcut = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _homePageKey,
      extendBody: true, // 让底部导航半透明效果更自然
      floatingActionButton: _showChatShortcut ? FloatingActionButton(
        onPressed: () {
          // Navigate to AI Chat page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AiChatPage()),
          );
        },
        backgroundColor: const Color(0xFF1E3A8A), // Primary blue
        child: const Icon(Icons.chat, color: Colors.white),
        tooltip: 'Chat with Assistant',
      ) : null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: _pages[_selectedIndex],
      ),

      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          child: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.store_rounded),
                label: 'Products',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_books_rounded),
                label: 'Learn',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.build_circle_rounded),
                label: 'Service',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.visibility_rounded),
                label: 'Live',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.support_agent_rounded),
                label: 'Contact',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Color(0xFF1A3C6E), // Primary Blue
            unselectedItemColor: Color(0xFF0F172A), // Text Color - Black
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
