// lib/features/auth/screens/guest_login_screen.dart
  import 'package:flutter/material.dart';

  class GuestLoginScreen extends StatelessWidget {
    const GuestLoginScreen({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text('تسجيل دخول كزائر')),
        body: const Center(
          child: Text('قريباً'),
        ),
      );
    }
  }
  