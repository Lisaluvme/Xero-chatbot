import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../features/learn/learn_page.dart';
import '../features/live_status/live_status_page.dart';
import '../features/contact/contact_page.dart';
import '../features/products/products_page.dart';
import '../widgets/home_page.dart' show HomePageWidget;
import '../widgets/unauthenticated_homepage.dart';
import '../providers/genset_provider.dart';

/// Main app wrapper that handles authentication-aware navigation
/// Non-account features (Products, News/Home, Learn, Contact) are accessible without login
/// Account-specific features (Live Status, Profile) require authentication
class MainAppWrapper extends StatefulWidget {
  const MainAppWrapper({super.key});

  @override
  State<MainAppWrapper> createState() => _MainAppWrapperState();
}

class _MainAppWrapperState extends State<MainAppWrapper> {
  User? _currentUser;
  late StreamSubscription<User?> _authSubscription;
  User? _previousUser; // Track previous user to detect login

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _previousUser = _currentUser; // Initialize previous user
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        // Detect login (user went from null to non-null)
        if (_previousUser == null && user != null) {
          print('🔐 User just signed in: ${user.email}');
          // Trigger genset data fetch for newly signed-in user
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && context.mounted) {
              print('🔄 Triggering genset data fetch after login...');
              Provider.of<GensetProvider>(context, listen: false).fetchGensets();
            }
          });
        }
        
        // Detect logout (user went from non-null to null)
        if (_previousUser != null && user == null) {
          print('🔓 User just signed out');
          // Clear genset data when user logs out
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && context.mounted) {
              Provider.of<GensetProvider>(context, listen: false).reset();
            }
          });
        }

        setState(() {
          _currentUser = user;
          _previousUser = user; // Update previous user
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  // Pages that don't require authentication
  static const List<Widget> _publicPages = <Widget>[
    UnauthenticatedHomepage(), // Landing page for unauthenticated users (only page)
  ];

  // Account-specific pages that require authentication
  static const List<Widget> _authenticatedPages = <Widget>[
    HomePageWidget(),
    ProductsScreen(initialCategory: 0),
    LearnPage(),
    LiveStatusPage(),          // Genset monitoring (account-specific)
    ContactPage(),
  ];

  @override
  Widget build(BuildContext context) {
    print('🔄 MainAppWrapper: Building...');
    final isAuthenticated = _currentUser != null;
    print('🔐 Authentication status: ${isAuthenticated ? "LOGGED IN" : "NOT LOGGED IN"}');
    final pages = isAuthenticated ? _authenticatedPages : _publicPages;
    print('📄 Pages count: ${pages.length} - using ${isAuthenticated ? "authenticated" : "public"} pages');

    return MainNavigation(
      isAuthenticated: isAuthenticated,
      pages: pages,
      authenticatedPagesCount: _authenticatedPages.length,
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({
    super.key,
    required this.isAuthenticated,
    required this.pages,
    required this.authenticatedPagesCount,
  });

  final bool isAuthenticated;
  final List<Widget> pages;
  final int authenticatedPagesCount;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class AuthTransitionWrapper extends StatefulWidget {
  const AuthTransitionWrapper({
    super.key,
    required this.child,
    required this.isAuthenticated,
  });

  final Widget child;
  final bool isAuthenticated;

  @override
  State<AuthTransitionWrapper> createState() => _AuthTransitionWrapperState();
}

class _AuthTransitionWrapperState extends State<AuthTransitionWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Add a delay to prevent blank screen during navigation transition
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F6FB),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return widget.child;
  }
}

class _MainNavigationState extends State<MainNavigation> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0; // Default to Home
  }

  @override
  void didUpdateWidget(MainNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset to safe index if user logs in/out and pages change
    if (_selectedIndex >= widget.pages.length) {
      _selectedIndex = 0;
    }
  }

  void _onItemTapped(int index) async {
    if (!widget.isAuthenticated) {
      // For unauthenticated users, allow access to Home (index 0) only
      if (index > 0) {
        return; // Don't allow switching to non-existent pages
      }
    }

    setState(() => _selectedIndex = index);
  }

  Future<bool?> _showAuthRequiredDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In Required'),
        content: const Text(
          'Access to your personal genset data requires signing in. '
          'Would you like to sign in now?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continue Browsing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // For unauthenticated users, hide bottom navigation and just show the page
    if (!widget.isAuthenticated) {
      return Scaffold(
        body: widget.pages[_selectedIndex],
      );
    }

    // For authenticated users, show full navigation with bottom bar
    return Scaffold(
      body: widget.pages[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            items: [
              _buildBottomNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
              ),
              _buildBottomNavItem(
                icon: Icons.store_rounded,
                label: 'Products',
                index: 1,
              ),
              _buildBottomNavItem(
                icon: Icons.library_books_rounded,
                label: 'Learn',
                index: 2,
              ),
              _buildBottomNavItem(
                icon: Icons.visibility_rounded,
                label: 'Live',
                index: 3,
              ),
              _buildBottomNavItem(
                icon: Icons.support_agent_rounded,
                label: 'Contact',
                index: 4,
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFF1E3A8A),
            unselectedItemColor: Colors.grey.shade600,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            showUnselectedLabels: true,
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _selectedIndex == index
              ? const Color(0xFF1E3A8A).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22),
      ),
      label: label,
    );
  }
}
