import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/customer_profile_service.dart';
import '../../features/auth/screens/profile_setup_screen.dart';

class ProfileCheckWrapper extends StatefulWidget {
  final Widget child;

  const ProfileCheckWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<ProfileCheckWrapper> createState() => _ProfileCheckWrapperState();
}

class _ProfileCheckWrapperState extends State<ProfileCheckWrapper> {
  bool _isLoading = true;
  bool _hasProfile = false;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    try {
      final authService = context.read<AuthService>();
      final profileService = context.read<CustomerProfileService>();

      if (authService.token != null) {
        try {
          await profileService.getProfile();
          if (mounted) {
            setState(() {
              _hasProfile = true;
              _isLoading = false;
            });
          }
        } catch (e) {
          // If we get a 404 or any error, it means no profile exists
          if (mounted) {
            setState(() {
              _hasProfile = false;
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final authService = context.read<AuthService>();
    
    // If user is logged in but has no profile, show profile setup
    if (authService.token != null && !_hasProfile) {
      return const ProfileSetupScreen();
    }
    
    // Otherwise show the intended screen
    return widget.child;
  }
} 