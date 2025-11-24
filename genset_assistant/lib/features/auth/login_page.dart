import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_fonts/google_fonts.dart';
import 'register_page.dart';
import '../../services/airtable_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _signInWithEmail() async {
    _showEmailSignInDialog();
  }

  void _showEmailSignInDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Sign in with Email',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.inter(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Email',
                  hintStyle: GoogleFonts.inter(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                style: GoogleFonts.inter(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: GoogleFonts.inter(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() => obscurePassword = !obscurePassword);
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                final cleanEmail = emailController.text.trim().toLowerCase();
                final cleanPassword = passwordController.text.trim();

                if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                  return;
                }

                if (!_isValidEmail(cleanEmail)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid email address')),
                  );
                  return;
                }

                setState(() => _isLoading = true);
                try {
                  print('🔐 Attempting to sign in with email: $cleanEmail');

                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: cleanEmail,
                    password: cleanPassword,
                  );

                  print('✅ Sign in successful!');
                  if (mounted) {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Close login page - return to homepage
                    print('🏠 Auth state change will automatically navigate to homepage');
                  }
                } catch (e) {
                  print('❌ Sign in failed: $e');
                  if (mounted) {
                    String errorMessage = 'Sign-in failed';
                    if (e.toString().contains('user-not-found')) {
                      errorMessage = 'No user found with this email. Please register first.';
                    } else if (e.toString().contains('wrong-password')) {
                      errorMessage = 'Incorrect password. Please try again.';
                    } else if (e.toString().contains('invalid-email')) {
                      errorMessage = 'Invalid email format';
                    } else if (e.toString().contains('network-request-failed')) {
                      errorMessage = 'Network error. Please check your connection';
                    } else if (e.toString().contains('too-many-requests')) {
                      errorMessage = 'Too many failed attempts. Please try again later.';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Sign In',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      print('🔐 Starting Google Sign In...');

      String? osName = Theme.of(context).platform.name;
      bool isSimulator = osName?.contains('iOS') == true ||
          osName?.contains('Android') == true ||
          osName?.contains('macOS') == true ||
          false;

      print('📱 Platform: $osName (Simulator check: $isSimulator)');

      final GoogleSignIn googleSignIn = GoogleSignIn(
        hostedDomain: null,
        clientId: null,
        forceCodeForRefreshToken: true,
      );

      print('🔐 Resetting Google Sign In session to force account chooser...');
      await googleSignIn.signOut();

      print('🔐 Attempting native Google Sign In with account chooser (iPad-compatible)...');

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ Google Sign In timed out - likely simulator OAuth issue');
          throw Exception('Google Sign In timed out. This is common on simulators. Please use physical device or try email sign-in instead.');
        },
      );

      if (googleUser == null) {
        print('⚠️ User canceled Google Sign In');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign in was cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      print('✅ Google Sign In successful: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        print('✅ Firebase authentication successful: ${userCredential.user?.email}');

        final customerRecord = await AirtableService.getCustomerByEmail(userCredential.user!.email!);

        if (customerRecord != null && customerRecord.hasValidTokens) {
          print('✅ User has Airtable tagging - gensets will be available');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Successfully signed in with Google! Gensets will be available.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          print('⚠️ User signed in but no Airtable tagging found');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Successfully signed in with Google! Contact support to get access to gensets.'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        }

        print('✅ Google Sign In completed successfully');

        if (mounted) {
          Navigator.of(context).pop(); // Close login page - return to homepage
        }

        print('🏠 Auth state change will automatically navigate to homepage');
      }
    } catch (e) {
      print('❌ Google Sign In failed: $e');
      if (mounted) {
        String errorMessage;
        if (e.toString().contains('timed out') || e.toString().contains('timeout')) {
          errorMessage = 'Google Sign In unavailable on simulator. Use physical device or email sign-in instead.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection.';
        } else if (e.toString().contains('canceled')) {
          errorMessage = 'Sign in was cancelled.';
        } else if (e.toString().contains('sign_in_failed')) {
          errorMessage = 'Google Sign In failed. Please try again.';
        } else if (e.toString().contains('sign_in_required')) {
          errorMessage = 'Google Sign In is required but not available.';
        } else {
          errorMessage = 'Google Sign In failed. Please try email sign-in instead.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      print('🔐 Starting Apple Sign In...');

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: null, // Disable web auth for native iOS
      );

      print('✅ Apple credential obtained - Authorization Code: ${appleCredential.authorizationCode?.substring(0, 20)}...');
      print('✅ Identity Token: ${appleCredential.identityToken?.substring(0, 20)}...');

      if (appleCredential.authorizationCode == null || appleCredential.identityToken == null) {
        throw Exception('Missing authorization code or identity token from Apple');
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        accessToken: appleCredential.authorizationCode,
        idToken: appleCredential.identityToken,
      );

      print('🔄 Signing in with Firebase...');
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      if (userCredential.user != null) {
        print('✅ Firebase authentication successful: ${userCredential.user?.email ?? 'No email'}');

        // Store additional user info if needed
        if (appleCredential.givenName != null || appleCredential.familyName != null) {
          await userCredential.user?.updateDisplayName(
            '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim()
          );
        }

        print('✅ Apple Sign In completed successfully');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully signed in with Apple!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Close login page - return to homepage
        }

        print('🏠 Auth state change will automatically navigate to homepage');
      } else {
        throw Exception('Firebase authentication returned null user');
      }
    } catch (e) {
      print('❌ Apple Sign In failed: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Error stack: ${e.toString()}');

      if (mounted) {
        String errorMessage = _getAppleSignInErrorMessage(e);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _signInWithApple(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getAppleSignInErrorMessage(Object e) {
    final errorString = e.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error. Check internet connection and try again.';
    } else if (errorString.contains('canceled') || errorString.contains('cancelled')) {
      return 'Sign in was cancelled.';
    } else if (errorString.contains('invalid_scope')) {
      return 'Apple Sign In configuration issue. Please contact support.';
    } else if (errorString.contains('unauthorized')) {
      return 'Apple Sign In not authorized. Check app configuration.';
    } else if (errorString.contains('invalid_client')) {
      return 'Apple Sign In configuration error. Please contact support.';
    } else if (errorString.contains('access_denied')) {
      return 'Apple Sign In access denied. Please try again.';
    } else if (errorString.contains('popup_blocked')) {
      return 'Sign in popup was blocked. Please allow popups and try again.';
    } else if (errorString.contains('account_exists_with_different_credential')) {
      return 'Account exists with different sign-in method. Use email sign-in instead.';
    } else {
      return 'Apple Sign In failed. Try email sign-in or contact support.';
    }
  }

  Widget _buildAppleSignInButton() {
    // Check if Apple Sign In is available (iOS only)
    if (Theme.of(context).platform.name != 'iOS') {
      // Return empty container for non-iOS platforms
      return const SizedBox.shrink();
    }

    try {
      // Try to use the official Apple Sign In button
      return SignInWithAppleButton(
        onPressed: _isLoading ? () {} : _signInWithApple,
        style: SignInWithAppleButtonStyle.black,
        borderRadius: BorderRadius.circular(8.0),
        text: 'Sign in with Apple',
      );
    } catch (e) {
      print('⚠️ Apple Sign In button not available: $e');
      // Fallback to custom button if official button fails
      return ElevatedButton(
        onPressed: _isLoading ? null : _signInWithApple,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apple, size: 20),
            const SizedBox(width: 12),
            Text(
              'Sign in with Apple',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final buttonWidth = isTablet ? 400.0 : screenWidth - 48.0;
    final buttonHeight = 50.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 500 : double.infinity),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo Section
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF14B8A6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.flash_on,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Welcome Text
                  Text(
                    'Welcome to Genset Assistant',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 32 : 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    'Sign in to manage your generators',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Sign in with Apple Button (Official with fallback)
                  SizedBox(
                    width: buttonWidth,
                    height: buttonHeight,
                    child: _buildAppleSignInButton(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Sign in with Google Button
                  SizedBox(
                    width: buttonWidth,
                    height: buttonHeight,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shadowColor: Colors.black.withOpacity(0.1),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/google_logo.png',
                            height: 20,
                            width: 20,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  color: Colors.grey[300],
                                ),
                                child: const Icon(
                                  Icons.account_circle,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Sign in with Google',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Sign in with Email Button
                  SizedBox(
                    width: buttonWidth,
                    height: buttonHeight,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signInWithEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF8F9FA),
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mail_outline,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Sign in with Email',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterPage()),
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF007AFF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Terms and Privacy
                  Text(
                    'By continuing, you agree to our Terms of Service and Privacy Policy',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
