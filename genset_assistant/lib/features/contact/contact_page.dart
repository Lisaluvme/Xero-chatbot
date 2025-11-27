import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  // Contact information based on policy
  static const Map<String, Map<String, String>> _contactInfo = {
    'default': {
      'phone': '+60129689816',
      'email': 'genset@genset.com.my',
      'note': 'For general inquiries or normal cases, please provide the company contact details.'
    },
    'urgent_or_discount': {
      'phone': '+6016-219 8537',
      'email': 'peter@genset.com.my',
      'note': 'Only share Mr. Peter\'s contact information if it\'s an urgent matter or the customer requests a discount.'
    }
  };

  // Current contact type being displayed
  String _currentContactType = 'default';

  @override
  void initState() {
    super.initState();
    _determineContactType();
  }

  void _determineContactType() {
    // For now, default to general contact
    // In a real implementation, this could be determined by:
    // 1. User's conversation history with the AI chatbot
    // 2. User's stated urgency level
    // 3. User's request for discounts
    // 4. Context from previous interactions
    setState(() {
      _currentContactType = 'default';
    });
  }

  void _switchToUrgentContact() {
    setState(() {
      _currentContactType = 'urgent_or_discount';
    });

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact Information Updated'),
          content: Text('You are now connected to ${_currentContact['note']}\n\nPhone: ${_currentContact['phone']}\nEmail: ${_currentContact['email']}'),
        );
      },
    );
  }

  Map<String, String> get _currentContact {
    return Map<String, String>.from(_contactInfo[_currentContactType]!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Support'),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.support_agent,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Contact Support We\'re here to help with your generator needs only.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Contact Methods
              _buildBeautifulContactCard(
                context,
                'Call Us',
                'Speak directly with our support team',
                Icons.phone,
                const Color(0xFF059669),
                _launchPhone,
                _currentContact['phone']!,
              ),

              const SizedBox(height: 16),

              _buildBeautifulContactCard(
                context,
                'WhatsApp',
                'Chat with us on WhatsApp for quick assistance',
                Icons.chat,
                const Color(0xFF25D366),
                _launchWhatsApp,
                'Available 24/7',
              ),

              const SizedBox(height: 16),

              _buildBeautifulContactCard(
                context,
                'Email Support',
                'Send us a detailed message about your issue',
                Icons.email_outlined,
                const Color(0xFF1E3A8A),
                _launchEmail,
                _currentContact['email']!,
              ),

              const SizedBox(height: 16),

              _buildBeautifulContactCard(
                context,
                'Feedback',
                'Share your thoughts and suggestions',
                Icons.feedback_outlined,
                const Color(0xFFF59E0B),
                _launchFeedbackEmail,
                'Help improve our service',
              ),

              const SizedBox(height: 30),

              // Additional Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Operating Hours',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTimeRow(Icons.access_time, 'Monday - Friday', '9:00 AM - 6:00 PM'),
                    const SizedBox(height: 8),
                    _buildTimeRow(Icons.weekend, 'Saturday', '9:00 AM - 2:00 PM'),
                    const SizedBox(height: 8),
                    _buildTimeRow(Icons.brightness_2, 'Sunday', 'Emergency Only'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _currentContact['note']!,
                              style: const TextStyle(
                                color: Color(0xFF92400E),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildBeautifulContactCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
    String subtitle,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(IconData icon, String day, String time) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            day,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(
      BuildContext context,
      String title,
      String description,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 40, color: color),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  void _launchWhatsApp() async {
    final phoneNumber = _currentContact['phone']!;
    const message = 'Hello, I need assistance with my generator.';
    final url = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      _showErrorDialog('Could not launch WhatsApp');
    }
  }

  void _launchPhone() async {
    final phoneNumber = _currentContact['phone']!;
    final url = 'tel:$phoneNumber';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      _showErrorDialog('Could not launch phone dialer');
    }
  }

  void _launchEmail() async {
    final email = _currentContact['email']!;
    const subject = 'Generator Support Request';
    const body = 'Please describe your issue:';
    final url =
        'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      _showErrorDialog('Could not launch email client');
    }
  }

  void _launchFeedbackEmail() async {
    final email = _currentContact['email']!;
    const subject = 'Genset Assistant App Feedback';
    const body = 'Please share your feedback about the app:';
    final url =
        'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      _showErrorDialog('Could not launch email client');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
        );
      },
    );
  }

  void _launchMaps() async {
    const address = 'Service Center Location'; // Replace with actual address
    final url =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch maps';
    }
  }
}
