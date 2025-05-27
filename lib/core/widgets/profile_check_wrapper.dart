import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/customer_profile_service.dart';
import '../../features/profile/screens/customer_profile_screen.dart';
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
  String? _userType;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    try {
      final authService = context.read<AuthService>();
      final profileService = context.read<CustomerProfileService>();
      final user = await authService.getCurrentUser();
      _userType = user?.userType;
      if (authService.token != null && _userType == 'customer') {
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
            _hasProfile = true; // Providers or not logged in, allow through
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
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1E1E1E),
                const Color(0xFF2D2D2D),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3A7D44)),
            ),
          ),
        ),
      );
    }

    // If customer and no profile, show profile setup
    if (_userType == 'customer' && !_hasProfile) {
      return const ProfileSetupScreen();
    }
    // Otherwise show the intended screen
    return widget.child;
  }
} 