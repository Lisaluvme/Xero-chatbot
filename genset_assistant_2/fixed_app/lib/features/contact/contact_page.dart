import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Contact Support',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Get in touch with our support team for assistance with your generator.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          _buildContactCard(
            context,
            'WhatsApp Support',
            'Chat with our technical support team',
            Icons.chat,
            Colors.green,
            _launchWhatsApp,
          ),
          _buildContactCard(
            context,
            'Emergency Hotline',
            'For urgent generator issues',
            Icons.phone,
            Colors.red,
            _launchPhone,
          ),
          _buildContactCard(
            context,
            'Email Support',
            'Send detailed queries via email',
            Icons.email,
            Colors.blue,
            _launchEmail,
          ),
          _buildContactCard(
            context,
            'Service Center',
            'Find nearest service location',
            Icons.location_on,
            Colors.orange,
            _launchMaps,
          ),
          const SizedBox(height: 24),
          const Text(
            'Operating Hours',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monday - Friday: 8:00 AM - 6:00 PM'),
                  Text('Saturday: 9:00 AM - 4:00 PM'),
                  Text('Sunday: Emergency calls only'),
                  SizedBox(height: 8),
                  Text(
                    'Emergency Support: 24/7',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _launchWhatsApp,
                  icon: const Icon(Icons.chat),
                  label: const Text('Start Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _launchPhone,
                  icon: const Icon(Icons.phone),
                  label: const Text('Call Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
      BuildContext context, String title, String description, IconData icon, Color color, VoidCallback onTap) {
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
    const phoneNumber = '+60123456789'; // Replace with actual WhatsApp number
    const message = 'Hello, I need assistance with my generator.';
    final url = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch WhatsApp';
    }
  }

  void _launchPhone() async {
    const phoneNumber = '+60123456789'; // Replace with actual phone number
    final url = 'tel:$phoneNumber';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch phone dialer';
    }
  }

  void _launchEmail() async {
    const email = 'support@gensetassistant.com';
    const subject = 'Generator Support Request';
    const body = 'Please describe your issue:';
    final url = 'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch email client';
    }
  }

  void _launchMaps() async {
    const address = 'Service Center Location'; // Replace with actual address
    final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch maps';
    }
  }
}
