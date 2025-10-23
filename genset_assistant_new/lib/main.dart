import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'features/learn/learn_page.dart';
import 'features/service_records/service_records_page.dart';
import 'features/live_status/live_status_page.dart';
import 'features/contact/contact_page.dart';
import 'features/products/products_page.dart';
import 'features/ai_chat/ai_chat_page.dart';
import 'features/auth/login_page.dart';
import 'providers/genset_provider.dart' as gp;
import 'services/notification_service.dart';
import 'widgets/home_page.dart' show HomePageWidget;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp();
  //await NotificationService().initialize();
  runApp(const GensetAssistantApp());
}

class GensetAssistantApp extends StatelessWidget {
  const GensetAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => gp.GensetProvider()),
      ],
      child: MaterialApp(
        title: 'Genset Assistant 2',
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
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static void showChatShortcut() {
    final state = _homePageKey.currentState;
    if (state != null) {
      state._showChatShortcutButton();
    }
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

final GlobalKey<_HomePageState> _homePageKey = GlobalKey<_HomePageState>();

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _showChatShortcut = false;

  static const List<Widget> _pages = <Widget>[
    HomePageWidget(),
    ProductsScreen(initialCategory: 0),
    LearnPage(),
    ServiceRecordsPage(),
    LiveStatusPage(), // ✅ 所有 genset 数据都在这里
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
      extendBody: true,
      floatingActionButton: _showChatShortcut
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AiChatPage()),
          );
        },
        backgroundColor: const Color(0xFF1E3A8A),
        child: const Icon(Icons.chat, color: Colors.white),
        tooltip: 'Chat with Assistant',
      )
          : null,
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
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.store_rounded), label: 'Products'),
              BottomNavigationBarItem(icon: Icon(Icons.library_books_rounded), label: 'Learn'),
              BottomNavigationBarItem(icon: Icon(Icons.build_circle_rounded), label: 'Service'),
              BottomNavigationBarItem(icon: Icon(Icons.visibility_rounded), label: 'Live'),
              BottomNavigationBarItem(icon: Icon(Icons.support_agent_rounded), label: 'Contact'),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFF1A3C6E),
            unselectedItemColor: const Color(0xFF0F172A),
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
