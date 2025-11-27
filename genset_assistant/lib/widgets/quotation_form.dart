import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'dart:async';

class QuotationForm extends StatefulWidget {
  final String productName;
  final String productDescription;
  final String productPrice;

  const QuotationForm({
    super.key,
    required this.productName,
    required this.productDescription,
    required this.productPrice,
  });

  static void show(BuildContext context, {
    required String productName,
    required String productDescription,
    required String productPrice,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuotationForm(
        productName: productName,
        productDescription: productDescription,
        productPrice: productPrice,
      ),
    );
  }

  @override
  State<QuotationForm> createState() => _QuotationFormState();
}

class _QuotationFormState extends State<QuotationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _companyController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isLoading = false;
  late final ScrollController _scrollController = ScrollController();
  late final KeyboardVisibilityController _keyboardVisibilityController = KeyboardVisibilityController();
  late StreamSubscription<bool> _keyboardSubscription;

  final GlobalKey _nameKey = GlobalKey();
  final GlobalKey _emailKey = GlobalKey();
  final GlobalKey _phoneKey = GlobalKey();
  final GlobalKey _locationKey = GlobalKey();
  final GlobalKey _companyKey = GlobalKey();
  final GlobalKey _messageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _keyboardSubscription = _keyboardVisibilityController.onChange.listen(_onKeyboardVisibilityChanged);
  }

  @override
  void dispose() {
    _keyboardSubscription.cancel();
    _scrollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _companyController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onKeyboardVisibilityChanged(bool visible) {
    if (visible && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToFocusedField();
      });
    }
  }

  void _scrollToFocusedField() {
    final focusNode = FocusScope.of(context).focusedChild;
    GlobalKey? focusedKey;

    if (focusNode?.context == _nameKey.currentContext) {
      focusedKey = _nameKey;
    } else if (focusNode?.context == _emailKey.currentContext) {
      focusedKey = _emailKey;
    } else if (focusNode?.context == _phoneKey.currentContext) {
      focusedKey = _phoneKey;
    } else if (focusNode?.context == _locationKey.currentContext) {
      focusedKey = _locationKey;
    } else if (focusNode?.context == _companyKey.currentContext) {
      focusedKey = _companyKey;
    } else if (focusNode?.context == _messageKey.currentContext) {
      focusedKey = _messageKey;
    }

    if (focusedKey?.currentContext != null) {
      Scrollable.ensureVisible(
        focusedKey!.currentContext!,
        duration: const Duration(milliseconds: 300),
        alignment: 0.5,
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;

    // Calculate available height: always use 90% screen height
    final availableHeight = screenHeight * 0.9;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: availableHeight.clamp(400.0, screenHeight * 0.95), // Ensure minimum height of 400 and max 95% screen
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Hide keyboard when tapping outside
        child: Column(
          children: [
            // Header (fixed height, non-scrollable)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Request Quotation',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.productName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.productPrice,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form Content (scrollable, expands to fill remaining space)
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 20 + keyboardHeight),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contact Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name Field
                      Container(
                        key: _nameKey,
                        child: _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.person,
                          validator: (value) => _validateRequired(value, 'Please enter your name'),
                          inputType: TextInputType.name,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email Field
                      Container(
                        key: _emailKey,
                        child: _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email,
                          validator: _validateEmail,
                          inputType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Phone Field
                      Container(
                        key: _phoneKey,
                        child: _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone,
                          validator: (value) => _validateRequired(value, 'Please enter your phone number'),
                          inputType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Location Field
                      Container(
                        key: _locationKey,
                        child: _buildTextField(
                          controller: _locationController,
                          label: 'Location',
                          icon: Icons.location_on,
                          validator: (value) => _validateRequired(value, 'Please enter your location'),
                          inputType: TextInputType.text,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Company Field
                      Container(
                        key: _companyKey,
                        child: _buildTextField(
                          controller: _companyController,
                          label: 'Company (Optional)',
                          icon: Icons.business,
                          validator: null, // Optional field
                          inputType: TextInputType.text,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Message Field
                      Container(
                        key: _messageKey,
                        child: _buildTextField(
                          controller: _messageController,
                          label: 'Additional Message (Optional)',
                          icon: Icons.message,
                          validator: null, // Optional field
                          inputType: TextInputType.multiline,
                          maxLines: 3,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons Container
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : () => _submitViaWhatsApp(),
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Send via WhatsApp'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : () => _submitViaEmail(),
                              icon: const Icon(Icons.email_outlined),
                              label: const Text('Send via Email'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_isLoading) ...[
                        const SizedBox(height: 16),
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],

                      // Extra space at bottom to ensure scrolling works properly
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?)? validator,
    required TextInputType inputType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
      ),
      keyboardType: inputType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  String? _validateRequired(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String _validatePhoneNumber(String phone) {
    // Remove all non-numeric characters
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Remove leading + if present
    if (cleanPhone.startsWith('60')) {
      cleanPhone = cleanPhone.substring(2);
    } else if (cleanPhone.startsWith('+60')) {
      cleanPhone = cleanPhone.substring(3);
    }

    return cleanPhone;
  }

  String _buildInquiryMessage() {
    return '''
*New Quotation Request*

*Product Information:*
📦 Product: ${widget.productName}
💰 Price: ${widget.productPrice}
📝 Description: ${widget.productDescription}

*Customer Details:*
👤 Name: ${_nameController.text}
📧 Email: ${_emailController.text}
📞 Phone: ${_phoneController.text}
📍 Location: ${_locationController.text}
🏢 Company: ${_companyController.text.isNotEmpty ? _companyController.text : 'Not specified'}

${_messageController.text.isNotEmpty ? '*Additional Notes:*\n${_messageController.text}' : ''}

---
*Please contact this customer ASAP regarding their quotation request.*
''';
  }

  void _submitViaWhatsApp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Company WhatsApp number
      const String phoneNumber = '+60129689816';
      final String message = _buildInquiryMessage();

      // Encode message for URL
      final String encodedMessage = Uri.encodeComponent(message);
      final String whatsappUrl = 'https://wa.me/$phoneNumber?text=$encodedMessage';
      final Uri whatsappUri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        _showSuccessDialog();
      } else {
        // Fallback URL for WhatsApp
        final String fallbackUrl = 'whatsapp://send?phone=$phoneNumber&text=$encodedMessage';
        final Uri fallbackUri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
          _showSuccessDialog();
        } else {
          _showErrorDialog('WhatsApp Not Available', 'WhatsApp is not installed on this device. Please try the email option instead.');
        }
      }
    } catch (e) {
      print('Error opening WhatsApp: $e');
      _showErrorDialog('WhatsApp Error', 'Failed to open WhatsApp. Please try again or use the email option.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _submitViaEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Company email
      const String email = 'genset@genset.com.my';
      final String subject = 'Quotation Request for ${widget.productName}';
      final String body = _buildInquiryMessage();

      // Encode for URL
      final String encodedSubject = Uri.encodeComponent(subject);
      final String encodedBody = Uri.encodeComponent(body);

      final String emailUrl = 'mailto:$email?subject=$encodedSubject&body=$encodedBody';
      final Uri emailUri = Uri.parse(emailUrl);
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
        _showSuccessDialog();
      } else {
        _showErrorDialog('Email Not Available', 'No email client is configured on this device. Please try the WhatsApp option instead.');
      }
    } catch (e) {
      print('Error opening email client: $e');
      _showErrorDialog('Email Error', 'Failed to open email client. Please try again or use the WhatsApp option.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }



  void _showSuccessDialog([String? customMessage, bool alwaysCloseForm = false]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Success!',
            style: TextStyle(color: Color(0xFF1E3A8A)),
          ),
          content: Text(
            customMessage ?? 'Thank you for your quotation request. Our team will get in touch with you shortly.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                if (alwaysCloseForm) {
                  Navigator.of(context).pop(); // Close form for specific cases
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A), // Blue background
                foregroundColor: Colors.white, // White text
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
