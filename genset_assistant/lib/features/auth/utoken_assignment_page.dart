import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/airtable_service.dart';

class UtokenAssignmentPage extends StatefulWidget {
  const UtokenAssignmentPage({super.key});

  @override
  State<UtokenAssignmentPage> createState() => _UtokenAssignmentPageState();
}

class _UtokenAssignmentPageState extends State<UtokenAssignmentPage> {
  String? _userEmail;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in')),
      );
      Navigator.of(context).pop();
      return;
    }
    _userEmail = user.email!;
    _askAssignUtoken();
  }

  Future<void> _askAssignUtoken() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Utoken'),
        content: Text('Do you want to assign a utoken to this user? ($_userEmail)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (result == true) {
      _askForUtoken();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _askForUtoken() async {
    final utokenController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Utoken'),
        content: TextField(
          controller: utokenController,
          decoration: const InputDecoration(hintText: 'Utoken'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(utokenController.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _updateUtoken(result);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _updateUtoken(String utoken) async {
    setState(() => _isLoading = true);
    try {
      // Fetch current customer record
      final customer = await AirtableService.getCustomerByEmail(_userEmail!);
      if (customer == null) {
        throw Exception('User not found in Airtable');
      }
      final currentUtokens = List<String>.from(customer.tokens);

      // Add utoken
      await AirtableService.addUtokenToUser(_userEmail!, utoken);

      // Ask for confirmation
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Update'),
          content: const Text('Do you want to confirm the update and finish?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // Fetch updated customer record
        final updatedCustomer = await AirtableService.getCustomerByEmail(_userEmail!);
        if (updatedCustomer != null) {
          final result = {
            'userEmail': _userEmail,
            'updatedUtokens': updatedCustomer.tokens,
            'customerName': updatedCustomer.customerName,
            'gensetName': updatedCustomer.gensetName,
          };
          _showResult(result);
        }
      } else {
        // Revert
        await AirtableService.setUtokensForUser(_userEmail!, currentUtokens);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operation cancelled')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      Navigator.of(context).pop();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showResult(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Confirmed'),
        content: SingleChildScrollView(
          child: Text(result.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((_) => Navigator.of(context).pop(result));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: const Color(0xFFFFFFFF),
        title: const Text('Utoken Assignment'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
              )
            : const Text(
                'Processing...',
                style: TextStyle(color: Color(0xFFB3B3B3)),
              ),
      ),
    );
  }
}
