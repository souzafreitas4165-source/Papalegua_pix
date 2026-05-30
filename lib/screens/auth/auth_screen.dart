import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:papaleguas_pix/services/auth_service.dart';
import 'package:papaleguas_pix/screens/login_screen.dart';
import 'package:papaleguas_pix/screens/home_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.checkAuth();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authService.isAuthenticated) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}
